//
//  WDBrushController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "NSArray+Additions.h"
#import "WDActiveState.h"
#import "WDBar.h"
#import "WDBrush.h"
#import "WDBrushController.h"
#import "WDPropertyCell.h"
#import "WDStampPicker.h"
#import "WDUtilities.h"

@implementation WDBrushController

@synthesize propertyTable;
@synthesize propertyCell;
@synthesize brush;
@synthesize preview;
@synthesize picker;
@synthesize topBar;
@synthesize bottomBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    self.title = NSLocalizedString(@"Brush", @"Brush");
    
    UIBarButtonItem *randomizeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                   target:self
                                                                                   action:@selector(randomize:)];
    self.navigationItem.rightBarButtonItem = randomizeItem;
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) enableRandomizeButton
{
    BOOL canRandomize = self.brush.generator.canRandomize;
    
    randomize_.enabled = canRandomize;
    self.navigationItem.rightBarButtonItem.enabled = canRandomize;
}

- (void) updatePreview
{
    [picker setImage:brush.generator.preview forIndex:picker.selectedIndex];
    preview.image = [brush previewImageWithSize:preview.bounds.size];
}

- (void) brushChanged:(NSNotification *)aNotification
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePreview) object:nil];
    [self performSelector:@selector(updatePreview) withObject:nil afterDelay:0];
    
    [self enableRandomizeButton];
}

- (void) randomize:(id)sender
{
    [brush.generator resetSeed];
}

- (void) brushGeneratorChanged:(NSNotification *)aNotification
{
    [[WDActiveState sharedInstance] setCanonicalGenerator:[aNotification userInfo][@"generator"]];
    [self brushChanged:aNotification];
}

- (void) brushGeneratorReplaced:(NSNotification *)aNotification
{
    preview.image = [brush previewImageWithSize:preview.bounds.size];
    [propertyTable reloadData];
    
    [self enableRandomizeButton];
}

- (void) setBrush:(WDBrush *)inBrush
{
    brush = inBrush;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushChanged:) name:WDBrushPropertyChanged object:brush];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushGeneratorChanged:) name:WDBrushGeneratorChanged object:brush];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brushGeneratorReplaced:) name:WDBrushGeneratorReplaced object:brush];
    
    if (inBrush) {
        [[WDActiveState sharedInstance] setCanonicalGenerator:inBrush.generator];
    }
    
    [picker chooseItemAtIndex:[[WDActiveState sharedInstance] indexForGeneratorClass:[brush.generator class]]];
    
    [self enableRandomizeButton];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) previewDoubleTapped:(id)sender
{
    [brush restoreDefaults];
}

- (void) configurePreview
{
    preview.image = [brush previewImageWithSize:preview.bounds.size];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(previewDoubleTapped:)];
    doubleTap.numberOfTapsRequired = 2;
    
    [preview addGestureRecognizer:doubleTap];
    
    preview.userInteractionEnabled = YES;
}

#pragma mark - Table Delegate/Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
{
    return WDUseModernAppearance() ? 20 : 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return brush.numberOfPropertyGroups;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [brush propertiesForGroupAtIndex:section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"PropertyCell";
    
    WDPropertyCell *cell = (WDPropertyCell *) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        NSString *nibName = WDUseModernAppearance() ? @"PropertyCell~iOS7" : @"PropertyCell";
        [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        cell = propertyCell;
        propertyCell = nil;
    }
    
    cell.property = [brush propertiesForGroupAtIndex:indexPath.section][indexPath.row];
    
    return cell;
}

#pragma mark - View lifecycle

- (void) takeGeneratorFrom:(WDStampPicker *)sender
{
    WDStampGenerator *gen = ([WDActiveState sharedInstance].canonicalGenerators)[sender.selectedIndex];

    brush.generator = [gen copy];
}

- (void) goBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
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
    WDBarItem *backButton = [WDBarItem backButtonWithTitle:NSLocalizedString(@"Brushes", @"Brushes")
                                                    target:self
                                                    action:@selector(goBack:)];

    randomize_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"refresh.png"]
                              landscapeImage:[UIImage imageNamed:@"refreshLandscape.png"]
                                      target:self
                                      action:@selector(randomize:)];
    
    return @[[WDBarItem fixedItemWithWidth:4], backButton, [WDBarItem flexibleItem],
            randomize_];
}

- (NSArray *) bottomBarItems
{
    WDBarItem *dismiss = [WDBarItem barItemWithImage:[UIImage imageNamed:@"dismiss.png"]
                                      landscapeImage:[UIImage imageNamed:@"dismissLandscape.png"]
                                              target:self
                                              action:@selector(done:)];

    return @[[WDBarItem flexibleItem], dismiss];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    propertyTable.rowHeight = WDUseModernAppearance() ? 64 : 60;
    propertyTable.allowsSelection = NO;
    
    if (WDUseModernAppearance()) {
        propertyTable.sectionHeaderHeight = 0;
        propertyTable.sectionFooterHeight = 0;
    }
    
    [propertyTable setBackgroundView:nil];
    [propertyTable setBackgroundView:[[UIView alloc] init]];
    propertyTable.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    [self configurePreview];
    
    NSArray *canon = [WDActiveState sharedInstance].canonicalGenerators;
    NSArray *stamps = [canon map:^id(id obj) {
        return [obj preview];
    }];
    picker.images = stamps;
    
    picker.action = @selector(takeGeneratorFrom:);
    [picker chooseItemAtIndex:[[WDActiveState sharedInstance] indexForGeneratorClass:[brush.generator class]]];
    
    self.preview.contentMode = UIViewContentModeCenter;
    
    self.contentSizeForViewInPopover = self.view.frame.size;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.topBar.ignoreTouches = YES;
        self.topBar.items = [self barItems];
        
        self.bottomBar.items = [self bottomBarItems];
    }
    
    [self enableRandomizeButton];
}

- (void) done:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self configureForOrientation:self.interfaceOrientation];
    }
}

- (void) configureForOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    [self.topBar setOrientation:toInterfaceOrientation];
    [self.bottomBar setOrientation:toInterfaceOrientation];
    
    float barHeight = CGRectGetHeight(bottomBar.frame) - 10;
    propertyTable.contentInset = UIEdgeInsetsMake(0, 0, barHeight, 0);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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
