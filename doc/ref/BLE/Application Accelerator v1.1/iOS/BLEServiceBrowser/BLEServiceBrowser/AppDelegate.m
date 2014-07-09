//
//  AppDelegate.m
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/22/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "DeviceViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [self.splitViewController.viewControllers objectAtIndex:0];
        // assign the main view controller
        _mainviewController = (MainViewController *) [navigationController topViewController];
        self.splitViewController.delegate = (id)navigationController.topViewController;
    }
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void) setMainViewDelegate:(DeviceViewController *)controller
{
    //Set the main view controller delegate and set the deviceviewcontroller as the splitviewcontroller delegate
    // to enable messages to e sent to the correct view controller
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        _mainviewController.delegate = controller;
        _deviceviewController = controller;
        self.splitViewController.delegate = (id)controller;
    }
}

-(void) setServiceViewDelegate:(ServiceViewController *)controller
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        //Set the main view controller delegate and set the serviceviewcontroller as the splitviewcontroller delegate
        // to enable messages to e sent to the correct view controller
        _deviceviewController.delegate = controller;
        _serviceviewController = controller;
        self.splitViewController.delegate = (id)controller;
    }
}

-(void) setCharViewDelegate:(CharViewController *)controller
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        //Set the main view controller delegate and set the charviewcontroller as the splitviewcontroller delegate
        // to enable messages to e sent to the correct view controller
        _serviceviewController.delegate = controller;
        self.splitViewController.delegate = (id)controller;
    }
}

-(void) clearViewControllers
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // Clear the view controller list and send it back to being the deviceviewcontroller
        UINavigationController *detailNavigationController = [self.splitViewController.viewControllers objectAtIndex:1];
        [detailNavigationController popToViewController:_deviceviewController animated:YES];
        self.splitViewController.delegate = (id)detailNavigationController.topViewController;
    }
}

@end
