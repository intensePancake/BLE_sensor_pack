//
//  DetailViewController.h
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/22/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectionDelegate.h"

@class ServiceViewController;

@interface DeviceViewController : UIViewController <UISplitViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, SelectionDelegate>{
    IBOutlet UIBarButtonItem *connectButton;
}

- (IBAction)connectButtonPressed:(id)sender;

-(void) OnConnected:(BOOL)status;
-(void) OnDiscoverServices:(NSArray *)s;
//-(void) updateView;

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (strong, nonatomic) ServiceViewController *serviceViewController;
@property (strong, nonatomic) IBOutlet UITableView *serviceTableViewOutlet;
@property (strong, nonatomic) IBOutlet UILabel *connectionStatusLabel;
@property (nonatomic, assign) id<SelectionDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *serviceLabel;
@property (strong, nonatomic) IBOutlet UILabel *advertisementLabel;
@property (strong, nonatomic) IBOutlet UILabel *noDevicesLabel;

@end
