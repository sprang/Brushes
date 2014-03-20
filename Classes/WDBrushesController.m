//
//  WDBrushesController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDActiveState.h"
#import "WDBar.h"
#import "WDBarSlider.h"
#import "WDBrush.h"
#import "WDBrushController.h"
#import "WDBrushesController.h"
#import "WDBrushCell.h"
#import "UIImage+Additions.h"

#define kRowHeight 100

@interface WDBrushesController ()
- (void) configureNavBar;
- (void) selectActiveBrush;
@end

@implementation WDBrushesController

@synthesize brushTable;
@synthesize brushCell;
@synthesize delegate;
@synthesize topBar;
@synthesize bottomBar;
@synthesize brushSlider;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (!self) {
        return nil;
    }
    
    self.title = NSLocalizedString(@"Brushes", @"Brushes");
    
    [self configureNavBar];
    
    return self;
}

- (void) done:(id)sender
{   
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissViewController:)]) {
        [self.delegate performSelector:@selector(dismissViewController:) withObject:self];
    }
}

- (void) configureNavBar
{
    UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                            target:self
                                                                            action:@selector(deleteBrush:)];
    self.navigationItem.leftBarButtonItem = delete;
    
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                         target:self
                                                                         action:@selector(addBrush:)];
    
    UIBarButtonItem *duplicate = [[UIBarButtonItem alloc] initWithImage:[UIImage relevantImageNamed:@"duplicate.png"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(duplicateBrush:)];
    
    self.navigationItem.rightBarButtonItems = @[add, duplicate];
}

- (void) scrollToSelectedRowIfNotVisible
{
    UITableViewCell *selected = [brushTable cellForRowAtIndexPath:[brushTable indexPathForSelectedRow]];
    
    // if the cell is nil or not completely visible, we should scroll the table
    if (!selected || !CGRectIntersectsRect(selected.frame, brushTable.bounds)) {
        [brushTable scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (void) selectActiveBrush
{
    NSUInteger  activeRow = [[WDActiveState sharedInstance] indexOfActiveBrush];
    
    if ([[brushTable indexPathForSelectedRow] isEqual:[NSIndexPath indexPathForRow:activeRow inSection:0]]) {
        [self scrollToSelectedRowIfNotVisible];
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:activeRow inSection:0];
    // in selectRowAtIndex, "None" means no scrolling; in scrollToNearest, "None" means do minimal scrolling
    [brushTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [brushTable scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone animated:NO];
}

- (void) brushDeleted:(NSNotification *)aNotification
{
    NSNumber *index = [aNotification userInfo][@"index"];
    NSUInteger row = [index integerValue]; // add one to account for the fact that the model already deleted the entry
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    [brushTable beginUpdates];
    [brushTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [brushTable endUpdates];
    
    self.navigationItem.leftBarButtonItem.enabled = [[WDActiveState sharedInstance] canDeleteBrush];
}

- (void) brushAdded:(NSNotification *)aNotification
{    
    NSNumber *index = [aNotification userInfo][@"index"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    
    [brushTable beginUpdates];
    [brushTable insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [brushTable endUpdates];
    
    [self performSelector:@selector(selectActiveBrush) withObject:nil afterDelay:0];
    
    self.navigationItem.leftBarButtonItem.enabled = [[WDActiveState sharedInstance] canDeleteBrush];
}

- (void) deleteBrush:(id)sender
{
    [[WDActiveState sharedInstance] deleteActiveBrush];
}

- (void) addBrush:(id)sender
{
    [[WDActiveState sharedInstance] addBrush:[WDBrush randomBrush]];
}

- (void) duplicateBrush:(id)sender
{
    WDBrush *duplicate = [[WDActiveState sharedInstance].brush copy];

    [[WDActiveState sharedInstance] addBrush:duplicate];
    
}

#pragma mark - Table Delegate/Data Source

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [WDActiveState sharedInstance].brushesCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"BrushCell";
    WDBrush *brush = [[WDActiveState sharedInstance] brushAtIndex:indexPath.row];
    
    WDBrushCell *cell = (WDBrushCell *) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"BrushCell" owner:self options:nil];
        cell = brushCell;
        brushCell = nil;
    }
    
    cell.brush = brush;
    cell.table = brushTable;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath
{    
    [[WDActiveState sharedInstance] selectBrushAtIndex:newIndexPath.row];
}

- (void) brushChanged:(NSNotification *)aNotification
{
    [self selectActiveBrush];
    brushSlider.value = [WDActiveState sharedInstance].brush.weight.value;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [[WDActiveState sharedInstance] selectBrushAtIndex:indexPath.row];
    
    WDBrushController *brushController = [[WDBrushController alloc] initWithNibName:@"Brush" bundle:nil];
    brushController.brush = [[WDActiveState sharedInstance] brushAtIndex:indexPath.row];
    
    [self.navigationController pushViewController:brushController animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {    
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSUInteger srcIndex = sourceIndexPath.row;
    NSUInteger destIndex = destinationIndexPath.row;
    
    [[WDActiveState sharedInstance] moveBrushAtIndex:srcIndex toIndex:destIndex];
}

#pragma mark - View lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.navigationController setNavigationBarHidden:YES];
        [self configureForOrientation:self.interfaceOrientation];
    }
    
    [self selectActiveBrush];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[WDActiveState sharedInstance] saveBrushes];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushChanged:) name:WDActiveBrushDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushAdded:) name:WDBrushAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushDeleted:) name:WDBrushDeletedNotification object:nil];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) doubleTapped:(id)sender
{
    [self done:sender];
}

