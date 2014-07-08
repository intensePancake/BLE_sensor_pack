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
 
#define ERR_LED_PIN 13

#define MBAR_ATM_CONV_FACTOR 0.000986923267

#define M_FT_CONV_FACTOR 3.28084
#define REF_ALTITUDE_FT 72 // reference altitude in feet for finding pressure
#define REF_ALTITUDE_M REF_ALTITUDE_FT * M_FT_CONV_FACTOR // reference altitude in meters

#define DHTPIN 4
#define DHTTYPE DHT22

#define ADAFRUITBLE_REQ 10
#define ADAFRUITBLE_RDY 3
#define ADAFRUITBLE_RST 9

#define NUM_SENSORS 6

// sensor bit assignments in request byte
#define TEMP_REQ_BIT 5
#define HUMIDITY_REQ_BIT 4
#define PRESSURE_REQ_BIT 3
#define VIS_LIGHT_REQ_BIT 2
#define IR_LIGHT_REQ_BIT 1
#define UV_LIGHT_REQ_BIT 0

#define DEBUG

#include <Wire.h>
#include <SPI.h>
#include <SFE_BMP180.h>
#include <DHT.h>
#include <Adafruit_BLE_UART.h>
#include <Adafruit_SI1145.h>

SFE_BMP180 barometer;
DHT dht(DHTPIN, DHTTYPE);
Adafruit_BLE_UART ble = Adafruit_BLE_UART(ADAFRUITBLE_REQ, ADAFRUITBLE_RDY, ADAFRUITBLE_RST);
Adafruit_SI1145 lsensor = Adafruit_SI1145();

void setup()
{
    Serial.begin(9600);
    while(!Serial);
        
    pinMode(ERR_LED_PIN, OUTPUT);
    digitalWrite(ERR_LED_PIN, LOW);
	
    if(!barometer.begin()) {
        // init failure
#ifdef DEBUG
	Serial.println("Failed to initialize pressure sensor");
#endif
	blink_block_forever(ERR_LED_PIN);
	while(1);
    }
	
    if(!lsensor.begin()) {
        // init failure
#ifdef DEBUG
	Serial.println("Failed to initialize light sensor");
#endif
	blink_block_forever(ERR_LED_PIN);
    }
	
    dht.begin();
  
#ifdef DEBUG
    ble.setACIcallback(BLE_stateChange);
#endif
    ble.setRXcallback(processRequests);
    ble.begin();
#ifdef DEBUG
    Serial.println("nRF8001 init complete");
#endif
}

void loop()
{
     ble.pollACI();
     //delay(500);

/*
#ifdef DEBUG
        uint8_t buf = 0xff;
        uint8_t bufsize = 1;
        Serial.println("Sending buffer");
        delay(500);
        processRequests(&buf, bufsize);
#endif
*/
}

#ifdef DEBUG
void BLE_stateChange(aci_evt_opcode_t opcode)
{
    // state change - print it to the serial port
    if(opcode == ACI_EVT_DEVICE_STARTED) {
        Serial.println("BLE now advertising");
    } else if(opcode == ACI_EVT_CONNECTED) {
        Serial.println("BLE now connected");
    } else if(opcode == ACI_EVT_DISCONNECTED) {
        Serial.println("BLE disconnected");
    }
}
#endif

