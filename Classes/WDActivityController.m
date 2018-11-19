//
//  WDActivityController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDActivity.h"
#import "WDActivityController.h"
#import "WDActivityManager.h"

@implementation WDActivityController

@synthesize table;
@synthesize activityManager;

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    self.title = NSLocalizedString(@"Activity", @"Activity");
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) done:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) loadView
{
    table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 374) style:UITableViewStylePlain];
    self.view = table;
    
    table.delegate = self;
    table.dataSource = activityManager;
    table.allowsSelection = NO;
    
    if ([self respondsToSelector:@selector(setPreferredContentSize:)])
        self.preferredContentSize = table.frame.size;
    else
        self.contentSizeForViewInPopover = table.frame.size;
    
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(done:)];
        self.navigationItem.rightBarButtonItem = doneItem;
    }
}

- (void) setActivityManager:(WDActivityManager *)am
{
    activityManager = am;
    table.dataSource = am;
    
    // stop observing any previous activity managers that were set
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityAdded:) name:WDActivityAddedNotification object:am];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityRemoved:) name:WDActivityRemovedNotification object:am];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityProgressChanged:) name:WDActivityProgressChangedNotification object:am];
}

- (void) activityAdded:(NSNotification *)aNotification
{
    NSNumber    *index = (aNotification.userInfo)[@"index"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    
    [table beginUpdates];
    [table insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [table endUpdates];
}

- (void) activityRemoved:(NSNotification *)aNotification
{
    NSNumber    *index = (aNotification.userInfo)[@"index"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    
    [table beginUpdates];
    [table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [table endUpdates];
}

- (void) activityProgressChanged:(NSNotification *)aNotification
{
    NSNumber    *index = (aNotification.userInfo)[@"index"];
    WDActivity  *activity = (aNotification.userInfo)[@"activity"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
    
    UITableViewCell *layerCell = (UITableViewCell *) [table cellForRowAtIndexPath:indexPath];
    UIProgressView *progress = (UIProgressView *) [layerCell viewWithTag:2];
    progress.progress = activity.progress;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
