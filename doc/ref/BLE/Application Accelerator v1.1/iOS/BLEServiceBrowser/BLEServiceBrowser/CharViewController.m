//
//  CharViewController.m
//  BLEServiceBrowser
//
//  Created by Muhammad on 3/26/13.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import "CharViewController.h"
#import "BLEAdapter.h"
#import "AppDelegate.h"

@interface CharViewController (){
}

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation CharViewController

BLEAdapter *t;
CBPeripheral * p;
CBCharacteristic *c;

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        c = newDetailItem;
        t = [BLEAdapter sharedBLEAdapter];
        p = t.activePeripheral;
        
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
    t.cvController = self;
    
    if(p)
    {
        [p discoverDescriptorsForCharacteristic:c];
    }
}

-(void) OnReadChar:(CBCharacteristic *)characteristic{
    NSLog(@"KeyfobViewController didUpdateValueForCharacteristic %@", characteristic);
    
    [self textBoxHex].text = [[characteristic value] description];    
    [self.tableView reloadData];

}

-(void) OnWriteChar:(CBCharacteristic *)characteristic{
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Set the charviewcontroller as the attached delegate to the application
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setCharViewDelegate:self];
    
    /* // b r w1 w2 n i a e]*/
    CBCharacteristicProperties properties = [c properties];

    [[self ReadButton] setEnabled:properties & CBCharacteristicPropertyRead?1:0];
    [[self WriteButton] setEnabled:properties & CBCharacteristicPropertyWrite?1:0];
    [[self WriteCommandButton] setEnabled:properties & CBCharacteristicPropertyWriteWithoutResponse?1:0];
    self.NotificationSwitch.enabled = properties & CBCharacteristicPropertyNotify?1:0;
    self.IndicationSwitch.enabled = properties & CBCharacteristicPropertyIndicate?1:0;

    self.NotificationSwitch.on = NO;
    self.IndicationSwitch.on = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSData *)dataFromHexString:(NSString *)string {
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    int length = string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
        
    }
    
    return data;
}

- (IBAction)WriteButtonPressed:(id)sender {
    if(p)
    {
        NSData * data = [self dataFromHexString:[self textBoxHex].text];
        NSLog(@"%@", data);

        if(c)
            [p writeValue:data forCharacteristic:c type:CBCharacteristicWriteWithResponse];
    }
}

- (IBAction)ReadButtonPressed:(id)sender {
    if(p)
    {
        if(c)
            [p readValueForCharacteristic:c];
    }
}

- (IBAction)WriteCommandButtonPressed:(id)sender {
    if(p)
    {
        NSData * data = [self dataFromHexString:[self textBoxHex].text];
        NSLog(@"%@", data);

        if(c)
            [p writeValue:data forCharacteristic:c type:CBCharacteristicWriteWithoutResponse];
    }

}



- (IBAction)NotificationSwitchChanged:(id)sender {
    if(self.NotificationSwitch.on)
        [p setNotifyValue:YES forCharacteristic:c];
    else
        [p setNotifyValue:NO forCharacteristic:c];

}

- (IBAction)InidicationSwitchChanged:(id)sender {
}
- (void)viewDidUnload {
    [self ReadButtonPressed:nil];
    [self WriteCommandButtonPressed:nil];
    [self WriteButtonPressed:nil];
    [self setNotificationSwitch:nil];
    [self setIndicationSwitch:nil];
    [self setTextBoxHex:nil];
    [self setReadButton:nil];
    [self setWriteButton:nil];
    [self setWriteCommandButton:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}

#pragma mark - Delegate methods
-(void)clearUI:(BOOL)clear
{
}

-(void)selectedCharacteristic:(CBCharacteristic *)characteristic
{
    [self setDetailItem:characteristic];
    [self.tableView reloadData];
}

-(void)selectedService:(TestService *)service
{
    [self setDetailItem:service];
}

-(void)selectedPeripheral:(CBPeripheral *)peripheral
{
}

#pragma mark - Table view data source

#define ROWS_PER_SECTION 3

// Each section is a unique characteristic
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

// Displaying 5 items of information about each characteristic
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // Return the number of rows in the section.
    return  ROWS_PER_SECTION;
}

/*
 *
 * Method Name:  tableView:cellForRowAtIndexPath
 *
 * Description:  Displays the content for each cell in the table. Each cell corresponds to an informational item about a characteristic.
 *
 * Parameter(s): tableView - the table being processed
 *               indexPath - corresponding section and row for the table cell
 *
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
     UITableViewCell *cell = [[tableView dequeueReusableCellWithIdentifier:@"Cell"] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    CBCharacteristic * characteristic = c;
    
    cell.textLabel.text = @"";
    cell.detailTextLabel.text = @"";
    
    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = @"Characteristic Property";
        
            CBCharacteristicProperties properties = [c properties];
            /* // b r w1 w2 n i a e]*/
            
            cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"B:%d R:%d w:%d W:%d N:%d I:%d A:%d E:%d",
                                         properties & CBCharacteristicPropertyBroadcast?1:0,
                                         properties & CBCharacteristicPropertyRead?1:0,
                                         properties & CBCharacteristicPropertyWriteWithoutResponse?1:0,
                                         properties & CBCharacteristicPropertyWrite?1:0,
                                         properties & CBCharacteristicPropertyNotify?1:0,
                                         properties & CBCharacteristicPropertyIndicate?1:0,
                                         properties & CBCharacteristicPropertyAuthenticatedSignedWrites?1:0,
                                         properties & CBCharacteristicPropertyExtendedProperties?1:0
                                         ];
            break;
            
        case 1:
            cell.textLabel.text = @"Value";
            if (characteristic.value)
            {
                cell.detailTextLabel.text = [@"0x" stringByAppendingString:[characteristic.value description]];
            }
            else
            {
                if (!(characteristic.properties & CBCharacteristicPropertyRead))
                    cell.detailTextLabel.text = @"Not Readable";
            }
            break;
            
        case 2:
            cell.textLabel.text = @"Descriptors";
            cell.detailTextLabel.text = @"";
            break;
            
        default:
            break;
    }
    
    return cell;
}


#pragma mark - Table view delegate

// Handle row selection if needed
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // empty
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
