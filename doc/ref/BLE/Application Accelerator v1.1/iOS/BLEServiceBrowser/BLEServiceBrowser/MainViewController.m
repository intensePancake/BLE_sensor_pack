//
//  MainViewController.m
//  BLEServiceBrowser
//
//  Updated for iOS7
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import "MainViewController.h"
#import "BLEAdapter.h"
#import "AppDelegate.h"

@interface MainViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MainViewController

BLEAdapter *t;

#pragma mark - View lifecycle
- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    t = [BLEAdapter sharedBLEAdapter];
    [t controlSetup:1]; 
    
    self.scanState = NO;  // scanning
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)insertScannedperipherals
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }

    for(int i=0; i < [t.peripherals count]; i++)
    {
        [_objects insertObject:[[t peripherals] objectAtIndex:i] atIndex:0];

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    CBPeripheral *object = _objects[indexPath.row];
    cell.textLabel.text = [object name];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        // set up the selected peripheral into the attached delegate
        CBPeripheral *object = _objects[indexPath.row];
        if(_delegate) {
            [_delegate selectedPeripheral:object];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        CBPeripheral *object = _objects[indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}
#pragma mark - UI Methods
- (IBAction)ScanButton:(id)sender {

    if (! self.scanState)
    {
        // New Scan - Make sure to empty _objects
        [_objects removeAllObjects];
        [self.tableView reloadData];
        
        // Call the clearUI method of the attached viewcontroller attached as a delegate
        if(_delegate) {
            [_delegate clearUI:YES];
        }
        
        // Clear the viewcontrollers and reset back to first viewcontroller
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate clearViewControllers];
        
        // start progress spinner
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

        if (t.activePeripheral) if(t.activePeripheral.state) [[t CM] cancelPeripheralConnection:[t activePeripheral]];
        if (t.peripherals) t.peripherals = nil;
        
        [t findBLEPeripherals:2];
        [NSTimer scheduledTimerWithTimeInterval:(float)2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];
    }
    else  // stop scanning
    {
    }
}

// Called when scan period is over to connect to the first found peripheral
-(void) connectionTimer:(NSTimer *)timer {
    if(t.peripherals.count > 0)
    {
        [t printKnownPeripherals];
        
        if( t.peripherals.count > 0)
            [self insertScannedperipherals];
    }
    // stop progress spinner
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// Converts CBCentralManagerState to a string... implement as a category on CBCentralManagerState?
+(NSString *)getCBCentralStateName:(CBCentralManagerState) state
{
    NSString *stateName;
    
    switch (state) {
        case CBCentralManagerStatePoweredOn:
            stateName = @"Bluetooth Powered On - Ready";
            break;
        case CBCentralManagerStateResetting:
            stateName = @"Resetting";
            break;
            
        case CBCentralManagerStateUnsupported:
            stateName = @"Unsupported";
            break;
            
        case CBCentralManagerStateUnauthorized:
            stateName = @"Unauthorized";
            break;
            
        case CBCentralManagerStatePoweredOff:
            stateName = @"Bluetooth Powered Off";
            break;
            
        default:
            stateName = @"Unknown";
            break;
    }
    return stateName;
}
@end
