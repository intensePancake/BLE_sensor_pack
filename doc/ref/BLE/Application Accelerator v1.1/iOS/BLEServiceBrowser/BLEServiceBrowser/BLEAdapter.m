//
//  BLEAdapter.m
//  BLEServiceBrowser
//
//  version 1.2     Updated for iOS 7.0 ----11/22/13
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import "BLEAdapter.h"

@implementation BLEAdapter

static BLEAdapter * _sharedBLEAdapter = nil;


//@synthesize delegate;
@synthesize dvController;
@synthesize svController;
@synthesize cvController;

@synthesize CM;
@synthesize peripherals;
@synthesize activePeripheral;

+(BLEAdapter *)sharedBLEAdapter
{
    @synchronized([BLEAdapter class])
    {
        if(!_sharedBLEAdapter)
            _sharedBLEAdapter = [[self alloc] init];
        
        return _sharedBLEAdapter;
    }

    return nil;
}

/*!
 *  @method writeValue:
 *
 *  @param serviceUUID Service UUID to write to (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to write to (e.g. 0x2401)
 *  @param data Data to write to peripheral
 *  @param p CBPeripheral to write to
 *
 *  @discussion Main routine for writeValue request, writes without feedback. It converts integer into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, value is written. If not nothing is done.
 *
 */

-(void) writeValue:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p data:(NSData *)data {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[[[p identifier] UUIDString] UTF8String]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:(p.identifier)]);
        return;
    }
    [p writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
}


/*!
 *  @method readValue:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for read value request. It converts integers into
 *  CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the read value is started. When value is read the didUpdateValueForCharacteristic
 *  routine is called.
 *
 *  @see didUpdateValueForCharacteristic
 */

-(void) readValue: (int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[self UUIDToString:(p.identifier)]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:(p.identifier)]);
        return;
    }
    [p readValueForCharacteristic:characteristic];
}


/*!
 *  @method notification:
 *
 *  @param serviceUUID Service UUID to read from (e.g. 0x2400)
 *  @param characteristicUUID Characteristic UUID to read from (e.g. 0x2401)
 *  @param p CBPeripheral to read from
 *
 *  @discussion Main routine for enabling and disabling notification services. It converts integers
 *  into CBUUID's used by CoreBluetooth. It then searches through the peripherals services to find a
 *  suitable service, it then checks that there is a suitable characteristic on this service.
 *  If this is found, the notfication is set.
 *
 */
-(void) notification:(int)serviceUUID characteristicUUID:(int)characteristicUUID p:(CBPeripheral *)p on:(BOOL)on {
    UInt16 s = [self swap:serviceUUID];
    UInt16 c = [self swap:characteristicUUID];
    NSData *sd = [[NSData alloc] initWithBytes:(char *)&s length:2];
    NSData *cd = [[NSData alloc] initWithBytes:(char *)&c length:2];
    CBUUID *su = [CBUUID UUIDWithData:sd];
    CBUUID *cu = [CBUUID UUIDWithData:cd];
    CBService *service = [self findServiceFromUUID:su p:p];
    if (!service) {
        printf("Could not find service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:su],[[[p identifier] UUIDString] UTF8String]);
        return;
    }
    CBCharacteristic *characteristic = [self findCharacteristicFromUUID:cu service:service];
    if (!characteristic) {
        printf("Could not find characteristic with UUID %s on service with UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:cu],[self CBUUIDToString:su],[self UUIDToString:(p.identifier)]);
        return;
    }
    [p setNotifyValue:on forCharacteristic:characteristic];
}


/*!
 *  @method swap:
 *
 *  @param s Uint16 value to byteswap
 *
 *  @discussion swap byteswaps a UInt16
 *
 *  @return Byteswapped UInt16
 */

-(UInt16) swap:(UInt16)s {
    UInt16 temp = s << 8;
    temp |= (s >> 8);
    return temp;
}

/*!
 *  @method controlSetup:
 *
 *  @param s Not used
 *
 *  @return Allways 0 (Success)
 *
 *  @discussion controlSetup enables CoreBluetooths Central Manager and sets delegate to TIBLECBKeyfob class
 *
 */
- (int) controlSetup: (int) s{
    // added RestoreIdentifier for restoration.
    self.CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionRestoreIdentifierKey:@"BLESericeBrowser"} ];
    return 0;
    
    //
}

