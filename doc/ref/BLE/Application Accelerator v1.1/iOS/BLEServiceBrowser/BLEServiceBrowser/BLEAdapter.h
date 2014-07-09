//
//  BLEAdapter.h
//  BLEServiceBrowser
//
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreBluetooth/CBService.h>
#import "constants.h"

#import "DeviceViewController.h"
#import "ServiceViewController.h"
#import "CharViewController.h"


@protocol BLEAdapterDelegate
@optional
-(void) OnDiscoverServices:(NSArray *)s;
-(void) OnConnected:(BOOL)status;
@end

@interface BLEAdapter : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate> {
}

+(BLEAdapter*) sharedBLEAdapter;

@property (strong, nonatomic) DeviceViewController * dvController; // Device View Controller
@property (strong, nonatomic) ServiceViewController * svController; // Service View Controller
@property (strong, nonatomic) UIViewController * cvController; // Characteristics View Controller

@property (strong, nonatomic) NSMutableArray *peripherals;
@property (strong, nonatomic) CBCentralManager *CM;
@property (strong, nonatomic) CBPeripheral *activePeripheral;


-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID  p:(CBPeripheral *)p data:(NSData *)data;
-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID  p:(CBPeripheral *)p;
-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID  p:(CBPeripheral *)p on:(BOOL)on;

-(UInt16) swap:(UInt16) s;
-(int) controlSetup:(int) s;
-(int) findBLEPeripherals:(int) timeout;
-(const char *) centralManagerStateToString:(int)state;
-(void) scanTimer:(NSTimer *)timer;
-(void) printKnownPeripherals;
-(void) printPeripheralInfo:(CBPeripheral*)peripheral;
-(void) connectPeripheral:(CBPeripheral *)peripheral status:(BOOL)status;
-(NSString *)GetServiceName:(CBUUID *)UUID;
-(void) getAllCharacteristicsForService:(CBPeripheral *)p service:(CBService *)s;
-(void) getAllServicesFromPeripheral:(CBPeripheral *)p;
-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p;
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p;
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service;
-(NSString *) CBUUIDToNSString:(CBUUID *) UUID;  // see CBUUID UUIDString in iOS 7.1
-(const char *) UUIDToString:(NSUUID *) UUID;
-(const char *) CBUUIDToString:(CBUUID *) UUID;
-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2;
-(int) compareCBUUIDToInt:(CBUUID *) UUID1 UUID2:(UInt16)UUID2;
-(UInt16) CBUUIDToInt:(CBUUID *) UUID;





@end