// TODO: light sensor code
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
void processRequests(uint8_t *RxBuf, uint8_t RxBufsize)
{
#ifdef DEBUG
    Serial.println("Rx buffer received");
    for(int i = 0; i < RxBufsize; i++) {
        Serial.print("\t0x");
        Serial.print(RxBuf[i], HEX);
        delay(10);
    }
    Serial.println("");
#endif

    byte TxBuf[NUM_SENSORS * sizeof(float)];
    int TxBufsize; // number of bytes to send
    int TxBufIndex = 0;
    float temp; // in degrees Celcius
    float humidity; // in percent
    float abs_P, compensated_P; // in mbar
    float P_atm; // in atm
    float vis_intensity;
    float IR_intensity;
    float UV_index;
    byte req;
    boolean req_T, req_H, req_P, req_Vis, req_IR, req_UV;
    // loop through requests

    for(int i = 0; i < RxBufsize; i++) {
    	// process this request
    
        // determine which sensors to read
	req = RxBuf[i];
	req_T = (req >> TEMP_REQ_BIT) & 0x1;
	req_H = (req >> HUMIDITY_REQ_BIT) & 0x1;
	req_P = (req >> PRESSURE_REQ_BIT) & 0x1;
	req_Vis = (req >> VIS_LIGHT_REQ_BIT) & 0x1;
	req_IR = (req >> IR_LIGHT_REQ_BIT) & 0x1;
	req_UV = (req >> UV_LIGHT_REQ_BIT) & 0x1;
	

	if(req_T || req_P) {
            // pressure measurement requires the temperature,
            // so update temperature as well
            temp = getTemp();
            floatToByteArray(TxBuf, temp, &TxBufIndex);
#ifdef DEBUG
            Serial.print("T=");
            Serial.println(temp);
#endif
	}

	if(req_H) {
	    humidity = dht.readHumidity();
	    floatToByteArray(TxBuf, humidity, &TxBufIndex);
#ifdef DEBUG
	    Serial.print("H=");
            Serial.println(humidity);
#endif
        }

	if(req_P) {
	    abs_P = getAbsPressure(temp);
	    compensated_P = barometer.sealevel(abs_P, REF_ALTITUDE_M);
            P_atm = compensated_P * MBAR_ATM_CONV_FACTOR;
	    floatToByteArray(TxBuf, compensated_P, &TxBufIndex);
#ifdef DEBUG
            Serial.print("P=");
            Serial.println(compensated_P);
#endif
	}

	// TODO:
	// SI1145 code
	if(req_Vis) {
            // get visible intensity
	    vis_intensity = lsensor.readVisible();
	    floatToByteArray(TxBuf, vis_intensity, &TxBufIndex);
#ifdef DEBUG
	    Serial.print("VI=");
            Serial.println(vis_intensity);
#endif
	}

	if(req_IR) {
	    // get IR intensity
	    IR_intensity = lsensor.readIR();
	    floatToByteArray(TxBuf, IR_intensity, &TxBufIndex);
#ifdef DEBUG
            Serial.print("IR=");
            Serial.println(IR_intensity);
#endif
	}

	if(req_UV) {
	    // get UV index
	    UV_index = lsensor.readUV() / 100.0;
	    floatToByteArray(TxBuf, UV_index, &TxBufIndex);
#ifdef DEBUG
	    Serial.print("UV=");
            Serial.println(UV_index);
#endif
	}

	// we only want to send as much data as was requested
        // NOTE: if pressure is requested, temperature and pressure are sent back
        // regardless of temperature request.  This is because temperature is
        // required for the pressure calculation.
	TxBufsize = TxBufIndex;
		
	// BLE code
	ble.write(TxBuf, TxBufsize); // send bytes
    }
#ifdef DEBUG
    Serial.println("Done processing request");
#endif
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
#ifdef DEBUG
	    Serial.println("Failed to retrieve temperature");
#endif
	    errcode = barometer.getError();
	    // TODO: error handling
	}
    } else {
        // could not start temperature reading
#ifdef DEBUG
        Serial.println("Failed to initialize temperature reading");
#endif
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
#ifdef DEBUG
	    Serial.println("Failed to retrieve pressure");
#endif
	    // TODO: error handling
	    errcode = barometer.getError();
	}
    } else {
	// could not start pressure reading
#ifdef DEBUG
	Serial.println("Failed to initialize pressure reading");
#endif
	// TODO: error handling
	errcode = barometer.getError();
    }
}

void floatToByteArray(byte *buffer, float f, int *index)
{
    int i;
    char *dataPtr = (char*)(&f);

    for(i = 0; i < sizeof(float); i++) {
	buffer[*index] = *(dataPtr + i);
	*index += 1;
    }
}

void blink_block_forever(int led_pin)
{
    int delay_ms = 250;
    while(1) {
        digitalWrite(led_pin, HIGH);
        delay(delay_ms);
        digitalWrite(led_pin, LOW);
        delay(delay_ms);
    }
}

