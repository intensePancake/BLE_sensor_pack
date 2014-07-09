//
//  MainViewController.h
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/22/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "SelectionDelegate.h"

//@class DeviceViewController;

@interface MainViewController : UITableViewController{
}

// UI elements actions
- (IBAction)ScanButton:(id)sender;

// Other properties
//@property (strong, nonatomic) DeviceViewController *deviceViewController;
@property (nonatomic) BOOL scanState;
@property (nonatomic, strong)NSMutableArray *discoveredPeripherals;
@property (nonatomic, assign) id<SelectionDelegate> delegate;

+(NSString *)getCBCentralStateName:(CBCentralManagerState) state;

@end
