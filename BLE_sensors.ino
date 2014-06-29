/* 
 * BT_sensors.ino
 *
 * Author: Graham Harvey
 * Last Modified: 28 June 2014
 * Version 0.1
 *
 * This is the main Arduino project file for this Bluetooth
 * Low Energy sensor project.  The Arduino will obtain data 
 * from a temperature sensor, humidity sensor, barometer/altimeter,
 * and UV light sensor.  It will send the results via Bluetooth
 * to a smartphone or other Android device.  The first version
 * of the project will only support Android devices.
 * 
 */

#define M_FT_CONV_FACTOR 3.28084
#define REF_ALTITUDE_FT 72 // reference altitude in feet for finding pressure
#define REF_ALTITUDE_M REF_ALTITUDE_FT * M_FT_CONV_FACTOR // reference altitude in meters

#define DHTPIN 0
#define DHTTYPE DHT22

#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 3
#define ADAFRUITBLE_RST 9

#define MAX_DATABUF_SIZE 30 // maximum number of bytes in the data buffer
#define NUM_SENSORS 6

// sensor bit assignments in request byte
#define TEMP_REQ_BIT 5
#define HUMIDITY_REQ_BIT 4
#define PRESSURE_REQ_BIT 3
#define VIS_LIGHT_REQ_BIT 2
#define IR_LIGHT_REQ_BIT 1
#define UV_LIGHT_REQ_BIT 0

#include <assert.h>
#include <Wire.h>
#include <SPI.h>
#include <SFE_BMP180.h>
#include <DHT.h>
#include <Adafruit_BLE_UART.h>

SFE_BMP180 barometer;
DHT dht(DHTPIN, DHTTYPE);
Adafruit_BLE_UART ble = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);

aci_evt_opcode_t ble_last_state = ACI_EVT_DISCONNECTED;

void setup()
{
  Serial.begin(9600);
  
  if(!barometer.begin()) {
    // init failure
    Serial.println("Failed to initialize pressure sensor");
    while(1);
  }
  
  dht.begin();
  ble.begin();
  ble_last_state = ble.getState();
}

void loop()
{
  byte RxBuf[MAX_DATABUF_SIZE];
  int RxBufsize;
  ble.pollACI();
  
  aci_evt_opcode_t ble_state = ble.getState();
  if(ble_state != ble_last_state) {
    // connection state has changed
    ble_last_state = ble_state;
  }
  
  // check if there is a connection
  if(ble_state == ACI_EVT_CONNECTED) {
    // check for available data
    RxBufsize = 0;
    while(ble.available()) {
      while(RxBufsize < MAX_DATABUF_SIZE) {
        RxBuf[RxBufsize++] = ble.read();
      }
      
      processRequests(RxBuf, RxBufsize);
    }
  }
}

// TODO: write this function
/* processRequests - processes the request for sensor readings
 * or otherwise, and stores the results of length len in databuf
 *
 * The request format is as follows: one request is in the form
 * of one byte - 8 bits.  There are 6 sensors that the Arduino
 * can read.  In a certain bit position, a 1 represents a request
 * for the sensor to be read, while a 0 means that such a request
 * was not sent for that sensor.  The bit position for each
 * sensor is shown below.
 *
 * |   7  |   6  |   5   |    4     |    3     |   2        |    1     |    0     |
 * | none | none | temp  | humidity | pressure | Vis. light | IR light | UV Index |
 *
 */
void processRequests(byte *RxBuf,  int RxBufsize)
{
  byte TxBuf[NUM_SENSORS * sizeof(float)];
  int TxBufsize; // number of bytes to send
  int TxBufIndex = 0;
  float temp; // in degrees Celcius
  float humidity; // in percent
  float abs_P, compensated_P; // in mbar
  
  byte req;
  boolean req_T, req_H, req_P, req_Vis, req_IR, req_UV;
  
  // loop through requests
  for(int i = 0; i < RxBufsize; i++) {
    // process this request
    req = RxBuf[i];
    req_T = req >> TEMP_REQ_BIT;
    req_H = (req >> HUMIDITY_REQ_BIT) & 0x1;
    req_P = (req >> PRESSURE_REQ_BIT) & 0x1;
    req_Vis = (req >> VIS_LIGHT_REQ_BIT) & 0x1;
    req_IR = (req >> IR_LIGHT_REQ_BIT) & 0x1;
    req_UV = (req >> UV_LIGHT_REQ_BIT) & 0x1;
    
    if(req_T || req_P) {
      temp = getTemp();
      floatToBuffer(TxBuf, temp, &TxBufIndex);
    }
    if(req_H) {
      humidity = dht.readHumidity();
      floatToBuffer(TxBuf, humidity, &TxBufIndex);
    }
    if(req_P) {
      abs_P = getAbsPressure(temp);
      compensated_P = barometer.sealevel(abs_P, REF_ALTITUDE_M);
      floatToBuffer(TxBuf, compensated_P, &TxBufIndex);
    }
    
    // TODO:
    // SI1145 code
    if(req_Vis) {
      // get visible intensity
    }
    if(req_IR) {
      // get IR intensity
    }
    if(req_UV) {
      // get UV index
    }
    
    // BLE code
    // sanity check
    assert(TxBufsize == sizeof(float) * (req_T + req_H + req_P + req_Vis + req_IR + req_UV));
    // send bytes
    ble.write(TxBuf, TxBufsize);
  }
}

float getTemp()
{
  int state;
  double temp;
  char errcode;
  
  state = barometer.startTemperature();
  if(state != 0) {
    delay(state); // wait until temperature reading is ready -- about 5 ms
    state = barometer.getTemperature(temp); // retrieve temperature
    if(state != 0) {
      // successful temperature reading
      return (float)temp;
    } else {
      // could not get temperature
      Serial.println("Failed to retrieve temperature");
      errcode = barometer.getError();
      // TODO: error handling
    }
  } else {
    // could not start temperature reading
    Serial.println("Failed to initialize temperature reading");
    errcode = barometer.getError();
    // TODO: error handling
  }
}

float getAbsPressure(float temp)
{
  int state;
  double abs_P;
  char errcode;
  
  state = barometer.startPressure(3);
  if(state != 0) {
    delay(state); // wait for pressure reading
    state = barometer.getPressure(abs_P, (double&)temp); // retrieve absolute pressure
    if(state != 0) {
      // successful pressure reading
      return (float)abs_P;
    } else {
      // could not read pressure
      Serial.println("Failed to retrieve pressure");
      // TODO: error handling
      errcode = barometer.getError();
    }
  } else {
    // could not start pressure reading
    Serial.println("Failed to initialize pressure reading");
    // TODO: error handling
    errcode = barometer.getError();
  }
}
void floatToBuffer(byte *buffer, float data, int *index)
{
  long *dataPtr = (long*)(&data);
  
  for(int i = 0; i < sizeof(float); i++) {
    buffer[*index] = (*dataPtr >> 8 * i);
    *index += 1;
  }
}
