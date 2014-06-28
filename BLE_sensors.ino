/* 
 * BT_sensors.ino
 *
 * Author: Graham Harvey
 * Last Modified: 26 June 2014
 *
 * This is the main Arduino project file for this Bluetooth
 * sensor project.  The Arduino will obtain data from a
 * temperature sensor, humidity sensor, barometer/altimeter,
 * and UV light sensor.  It will send the results via Bluetooth
 * to a smartphone or other Android device.  The first version
 * of the project will only support Android devices.
 */

#define 3V3ref A0
#define UV_pin A1

void setup() {
}

void loop() {
  // enter low power mode
  // wake up
  
  // BMP180 code
  // get temperature
  // get pressure
  // get altitude
  
  // DHT22 code
  // get humidity
  // get temperature?
  
  // SI1145 code
  // get UV index
  // get IR intensity
  // get visible intensity
  
  // BLE code
  // send data to phone
}

double readUV() {
}
