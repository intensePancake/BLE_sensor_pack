//
//  ServiceViewController.h
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/25/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEAdapter.h"

@interface ServiceViewController : UITableViewController <UISplitViewControllerDelegate, SelectionDelegate>
    @property (strong, nonatomic) id detailItem;
    @property (strong, nonatomic) CBPeripheral * p;
    @property (nonatomic, assign) id<SelectionDelegate> delegate;

-(void) AllCharacteristics:(NSArray *)c;

@end
