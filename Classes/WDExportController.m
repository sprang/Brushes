//
//  WDExportController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDBrowserController.h"
#import "WDExportController.h"
#import "WDImageButton.h"
#import "WDMatrix.h"
#import "WDUtilities.h"
#import "UIImage+Additions.h"

@interface WDExportController ()

@end

@implementation WDExportController {
    UIBarButtonItem *dropbox_;
    UIBarButtonItem *email_;
}

@synthesize browserController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (!self) {
        return nil;
    }
    
    self.title = NSLocalizedString(@"Export", @"Export");
    
    return self;
}

- (void) cancel:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (WDImageButton *) imageButtonWithImage:(NSString *)image tag:(int)tag
{
    WDImageButton *button = [WDImageButton imageButtonWithImage:[UIImage relevantImageNamed:image]];
    [button addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = tag;
    
    return button;
}

- (NSString *) stringForPreferredFormat
{
    NSUInteger preferredFormat = [[NSUserDefaults standardUserDefaults] integerForKey:@"WDPreferredExportFormat"];
    
    NSArray *formats = @[@"Brushes", @"Photoshop", @"JPEG", @"PNG"];
    return formats[preferredFormat];
}

- (void) email:(id)sender
{
    [self.browserController emailPaintings:[self stringForPreferredFormat]];
}

- (void) sendToDropbox:(id)sender
{
    [self.browserController sendToDropbox:[self stringForPreferredFormat]];
}

- (void) enableToolbarItems
{
    NSUInteger preferredFormat = [[NSUserDefaults standardUserDefaults] integerForKey:@"WDPreferredExportFormat"];
    email_.enabled = preferredFormat == 2 || preferredFormat == 3;
}

- (void) select:(WDImageButton *)sender
{
    WDMatrix *matrix = (WDMatrix *) self.view;
    for (WDImageButton *button in matrix.cellViews) {
        button.marked = NO;
    }
    
    sender.marked = YES;
    
    [[NSUserDefaults standardUserDefaults] setInteger:sender.tag forKey:@"WDPreferredExportFormat"];
    [self enableToolbarItems];
}
                    
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = (WDUseModernAppearance() && !WDDeviceIsPhone()) ? nil : [UIColor colorWithWhite:0.95 alpha:1];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelItem;
    }
    
    // configure the matrix
    WDMatrix *matrix = (WDMatrix *) self.view;
    matrix.rows = 2;
    matrix.columns = 2;
    
    NSMutableArray *buttons = [NSMutableArray array];
    [buttons addObject:[self imageButtonWithImage:@"export_brushes_icon.png" tag:kWDImageFormatBrushes]];
    [buttons addObject:[self imageButtonWithImage:@"export_photoshop_icon.png" tag:kWDImageFormatPhotoshop]];
    [buttons addObject:[self imageButtonWithImage:@"export_jpeg_icon.png" tag:kWDImageFormatJPEG]];
    [buttons addObject:[self imageButtonWithImage:@"export_png_icon.png" tag:kWDImageFormatPNG]];
    matrix.cellViews = buttons;
    
    NSUInteger preferredFormat = [[NSUserDefaults standardUserDefaults] integerForKey:@"WDPreferredExportFormat"];
    for (WDImageButton *button in buttons) {
        if (button.tag == preferredFormat) {
            button.marked = YES;
            break;
        }
    }
    [self toolbarItems];
    [self enableToolbarItems];
    
    if (WDUseModernAppearance()) {
        // we don't want to go under the nav bar and tool bar
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (NSArray *) toolbarItems
{
    if (!email_) {
        email_ = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Email", @"Email")
                                                  style:UIBarButtonItemStyleBordered
                                                 target:self
                                                 action:@selector(email:)];
    }
    
    if (!dropbox_) {
        dropbox_ = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send to Dropbox", @"Send to Dropbox")
                                                    style:UIBarButtonItemStyleBordered
                                                   target:self
                                                   action:@selector(sendToDropbox:)];
    }
    
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil action:nil];
    
    return @[email_, flexible, dropbox_];
}

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.toolbarHidden = NO;
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0.0f];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    WDMatrix *matrix = (WDMatrix *) self.view;
    
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        matrix.columns = 4;
        matrix.rows = 1;
    } else {
        matrix.columns = 2;
        matrix.rows = 2;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
