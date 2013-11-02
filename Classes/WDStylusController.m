//
//  WDStylusController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDStylusController.h"
#import "WDStylusManager.h"
#import "WDStylusTableCell.h"
#import "WDUtilities.h"

@interface WDStylusController ()

@end

@implementation WDStylusController

@synthesize stylusTable;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    self.title = NSLocalizedString(@"Accessories", @"Accessories");
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(stylusConnected:)
               name:WDStylusDidConnectNotification object:nil];
    [nc addObserver:self selector:@selector(stylusDisconnected:)
               name:WDStylusDidDisconnectNotification object:nil];
    
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) stylusConnected:(NSNotification *)aNotification
{
    [self.stylusTable reloadData];
}

- (void) stylusDisconnected:(NSNotification *)aNotification
{
    [self.stylusTable reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGSize contentSize = self.view.frame.size;
    contentSize.height = 60 * [[WDStylusManager sharedStylusManager] numberOfStylusTypes] - 1;
    self.contentSizeForViewInPopover = contentSize;
    
    self.stylusTable.delegate = self;
    self.stylusTable.dataSource = self;
    self.stylusTable.rowHeight = 60;
    
    if (WDDeviceIsPhone()) {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(done:)];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [[WDStylusManager sharedStylusManager] setMode:(WDStylusType)indexPath.section];
    
    [tableView reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [WDStylusManager sharedStylusManager].numberOfStylusTypes;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[WDStylusManager sharedStylusManager] numberOfStylusesForType:(WDStylusType)section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	WDStylusTableCell       *cell = nil;
    NSString                *cellIdentifier = @"detailCellIdentifier";
    UITableViewCellStyle    style = UITableViewCellStyleSubtitle;
    WDStylusData            *data = [[WDStylusManager sharedStylusManager] dataForStylusType:(WDStylusType)indexPath.section
                                                                                     atIndex:indexPath.row];
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[WDStylusTableCell alloc] initWithStyle:style reuseIdentifier:cellIdentifier];
    }
    cell.stylusData = data;

	return cell;
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
