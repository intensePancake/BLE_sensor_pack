//
//  CharViewController.h
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/26/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEAdapter.h"


@interface CharViewController : UIViewController<UISplitViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, SelectionDelegate>{
}

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) CBPeripheral * p;
@property (strong, nonatomic) IBOutlet UIButton *WriteButton;
@property (strong, nonatomic) IBOutlet UIButton *WriteCommandButton;

@property (strong, nonatomic) IBOutlet UIButton *ReadButton;
- (IBAction)WriteButtonPressed:(id)sender;
- (IBAction)ReadButtonPressed:(id)sender;
- (IBAction)WriteCommandButtonPressed:(id)sender;
- (IBAction)NotificationSwitchChanged:(id)sender;
- (IBAction)InidicationSwitchChanged:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *textBoxHex;

@property (strong, nonatomic) IBOutlet UISwitch *NotificationSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *IndicationSwitch;

-(void) OnReadChar:(CBCharacteristic *)characteristic;
-(void) OnWriteChar:(CBCharacteristic *)characteristic;
-(NSData *)dataFromHexString:(NSString *)string;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end


