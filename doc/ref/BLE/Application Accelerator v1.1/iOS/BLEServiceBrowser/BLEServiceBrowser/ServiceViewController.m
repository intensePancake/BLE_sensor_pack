//
//  ServiceViewController.m
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/25/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import "ServiceViewController.h"
#import "AppDelegate.h"

@interface ServiceViewController (){
    NSMutableArray *_objects;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation ServiceViewController

BLEAdapter *t;
CBPeripheral * p;
CBService *s;

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        s = newDetailItem;
        p = s.peripheral;
        t.activePeripheral = p;
        
        // Update the view.
        [self configureView];
        
        if (self.masterPopoverController != nil) {
            [self.masterPopoverController dismissPopoverAnimated:YES];
        }
    }
}

- (void)configureView
{
    // Update the user interface for the detail item.
    t.svController = self;
    
    if(s)
    {
        self.title = [t CBUUIDToNSString:s.UUID];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    t = [BLEAdapter sharedBLEAdapter];
    
    t.svController = self;
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setServiceViewDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setServiceViewDelegate:self];
    [self configureView];
    
    [t getAllCharacteristicsForService:p service:s];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegate methods
-(void)clearUI:(BOOL)clear
{
}

-(void)selectedCharacteristic:(CBCharacteristic *)characteristic
{
}

-(void)selectedService:(TestService *)service
{
    [self setDetailItem:service];
}

-(void)selectedPeripheral:(CBPeripheral *)peripheral
{
}

#pragma mark - BLEAdapterDelegate
-(void) AllCharacteristics:(NSArray *)c
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    
    for (CBCharacteristic *aCharacteristic in c)
    {
        [_objects insertObject:aCharacteristic atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        NSLog(@"KeyfobViewController Characteristic found with UUID: %@", aCharacteristic.UUID);
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[tableView dequeueReusableCellWithIdentifier:@"Cell"] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    // Configure the cell...
    CBCharacteristic *aCharacteristic = _objects[indexPath.row];
    cell.textLabel.text = [t CBUUIDToNSString:aCharacteristic.UUID];
    cell.textLabel.text = [t GetServiceName:aCharacteristic.UUID];
    cell.detailTextLabel.text = [aCharacteristic.UUID.data description];
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CBCharacteristic *object = _objects[indexPath.row];
        // set up the selected characteristic into the attached delegate
        if(_delegate) {
            [_delegate selectedCharacteristic:object];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showCharacteristic"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CBCharacteristic *object = _objects[indexPath.row];
        
        [[segue destinationViewController] setDetailItem:object];
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Scan", @"Scan");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
