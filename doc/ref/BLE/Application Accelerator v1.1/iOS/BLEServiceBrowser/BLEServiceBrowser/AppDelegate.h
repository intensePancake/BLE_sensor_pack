//
//  AppDelegate.h
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/22/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"
#import "DeviceViewController.h"
#import "ServiceViewController.h"
#import "CharViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    
}

// Add delegate methods to be called from ViewControllers
-(void) setMainViewDelegate:(DeviceViewController *)controller;
-(void) setServiceViewDelegate:(ServiceViewController *)controller;
-(void) setCharViewDelegate:(CharViewController *)controller;
-(void) clearViewControllers;

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MainViewController *mainviewController;
@property (strong, nonatomic) DeviceViewController *deviceviewController;
@property (strong, nonatomic) ServiceViewController *serviceviewController;
@property (strong, nonatomic) UISplitViewController *splitViewController;

@end
