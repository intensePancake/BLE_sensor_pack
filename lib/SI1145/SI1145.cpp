/*
 * SI1145.cpp
 * 
 * Author: Graham Harvey
 * Last Modified: 28 June 2014
 * Version: 0.1
 * 
 * This is an Arduino library written for the Silicon Labs SI1145
 * ambient light sensor.  The library is written specifically to
 * work with the breakout board for this product created by Adafruit
 * Industries (https://www.adafruit.com/products/1777).
 * 
 */

#include "SI1145.h"
#include <Wire.h>

SI1145::SI1145()
{
}

void SI1145::begin()
{
	Wire.begin(); // start Arduino's I2C library
	
	
}