- (WDBar *) topBar
{
    if (!topBar) {
        WDBar *aBar = [WDBar topBar];
        CGRect frame = aBar.frame;
        frame.size.width = CGRectGetWidth(self.view.bounds);
        aBar.frame = frame;
        
        [self.view addSubview:aBar];
        self.topBar = aBar;
    }
    
    return topBar;
}

- (WDBar *) bottomBar
{
    if (!bottomBar) {
        WDBar *aBar = [WDBar bottomBar];
        CGRect frame = aBar.frame;
        frame.origin.y  = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(aBar.frame);
        frame.size.width = CGRectGetWidth(self.view.bounds);
        aBar.frame = frame;
        
        [self.view addSubview:aBar];
        self.bottomBar = aBar;
    }
    
    return bottomBar;
}

- (NSArray *) barItems
{
    WDBarItem *delete = [WDBarItem barItemWithImage:[UIImage imageNamed:@"trash.png"] target:self action:@selector(deleteBrush:)];
    WDBarItem *add = [WDBarItem barItemWithImage:[UIImage imageNamed:@"add.png"] target:self action:@selector(addBrush:)];
    WDBarItem *duplicate = [WDBarItem barItemWithImage:[UIImage imageNamed:@"duplicate.png"] target:self action:@selector(duplicateBrush:)];
    
    return @[delete, [WDBarItem flexibleItem], duplicate, add];
}

- (void) decrementBrushSize:(id)sender
{
    [[WDActiveState sharedInstance].brush.weight decrement];
    brushSlider.value = [WDActiveState sharedInstance].brush.weight.value;
}

- (void) incrementBrushSize:(id)sender
{
    [[WDActiveState sharedInstance].brush.weight increment];
    brushSlider.value = [WDActiveState sharedInstance].brush.weight.value;
}

- (void) takeBrushSizeFrom:(WDBarSlider *)sender
{
    [WDActiveState sharedInstance].brush.weight.value = sender.value;
}

- (NSArray *) bottomBarItems
{
    WDBarItem *dismiss = [WDBarItem barItemWithImage:[UIImage imageNamed:@"dismiss.png"]
                                      landscapeImage:[UIImage imageNamed:@"dismissLandscape.png"]
                                              target:self
                                              action:@selector(done:)];
    
    WDBarItem *minusItem = [WDBarItem barItemWithImage:[UIImage imageNamed:@"bar_minus.png"]
                                                target:self
                                                action:@selector(decrementBrushSize:)];
    minusItem.width = 32;
    
    WDBarItem *plusItem = [WDBarItem barItemWithImage:[UIImage imageNamed:@"bar_plus.png"]
                                               target:self
                                               action:@selector(incrementBrushSize:)];
    plusItem.width = 32;
    
    brushSlider = [[WDBarSlider alloc] initWithFrame:CGRectMake(0, 0, 255, 44)];
    brushSlider.parentViewForOverlay = self.view;
    WDBarItem *brushSizeItem = [WDBarItem barItemWithView:brushSlider];
    brushSizeItem.flexibleContent = YES;
    brushSlider.value = [WDActiveState sharedInstance].brush.weight.value;
    [brushSlider addTarget:self action:@selector(takeBrushSizeFrom:) forControlEvents:UIControlEventValueChanged];
    
    return @[minusItem, brushSizeItem, plusItem, [WDBarItem flexibleItem], dismiss];
}

- (void)viewDidLoad
{
    [super viewDidLoad];    
 
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];;
    
    brushTable.rowHeight = kRowHeight;
    brushTable.backgroundColor = nil;
    brushTable.editing = YES;
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] init];
    doubleTap.numberOfTapsRequired = 2;
    [doubleTap addTarget:self action:@selector(done:)];
    [brushTable addGestureRecognizer:doubleTap];
    
    self.contentSizeForViewInPopover = self.view.frame.size;

    self.navigationItem.leftBarButtonItem.enabled = [[WDActiveState sharedInstance] canDeleteBrush];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.topBar addEdge];
        self.topBar.ignoreTouches = NO;
        self.topBar.items = [self barItems];
        [self.topBar setTitle:NSLocalizedString(@"Brushes", @"Brushes")];
        
        [self.bottomBar addEdge];
        self.bottomBar.ignoreTouches = NO;
        self.bottomBar.items = [self bottomBarItems];
    }
    
    [self brushChanged:nil];
}

- (void) viewDidUnload
{
    [super viewDidUnload];
    
    bottomBar = nil;
    topBar = nil;
}

- (void) configureForOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    [self.topBar setOrientation:toInterfaceOrientation];
    [self.bottomBar setOrientation:toInterfaceOrientation];
    
    float barHeight = CGRectGetHeight(topBar.frame);
    brushTable.contentInset = UIEdgeInsetsMake(barHeight, 0, barHeight, 0);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self configureForOrientation:toInterfaceOrientation];
}

- (UIView *) rotatingHeaderView
{
    return self.topBar;
}

- (UIView *) rotatingFooterView
{
    return self.bottomBar;
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
