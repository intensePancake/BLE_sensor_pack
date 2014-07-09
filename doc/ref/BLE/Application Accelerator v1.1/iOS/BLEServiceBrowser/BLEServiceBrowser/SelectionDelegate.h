//
//  SelectionDelegate.h
//  BLEServiceBrowser
//
//  Created by Warren Dockerty on 03/06/2013.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TestService.h"

@protocol SelectionDelegate <NSObject>
@required
-(void)clearUI:(BOOL)clear;
-(void)selectedPeripheral:(CBPeripheral *)peripheral;
-(void)selectedService:(CBService *)service;
-(void)selectedCharacteristic:(CBCharacteristic *)characteristic;

@end
