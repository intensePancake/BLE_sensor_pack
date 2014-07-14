/* 
 * BT_sensors.ino
 *
 * Author: Graham Harvey
 * Last Modified: 11 July 2014
 * Version: 1.0
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

#define TIME_BETWEEN_SENDS 1000 // milliseconds


#define NUM_SENSORS 7
// sensor bit assignments in request byte
#define TEMP_REQ_BIT 6
#define HUMIDITY_REQ_BIT 5
#define HEAT_INDEX_REQ_BIT 4
#define PRESSURE_REQ_BIT 3
#define VIS_LIGHT_REQ_BIT 2
#define IR_LIGHT_REQ_BIT 1
#define UV_INDEX_REQ_BIT 0

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

// activity state of the sensors: 1 for on, 0 for off
boolean state_T, state_HU, state_HI, state_P, state_Vis, state_IR, state_UV;

boolean sensors_enable;
unsigned long last_send_time;

void setup()
{
    Serial.begin(9600);
    while(!Serial);
        
    pinMode(ERR_LED_PIN, OUTPUT);
    digitalWrite(ERR_LED_PIN, LOW);
    
    sensors_enable = false;
	
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
  
    ble.setACIcallback(BLE_stateChange);
    ble.setRXcallback(updateSensorState);
    ble.begin();
#ifdef DEBUG
    Serial.println("nRF8001 init complete");
#endif
    
    last_send_time = millis();
}

/*
 * The buffer that is sent includes one byte specifying the sensor
 * used, and four bytes representing the float value that was read
 * from that sensor.
 */
void loop()
{
    ble.pollACI();
  
    if((millis() - last_send_time > TIME_BETWEEN_SENDS) && sensors_enable) {
        byte TxBuf[NUM_SENSORS * (sizeof(byte) + sizeof(float))];
        int TxBufsize; // number of bytes to send
        int TxBufIndex = 0;
        float temp; // in degrees Fahrenheit
        float humidity; // in percent
        float heat_index;
        float abs_P, compensated_P; // in mbar
        float P_atm; // in atm
        float vis_intensity;
        float IR_intensity;
        float UV_index;
    
        if(state_T) {
            // get temperature
            temp = getTemp();
            sensorDataToBuffer(TxBuf, TEMP_REQ_BIT, temp, &TxBufIndex);
        }
        if(state_HU) {
            // get humidity
            humidity = dht.readHumidity();
            sensorDataToBuffer(TxBuf, HUMIDITY_REQ_BIT, humidity, &TxBufIndex);
        }
        if(state_HI) {
            // we need both temperature and humidity to
            // compute heat index
            if(!state_T) {
              temp = getTemp();
            }
            if(!state_HU) {
              humidity = dht.readHumidity();
            }
            heat_index = dht.computeHeatIndex(temp, humidity);
            sensorDataToBuffer(TxBuf, HEAT_INDEX_REQ_BIT, heat_index, &TxBufIndex);
        }
        if(state_P) {
            // get pressure
            // we need the temperature to get pressure,
            // so measure it if we haven't already
            if(!(state_T || state_HI)) {
                // if we don't enter this conditional,
                // temperature was already read
                temp = getTemp();
            }
            abs_P = getAbsPressure(temp);
	    compensated_P = barometer.sealevel(abs_P, REF_ALTITUDE_M);
            P_atm = compensated_P * MBAR_ATM_CONV_FACTOR;
            sensorDataToBuffer(TxBuf, PRESSURE_REQ_BIT, P_atm, &TxBufIndex);
        }
        if(state_Vis) {
            // get visible intensity
	    vis_intensity = lsensor.readVisible();
            sensorDataToBuffer(TxBuf, VIS_LIGHT_REQ_BIT, vis_intensity, &TxBufIndex);
        }
        if(state_IR) {
            // get IR intensity
            IR_intensity = lsensor.readIR();
            sensorDataToBuffer(TxBuf, IR_LIGHT_REQ_BIT, IR_intensity, &TxBufIndex);
        }
        if(state_UV) {
            // get UV index
            UV_index = lsensor.readUV() / 100.0;
            sensorDataToBuffer(TxBuf, UV_INDEX_REQ_BIT, UV_index, &TxBufIndex);
        }
    
        TxBufsize = TxBufIndex;
    
        last_send_time = millis();
        if(TxBufsize != 0) {
            ble.write(TxBuf, TxBufsize); // send bytes
        }
    }
}

void BLE_stateChange(aci_evt_opcode_t opcode)
{
    // state change - print it to the serial port
    if(opcode == ACI_EVT_DEVICE_STARTED) {
        Serial.println("BLE now advertising");
    } else if(opcode == ACI_EVT_CONNECTED) {
        Serial.println("BLE now connected");
        sensors_enable = true;
    } else if(opcode == ACI_EVT_DISCONNECTED) {
        Serial.println("BLE disconnected");
        sensors_enable = false;
    }
}

/*
 * updateSensorState - turn sensors on or off, depending on input
 *
 * The request format is as follows: one request is in the form
 * of one byte - 8 bits.  There are 6 sensors that the Arduino
 * can read.  In a certain bit position, a 1 represents a request
 * for the sensor to be read, while a 0 means that such a request
 * was not sent for that sensor.  The bit position for each
 * sensor is shown below.
 *
 * |   7  |      6     |   5   |    4     |    3     |   2        |    1     |    0     |
 * | none | heat index | temp  | humidity | pressure | Vis. light | IR light | UV Index |
 */
void updateSensorState(uint8_t *RxBuf, uint8_t RxBufsize)
{
    byte req;
  
    for(int i = 0; i < RxBufsize; i++) {
        // determine which sensors to read
	req = RxBuf[i];
#ifdef DEBUG
        Serial.print("Received byte: 0x");
        Serial.print(RxBuf[i], HEX);
        Serial.println();
#endif
        state_T = (req >> TEMP_REQ_BIT) & 0x1;
	state_HU = (req >> HUMIDITY_REQ_BIT) & 0x1;
        state_HI = (req >> HEAT_INDEX_REQ_BIT) & 0x1;
	state_P = (req >> PRESSURE_REQ_BIT) & 0x1;
	state_Vis = (req >> VIS_LIGHT_REQ_BIT) & 0x1;
	state_IR = (req >> IR_LIGHT_REQ_BIT) & 0x1;
	state_UV = (req >> UV_INDEX_REQ_BIT) & 0x1;
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
	    return tempCtoF((float)temp);
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

float tempCtoF(float Celcius)
{
    return 9 * Celcius / 5 + 32;
}

void sensorDataToBuffer(byte *buffer, byte sensor_select, float f, int *indexPtr)
{
    buffer[*indexPtr] = sensor_select;
    *indexPtr += 1;
    floatToByteArray(buffer, f, indexPtr);
}

void floatToByteArray(byte *buffer, float f, int *indexPtr)
{
    int i;
    char *dataPtr = (char*)(&f);

    for(i = 0; i < sizeof(float); i++) {
	buffer[*indexPtr] = *(dataPtr + i);
	*indexPtr += 1;
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