/*!
 *  @method findBLEPeripherals:
 *
 *  @param timeout timeout in seconds to search for BLE peripherals
 *
 *  @return 0 (Success), -1 (Fault)
 *
 *  @discussion findBLEPeripherals searches for BLE peripherals and sets a timeout when scanning is stopped
 *
 */
- (int) findBLEPeripherals:(int) timeout {
    
    if (self->CM.state  != CBCentralManagerStatePoweredOn) {
        printf("CoreBluetooth not correctly initialized !\r\n");
        printf("State = %d (%s)\r\n",self->CM.state,[self centralManagerStateToString:self.CM.state]);
        return -1;
    }
    
    [NSTimer scheduledTimerWithTimeInterval:(float)timeout target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
    
    [self.CM scanForPeripheralsWithServices:nil options:0]; // Start scanning
    return 0; // Started scanning OK !
}


/*!
 *  @method connectPeripheral:
 *
 *  @param p Peripheral to connect to
 *
 *  @discussion connectPeripheral connects to a given peripheral and sets the activePeripheral property of TIBLECBKeyfob.
 *
 */
- (void) connectPeripheral:(CBPeripheral *)peripheral status:(BOOL)status{
    
    if(status == TRUE)
    {
        printf("Connecting to peripheral with UUID : %s\r\n",[[[peripheral identifier] UUIDString] UTF8String]);
        activePeripheral = peripheral;
        activePeripheral.delegate = self;
        //added Peripheral onnection option for background notification.
        //(NSDictionary *)CBConnectPeripheralOptionNotifyOnDisconnectionKey
        [CM connectPeripheral:activePeripheral options:nil];
    }
    else
    {
        activePeripheral = peripheral;
        activePeripheral.delegate = self;
        [CM cancelPeripheralConnection:self.activePeripheral];
    }
}

/*!
 *  @method centralManagerStateToString:
 *
 *  @param state State to print info of
 *
 *  @discussion centralManagerStateToString prints information text about a given CBCentralManager state
 *
 */
- (const char *) centralManagerStateToString: (int)state{
    switch(state) {
        case CBCentralManagerStateUnknown:
            return "State unknown (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateResetting:
            return "State resetting (CBCentralManagerStateUnknown)";
        case CBCentralManagerStateUnsupported:
            return "State BLE unsupported (CBCentralManagerStateResetting)";
        case CBCentralManagerStateUnauthorized:
            return "State unauthorized (CBCentralManagerStateUnauthorized)";
        case CBCentralManagerStatePoweredOff:
            return "State BLE powered off (CBCentralManagerStatePoweredOff)";
        case CBCentralManagerStatePoweredOn:
            return "State powered up and ready (CBCentralManagerStatePoweredOn)";
        default:
            return "State unknown";
    }
    return "Unknown state";
}

/*!
 *  @method scanTimer:
 *
 *  @param timer Backpointer to timer
 *
 *  @discussion scanTimer is called when findBLEPeripherals has timed out, it stops the CentralManager from scanning further and prints out information about known peripherals
 *
 */
- (void) scanTimer:(NSTimer *)timer {
    [self.CM stopScan];
    printf("Stopped Scanning\r\n");
    printf("Known peripherals : %d\r\n",[self->peripherals count]);
    [self printKnownPeripherals];
}

/*!
 *  @method printKnownPeripherals:
 *
 *  @discussion printKnownPeripherals prints all curenntly known peripherals stored in the peripherals array of TIBLECBKeyfob class
 *
 */
- (void) printKnownPeripherals {
    int i;
    printf("List of currently known peripherals : \r\n");
    for (i=0; i < self->peripherals.count; i++)
    {
        CBPeripheral *p = [self->peripherals objectAtIndex:i];
        
        [self printPeripheralInfo:p];
    }
}

/*
 *  @method printPeripheralInfo:
 *
 *  @param peripheral Peripheral to print info of
 *
 *  @discussion printPeripheralInfo prints detailed info about peripheral
 *
 */
- (void) printPeripheralInfo:(CBPeripheral*)peripheral {
   
    printf("------------------------------------\r\n");
    printf("Peripheral Info :\r\n");
  
    printf("RSSI : %d\r\n",[peripheral.RSSI intValue]);
    printf("Name : %s\r\n",[peripheral.name cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    printf("isConnected : %d\r\n",peripheral.state);
    printf("-------------------------------------\r\n");
    
}


-(void) getAllCharacteristicsForService:(CBPeripheral *)p service:(CBService *)s
{
    [p discoverCharacteristics:nil forService:s];
}


/*
 *  @method getAllServicesFromPeripheral
 *
 *  @param p Peripheral to scan
 *
 *
 *  @discussion getAllServicesFromPeripheral starts a service discovery on a peripheral pointed to by p.
 *  When services are found the didDiscoverServices method is called
 *
 */
-(void) getAllServicesFromPeripheral:(CBPeripheral *)p{
    [p discoverServices:nil]; // Discover all services without filter
}

/*
 *  @method getAllCharacteristicsFromPeripheral
 *
 *  @param p Peripheral to scan
 *
 *
 *  @discussion getAllCharacteristicsFromPeripheral starts a characteristics discovery on a peripheral
 *  pointed to by p
 *
 */
-(void) getAllCharacteristicsFromPeripheral:(CBPeripheral *)p{
    for (int i=0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        printf("Fetching characteristics for service with UUID : %s\r\n",[self CBUUIDToString:s.UUID]);
        [p discoverCharacteristics:nil forService:s];
    }
}


/*
 *  @method CBUUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion CBUUIDToString converts the data of a CBUUID class to a character pointer for easy printout using printf()
 *
 */
-(const char *) CBUUIDToString:(CBUUID *) UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

-(NSString *) CBUUIDToNSString:(CBUUID *) UUID {
    return [UUID.data description];
}


/*
 *  @method UUIDToString
 *
 *  @param UUID UUID to convert to string
 *
 *  @returns Pointer to a character buffer containing UUID in string representation
 *
 *  @discussion UUIDToString converts the data of a CFUUIDRef class to a character pointer for easy printout using printf()
 *
 */
-(const char *) UUIDToString:(NSUUID *) UUID {
    if (!UUID) return "NULL";
    return [[UUID UUIDString] UTF8String];
    
}

/*
 *  @method compareCBUUID
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUID compares two CBUUID's to each other and returns 1 if they are equal and 0 if they are not
 *
 */

-(int) compareCBUUID:(CBUUID *) UUID1 UUID2:(CBUUID *)UUID2 {
    char b1[16];
    char b2[16];
    [UUID1.data getBytes:b1];
    [UUID2.data getBytes:b2];
    if (memcmp(b1, b2, UUID1.data.length) == 0)return 1;
    else return 0;
}

/*
 *  @method compareCBUUIDToInt
 *
 *  @param UUID1 UUID 1 to compare
 *  @param UUID2 UInt16 UUID 2 to compare
 *
 *  @returns 1 (equal) 0 (not equal)
 *
 *  @discussion compareCBUUIDToInt compares a CBUUID to a UInt16 representation of a UUID and returns 1
 *  if they are equal and 0 if they are not
 *
 */
-(int) compareCBUUIDToInt:(CBUUID *)UUID1 UUID2:(UInt16)UUID2 {
    char b1[16];
    [UUID1.data getBytes:b1];
    UInt16 b2 = [self swap:UUID2];
    if (memcmp(b1, (char *)&b2, 2) == 0) return 1;
    else return 0;
}
/*
 *  @method CBUUIDToInt
 *
 *  @param UUID1 UUID 1 to convert
 *
 *  @returns UInt16 representation of the CBUUID
 *
 *  @discussion CBUUIDToInt converts a CBUUID to a Uint16 representation of the UUID
 *
 */
-(UInt16) CBUUIDToInt:(CBUUID *) UUID {
    char b1[16];
    [UUID.data getBytes:b1];
    return ((b1[0] << 8) | b1[1]);
}

/*
 *  @method IntToCBUUID
 *
 *  @param UInt16 representation of a UUID
 *
 *  @return The converted CBUUID
 *
 *  @discussion IntToCBUUID converts a UInt16 UUID to a CBUUID
 *
 */
-(CBUUID *) IntToCBUUID:(UInt16)UUID {
    char t[16];
    t[0] = ((UUID >> 8) & 0xff); t[1] = (UUID & 0xff);
    NSData *data = [[NSData alloc] initWithBytes:t length:16];
    return [CBUUID UUIDWithData:data];
}


/*
 *  @method findServiceFromUUID:
 *
 *  @param UUID CBUUID to find in service list
 *  @param p Peripheral to find service on
 *
 *  @return pointer to CBService if found, nil if not
 *
 *  @discussion findServiceFromUUID searches through the services list of a peripheral to find a
 *  service with a specific UUID
 *
 */
-(CBService *) findServiceFromUUID:(CBUUID *)UUID p:(CBPeripheral *)p {
    for(int i = 0; i < p.services.count; i++) {
        CBService *s = [p.services objectAtIndex:i];
        if ([self compareCBUUID:s.UUID UUID2:UUID]) return s;
    }
    return nil; //Service not found on this peripheral
}

/*
 *  @method findCharacteristicFromUUID:
 *
 *  @param UUID CBUUID to find in Characteristic list of service
 *  @param service Pointer to CBService to search for charateristics on
 *
 *  @return pointer to CBCharacteristic if found, nil if not
 *
 *  @discussion findCharacteristicFromUUID searches through the characteristic list of a given service
 *  to find a characteristic with a specific UUID
 *
 */
-(CBCharacteristic *) findCharacteristicFromUUID:(CBUUID *)UUID service:(CBService*)service {
    for(int i=0; i < service.characteristics.count; i++) {
        CBCharacteristic *c = [service.characteristics objectAtIndex:i];
        if ([self compareCBUUID:c.UUID UUID2:UUID]) return c;
    }
    return nil; //Characteristic not found on this service
}

//----------------------------------------------------------------------------------------------------
//
//
//
//
//CBCentralManagerDelegate protocol methods here
// Documented in CoreBluetooth documentation
//
//
//
//
//----------------------------------------------------------------------------------------------------

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    printf("Status of CoreBluetooth central manager changed %d (%s)\r\n",central.state,[self centralManagerStateToString:central.state]);
}

-(void)centralManager:(CBCentralManager *) central willRestoreState:(NSDictionary *)dict

{
   self.peripherals =dict[CBCentralManagerRestoredStatePeripheralsKey];
    
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (!self.peripherals) self.peripherals = [[NSMutableArray alloc] initWithObjects:peripheral,nil];
    else {
        
        for(int i = 0; i < self.peripherals.count; i++) {
            CBPeripheral *p = [self.peripherals objectAtIndex:i];
         
            int nResult = [[p identifier] isEqual:([peripheral identifier] )];
            if (nResult == 1) {
                [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
                printf("Duplicate UUID found updating ...\r\n");
                return;
            }
            else if(nResult == -1)
            {// Work around: if the UUIDs don't match, check the advertisement data
                if(![p.name isEqualToString:peripheral.name])
                {
                    [self.peripherals replaceObjectAtIndex:i withObject:peripheral];
                    printf("Duplicate UUID found updating ...\r\n");
                    return;
                }
            }
         
        }
        
        [self->peripherals addObject:peripheral];
        printf("New UUID, adding\r\n");
    }
    printf("didDiscoverPeripheral\r\n");
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    printf("Connection to peripheral with UUID : %s successfull\r\n",[[[peripheral identifier] UUIDString] UTF8String]);
    self.activePeripheral = peripheral;
    
    if(dvController)
    {
        [(DeviceViewController *) [self dvController] OnConnected:TRUE];
    }

    //[self.activePeripheral discoverServices:nil];
}


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    printf("Failed to connect to peripheral %s\r\n",[[[peripheral identifier] UUIDString] UTF8String]);
    self.activePeripheral = peripheral;
    
    if(dvController)
    {
        [(DeviceViewController *) [self dvController] OnConnected:FALSE];
    }
    
    //[self.activePeripheral discoverServices:nil];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"KeyfobViewController didDisconnectPeripheral");
    
    if(dvController)
    {
        [(DeviceViewController *) [self dvController] OnConnected:FALSE];
    }
}

//----------------------------------------------------------------------------------------------------
//
//
//
//
//
//CBPeripheralDelegate protocol methods beneth here
//
//
//
//
//
//----------------------------------------------------------------------------------------------------


/*
 *  @method didDiscoverCharacteristicsForService
 *
 *  @param peripheral Pheripheral that got updated
 *  @param service Service that characteristics where found on
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverCharacteristicsForService is called when CoreBluetooth has discovered
 *  characteristics on a service, on a peripheral after the discoverCharacteristics routine has been called on the service
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (!error) {
        printf("Characteristics of service with UUID : %s found\r\n",[self CBUUIDToString:service.UUID]);
        
        if(svController)
        {
            [(ServiceViewController *) [self svController] AllCharacteristics:service.characteristics];
        }
    }
    else {
        printf("Characteristic discorvery unsuccessfull !\r\n");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error {
}

/*
 *  @method didDiscoverServices
 *
 *  @param peripheral Pheripheral that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didDiscoverServices is called when CoreBluetooth has discovered services on a
 *  peripheral after the discoverServices routine has been called on the peripheral
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (!error) {
        printf("Services of peripheral with UUID : %s found\r\n",[[[peripheral identifier] UUIDString] UTF8String]);
        
        if(dvController)
        {
            [(DeviceViewController *) [self dvController] OnDiscoverServices:peripheral.services];
        }
        
        //[self getAllCharacteristicsFromPeripheral:peripheral];
    }
    else {
        printf("Service discovery was unsuccessfull !\r\n");
    }
}

/*
 *  @method didUpdateNotificationStateForCharacteristic
 *
 *  @param peripheral Pheripheral that got updated
 *  @param characteristic Characteristic that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didUpdateNotificationStateForCharacteristic is called when CoreBluetooth has updated a
 *  notification state for a characteristic
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (!error) {
        printf("Updated notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[[[peripheral identifier] UUIDString] UTF8String]);
    }
    else {
        printf("Error in setting notification state for characteristic with UUID %s on service with  UUID %s on peripheral with UUID %s\r\n",[self CBUUIDToString:characteristic.UUID],[self CBUUIDToString:characteristic.service.UUID],[[[peripheral identifier] UUIDString] UTF8String]);
        printf("Error code was %s\r\n",[[error description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy]);
    }
    
}

/*
 *  @method didUpdateValueForCharacteristic
 *
 *  @param peripheral Pheripheral that got updated
 *  @param characteristic Characteristic that got updated
 *  @error error Error message if something went wrong
 *
 *  @discussion didUpdateValueForCharacteristic is called when CoreBluetooth has updated a
 *  characteristic for a peripheral. All reads and notifications come here to be processed.
 *
 */

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (!error) {
        printf("Services of peripheral with UUID : %s found\r\n",[[[peripheral identifier] UUIDString] UTF8String]);
        
        if(cvController)
        {
            [(CharViewController *) [self cvController] OnReadChar:characteristic];
        }
    }
    else {
        printf("updateValueForCharacteristic failed !");
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
}

- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    
}

-(NSString *)GetServiceName:(CBUUID *)UUID{
    
    UInt16 _uuid = [self CBUUIDToInt:UUID];

    switch(_uuid)
    {
        case 0x1800: return @"Generic Access"; break;
        case 0x1801: return @"Generic Attribute"; break;
        case 0x1802: return @"Immediate Alert"; break;
        case 0x1803: return @"Link Loss"; break;
        case 0x1804: return @"Tx Power"; break;
        case 0x1805: return @"Current Time Service"; break;
        case 0x1806: return @"Reference Time Update Service"; break;
        case 0x1807: return @"Next DST Change Service"; break;
        case 0x1808: return @"Glucose"; break;
        case 0x1809: return @"Health Thermometer"; break;
        case 0x180A: return @"Device Information"; break;
        case 0x180B: return @"Network Availability Service"; break;
        case 0x180C: return @"Watchdog"; break;
        case 0x180D: return @"Heart Rate"; break;
        case 0x180E: return @"Phone Alert Status Service"; break;
        case 0x180F: return @"Battery Service"; break;
        case 0x1810: return @"Blood Pressure"; break;
        case 0x1811: return @"Alert Notification Service"; break;
        case 0x1812: return @"Human Interface Device"; break;
        case 0x1813: return @"Scan Parameters"; break;
        case 0x1814: return @"RUNNING SPEED AND CADENCE"; break;
        case 0x1815: return @"Automation IO"; break;
        case 0x1816: return @"Cycling Speed and Cadence"; break;
        case 0x1817: return @"Pulse Oximeter"; break;
        case 0x1818: return @"Cycling Power Service"; break;
        case 0x1819: return @"Location and Navigation Service"; break;
        case 0x181A: return @"Continous Glucose Measurement Service"; break;
        case 0x2A00: return @"Device Name"; break;
        case 0x2A01: return @"Appearance"; break;
        case 0x2A02: return @"Peripheral Privacy Flag"; break;
        case 0x2A03: return @"Reconnection Address"; break;
        case 0x2A04: return @"Peripheral Preferred Connection Parameters"; break;
        case 0x2A05: return @"Service Changed"; break;
        case 0x2A06: return @"Alert Level"; break;
        case 0x2A07: return @"Tx Power Level"; break;
        case 0x2A08: return @"Date Time"; break;
        case 0x2A09: return @"Day of Week"; break;
        case 0x2A0A: return @"Day Date Time"; break;
        case 0x2A0B: return @"Exact Time 100"; break;
        case 0x2A0C: return @"Exact Time 256"; break;
        case 0x2A0D: return @"DST Offset"; break;
        case 0x2A0E: return @"Time Zone"; break;
        case 0x2A0F: return @"Local Time Information"; break;
        case 0x2A10: return @"Secondary Time Zone"; break;
        case 0x2A11: return @"Time with DST"; break;
        case 0x2A12: return @"Time Accuracy"; break;
        case 0x2A13: return @"Time Source"; break;
        case 0x2A14: return @"Reference Time Information"; break;
        case 0x2A15: return @"Time Broadcast"; break;
        case 0x2A16: return @"Time Update Control Point"; break;
        case 0x2A17: return @"Time Update State"; break;
        case 0x2A18: return @"Glucose Measurement"; break;
        case 0x2A19: return @"Battery Level"; break;
        case 0x2A1A: return @"Battery Power State"; break;
        case 0x2A1B: return @"Battery Level State"; break;
        case 0x2A1C: return @"Temperature Measurement"; break;
        case 0x2A1D: return @"Temperature Type"; break;
        case 0x2A1E: return @"Intermediate Temperature"; break;
        case 0x2A1F: return @"Temperature in Celsius"; break;
        case 0x2A20: return @"Temperature in Fahrenheit"; break;
        case 0x2A21: return @"Measurement Interval"; break;
        case 0x2A22: return @"Boot Keyboard Input Report"; break;
        case 0x2A23: return @"System ID"; break;
        case 0x2A24: return @"Model Number String"; break;
        case 0x2A25: return @"Serial Number String"; break;
        case 0x2A26: return @"Firmware Revision String"; break;
        case 0x2A27: return @"Hardware Revision String"; break;
        case 0x2A28: return @"Software Revision String"; break;
        case 0x2A29: return @"Manufacturer Name String"; break;
        case 0x2A2A: return @"IEEE 11073-20601 Regulatory Certification Data List"; break;
        case 0x2A2B: return @"Current Time"; break;
        case 0x2A2C: return @"Elevation"; break;
        case 0x2A2D: return @"Latitude"; break;
        case 0x2A2E: return @"Longitude"; break;
        case 0x2A2F: return @"Position 2D"; break;
        case 0x2A30: return @"Position 3D"; break;
        case 0x2A31: return @"Scan Refresh"; break;
        case 0x2A32: return @"Boot Keyboard Output Report"; break;
        case 0x2A33: return @"Boot Mouse Input Report"; break;
        case 0x2A34: return @"Glucose Measurement Context"; break;
        case 0x2A35: return @"Blood Pressure Measurement"; break;
        case 0x2A36: return @"Intermediate Cuff Pressure"; break;
        case 0x2A37: return @"Heart Rate Measurement"; break;
        case 0x2A38: return @"Body Sensor Location"; break;
        case 0x2A39: return @"Heart Rate Control Point"; break;
        case 0x2A3A: return @"Removable"; break;
        case 0x2A3B: return @"Service Required"; break;
        case 0x2A3C: return @"Scientific Temperature in Celsius"; break;
        case 0x2A3D: return @"String"; break;
        case 0x2A3E: return @"Network Availability"; break;
        case 0x2A3F: return @"Alert Status"; break;
        case 0x2A40: return @"Ringer Control Point"; break;
        case 0x2A41: return @"Ringer Setting"; break;
        case 0x2A42: return @"Alert Category ID Bit Mask"; break;
        case 0x2A43: return @"Alert Category ID"; break;
        case 0x2A44: return @"Alert Notification Control Point"; break;
        case 0x2A45: return @"Unread Alert Status"; break;
        case 0x2A46: return @"New Alert"; break;
        case 0x2A47: return @"Supported New Alert Category"; break;
        case 0x2A48: return @"Supported Unread Alert Category"; break;
        case 0x2A49: return @"Blood Pressure Feature"; break;
        case 0x2A4A: return @"HID Information"; break;
        case 0x2A4B: return @"Report Map"; break;
        case 0x2A4C: return @"HID Control Point"; break;
        case 0x2A4D: return @"Report"; break;
        case 0x2A4E: return @"Protocol Mode"; break;
        case 0x2A4F: return @"Scan Interval Window"; break;
        case 0x2A50: return @"PnP ID"; break;
        case 0x2A51: return @"Glucose Features"; break;
        case 0x2A52: return @"Record Access Control Point"; break;
        case 0x2A53: return @"RSC Measurement"; break;
        case 0x2A54: return @"RSC Feature"; break;
        case 0x2A55: return @"SC Control Point"; break;
        case 0x2A56: return @"Digital Input"; break;
        case 0x2A57: return @"Digital Output"; break;
        case 0x2A58: return @"Analog Input"; break;
        case 0x2A59: return @"Analog Output"; break;
        case 0x2A5A: return @"Aggregate Input"; break;
        case 0x2A5B: return @"CSC Measurement"; break;
        case 0x2A5C: return @"CSC Feature"; break;
        case 0x2A5D: return @"Sensor Location"; break;
        case 0x2A5E: return @"Pulse Oximetry Spot-check Measurement"; break;
        case 0x2A5F: return @"Pulse Oximetry Continuous Measurement"; break;
        case 0x2A60: return @"Pulse Oximetry Pulsatile Event"; break;
        case 0x2A61: return @"Pulse Oximetry Features"; break;
        case 0x2A62: return @"Pulse Oximetry Control Point"; break;
        case 0x2A63: return @"Cycling Power Measurement Characteristic"; break;
        case 0x2A64: return @"Cycling Power Vector Characteristic"; break;
        case 0x2A65: return @"Cycling Power Feature Characteristic"; break;
        case 0x2A66: return @"Cycling Power Control Point Characteristic"; break;
        case 0x2A67: return @"Location and Speed Characteristic"; break;
        case 0x2A68: return @"Navigation Characteristic"; break;
        case 0x2A69: return @"Position Quality Characteristic"; break;
        case 0x2A6A: return @"LN Feature Characteristic"; break;
        case 0x2A6B: return @"LN Control Point Characteristic"; break;
        case 0x2A6C: return @"CGM Measurement Characteristic"; break;
        case 0x2A6D: return @"CGM Features Characteristic"; break;
        case 0x2A6E: return @"CGM Status Characteristic"; break;
        case 0x2A6F: return @"CGM Session Start Time Characteristic"; break;
        case 0x2A70: return @"Application Security Point Characteristic"; break;
        case 0x2A71: return @"CGM Specific Ops Control Point Characteristic"; break;
        default:
            return @"Custom Profile";
            break;
    }
}



@end
