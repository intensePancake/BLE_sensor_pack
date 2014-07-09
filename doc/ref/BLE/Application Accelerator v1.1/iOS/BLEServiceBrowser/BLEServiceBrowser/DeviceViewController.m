//
//  DeviceViewController.m
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/22/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import "DeviceViewController.h"
#import "ServiceViewController.h"
#import "BLEAdapter.h"
#import "AppDelegate.h"
#import "TestService.h"


#import <QuartzCore/QuartzCore.h>

@interface DeviceViewController (){
    NSMutableArray *_objects;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation DeviceViewController

BLEAdapter *t;
CBPeripheral * p;


#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        p = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.
    t.dvController = self;

    if(p)
    {
        [self clearUI:NO];

        self.detailDescriptionLabel.text = [p description];//[p name];
        self.detailDescriptionLabel.layer.borderColor = [UIColor greenColor].CGColor;
        self.detailDescriptionLabel.layer.borderWidth = 1.0;
    }
}
-(void)viewWillAppear:(BOOL)animated
{
    t = [BLEAdapter sharedBLEAdapter];
    
    t.dvController = self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the deviceviewcontroller as the attached delegate to the application
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setMainViewDelegate:self];
    // Clear the UI
    [self clearUI:YES];
    
    self.detailDescriptionLabel.text = @"";
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    _connectionStatusLabel.text = @"Not Connected";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[tableView dequeueReusableCellWithIdentifier:@"Cell"] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    CBService *aService = _objects[indexPath.row];

    cell.textLabel.text = [t GetServiceName:aService.UUID];    
    cell.detailTextLabel.text = [aService.UUID.data description];// cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        CBService *object = _objects[indexPath.row];
        // set up the selected service into the attached delegate
        if(_delegate) {
            [_delegate selectedService:object];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showService"]) {
        NSIndexPath *indexPath = [self.serviceTableViewOutlet indexPathForSelectedRow];
        CBService *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

#pragma mark - BLEAdapterDelegate
-(void) OnDiscoverServices:(NSArray *)s
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    
    for (CBService *aService in s)
    {
        [_objects insertObject:aService atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

        [self.serviceTableViewOutlet insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];


        NSLog(@"KeyfobViewController Service found with UUID: %@", aService.UUID);
    }

}

-(void) OnConnected:(BOOL)status
{
    // Connect
    if(status == TRUE)
    {
        _connectionStatusLabel.text = @"Connected";
        [(UIBarButtonItem *)connectButton setTitle:@"Disconnect"];

        [t getAllServicesFromPeripheral:p];
    }
    else{
        _connectionStatusLabel.text = @"Not Connected";
        [(UIBarButtonItem *)connectButton setTitle:@"Connect"];

    }
}

#pragma mark - Delegate methods
-(void)selectedCharacteristic:(CBCharacteristic *)characteristic
{
}

-(void)selectedPeripheral:(CBPeripheral *)peripheral
{
    [self setDetailItem:peripheral];
}

-(void)selectedService:(CBService *)service
{
}

-(void)clearUI:(BOOL)clear
{
    // Clear the UI of all text if value is true otherwise replace the labels, table ready for population
    if(clear) {
        self.serviceTableViewOutlet.hidden = YES;
        self.navigationItem.rightBarButtonItem = nil;
        self.detailDescriptionLabel.hidden = YES;
        self.connectionStatusLabel.hidden = YES;
        self.advertisementLabel.hidden = YES;
        self.statusLabel.hidden = YES;
        self.serviceLabel.hidden = YES;
        self.noDevicesLabel.hidden = NO;
        [_objects removeAllObjects];
        [self.serviceTableViewOutlet reloadData];
    }
    else {
        self.serviceTableViewOutlet.hidden = NO;
        self.navigationItem.rightBarButtonItem = connectButton;
        self.detailDescriptionLabel.hidden = NO;
        self.connectionStatusLabel.hidden = NO;
        self.advertisementLabel.hidden = NO;
        self.statusLabel.hidden = NO;
        self.serviceLabel.hidden = NO;
        self.noDevicesLabel.hidden = YES;
    }
}

#pragma mark - UI Methods
- (IBAction)connectButtonPressed:(id)sender {
    
    if (! p.state)
    {
        // New Scan - Make sure to empty _objects
        [_objects removeAllObjects];
        [self.serviceTableViewOutlet reloadData];
        [t connectPeripheral:p status:TRUE];
        
    }
    else  // stop scanning
    {
        [t connectPeripheral:p status:FALSE];
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

- (void)viewDidUnload {
    [self setServiceTableViewOutlet:nil];
    connectButton = nil;
    [self setConnectionStatusLabel:nil];
    [super viewDidUnload];
}

@end
