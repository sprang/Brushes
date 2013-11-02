//
//  WDCanvasController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import <Twitter/Twitter.h>
#import <MessageUI/MessageUI.h>

#import "UIImage+Resize.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "WDActiveState.h"
#import "WDBar.h"
#import "WDBarSlider.h"
#import "WDBezierNode.h"
#import "WDBrush.h"
#import "WDBrushesController.h"
#import "WDCanvas.h"
#import "WDCanvasController.h"
#import "WDCodingProgress.h"
#import "WDColor.h"
#import "WDColorBalanceController.h"
#import "WDColorPickerController.h"
#import "WDColorWell.h"
#import "WDDocument.h"
#import "WDFillColor.h"
#import "WDHueSaturationController.h"
#import "WDLayer.h"
#import "WDLayerController.h"
#import "WDMenu.h"
#import "WDMenuItem.h"
#import "WDModifyLayer.h"
#import "WDPaintingManager.h"
#import "WDProgressView.h"
#import "WDRedoChange.h"
#import "WDStylusManager.h"
#import "WDStylusController.h"
#import "WDToolButton.h"
#import "WDUndoChange.h"
#import "WDUtilities.h"
#import "WDUnlockView.h"

#define RESCALE_REPLAY          0
#define kNavBarFixedWidth       20

@implementation WDCanvasController

@synthesize document = document_;
@synthesize canvas = canvas_;
@synthesize colorPickerController = colorPickerController_;
@synthesize brushController = brushController_;
@synthesize shareSheet;
@synthesize gearSheet;
@synthesize hasAppearedBefore;
@synthesize needsToResetInterfaceMode;
@synthesize canvasSettings;
@synthesize replay;
@synthesize topBar;
@synthesize bottomBar;
@synthesize unlockView;
@synthesize playButton;
@synthesize editingTopBarItems;
@synthesize interfaceMode;
@synthesize progressIndicator;
@synthesize actionNameView;
@synthesize replayScale;
@synthesize wasPlayingBeforeRotation;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    [self setWantsFullScreenLayout:YES];
    
    return self;
}

- (WDPainting *) painting
{
    return self.document.painting;
}

- (BOOL) runningOnPhone
{
    static BOOL isPhone;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? YES : NO;
    });
    
    return isPhone;
}

#pragma mark -
#pragma mark Interface Rotation

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    wasPlayingBeforeRotation = (replay && replay.isPlaying);
    if (wasPlayingBeforeRotation) {
        [replay pause];
    }
    
    canvas_.autoresizingMask = UIViewAutoresizingNone;
}

- (void) configureForOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    [self.topBar setOrientation:toInterfaceOrientation];
    [self.bottomBar setOrientation:toInterfaceOrientation];
    
    [layer_ setImage:[self layerImage]];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self hidePopovers];

    // temporarily square the canvas so that it looks good during rotation
    float maxDimension = MAX(canvas_.frame.size.width, canvas_.frame.size.height);
    CGRect frame = CGRectMake(0, 0, maxDimension, maxDimension);
    canvas_.frame = frame;
    canvas_.sharpCenter = WDCenterOfRect(canvas_.superview.bounds);
    
    [canvas_ nixMessageLabel];
    
    [balanceController_ bringOnScreenAnimated:YES];
    [hueController_ bringOnScreenAnimated:YES];
    
    if ([self runningOnPhone]) {
        [self configureForOrientation:toInterfaceOrientation];
    }
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // restore the proper canvas frame
    canvas_.frame = canvas_.superview.bounds;
    canvas_.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (wasPlayingBeforeRotation) {
        [replay play];
    }
}

#pragma mark -
#pragma mark Show Controllers

- (void) showBlueToothPanel:(id)sender
{
    if ([self shouldDismissPopoverForClassController:[WDStylusController class] insideNavController:YES]) {
        [self hidePopovers];
        return;
    }
    
    WDStylusController *stylusController = [[WDStylusController alloc] initWithNibName:@"Stylus" bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:stylusController];
    
    [self showController:navController fromBarButtonItem:sender animated:YES];
}

- (BOOL) shouldDismissPopoverForClassController:(Class)controllerClass insideNavController:(BOOL)insideNav
{
    if (!popoverController_) {
        return NO;
    }
    
    if (insideNav && [popoverController_.contentViewController isKindOfClass:[UINavigationController class]]) {
        NSArray *viewControllers = [(UINavigationController *)popoverController_.contentViewController viewControllers];
        
        for (UIViewController *viewController in viewControllers) {
            if ([viewController isKindOfClass:controllerClass]) {
                return YES;
            }
        }
    } else if ([popoverController_.contentViewController isKindOfClass:controllerClass]) {
        return YES;
    }
    
    return NO;
}

- (void) showPhotoBrowser:(id)sender
{
    if ([self shouldDismissPopoverForClassController:[UIImagePickerController class] insideNavController:NO]) {
        [self hidePopovers];
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    
    [self showController:picker fromBarButtonItem:sender animated:YES];
}

#pragma mark -
#pragma mark Image Placement

- (void) dismissImagePicker:(UIImagePickerController *)picker
{
    if (self.runningOnPhone) {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } else {
        [popoverController_ dismissPopoverAnimated:YES];
        popoverController_ = nil;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [self dismissImagePicker:picker];
    
    CGSize imageSize = image.size;
    if (imageSize.width > imageSize.height) {
        if (imageSize.width > 2048) {
            imageSize.height = (imageSize.height / imageSize.width) * 2048;
            imageSize.width = 2048;
        }
    } else {
        if (imageSize.height > 2048) {
            imageSize.width = (imageSize.width / imageSize.height) * 2048;
            imageSize.height = 2048;
        }
    }
    
    image = [image resizedImage:imageSize interpolationQuality:kCGInterpolationHigh];
    [canvas_ beginPhotoPlacement:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissImagePicker:picker];
}

#pragma mark -
#pragma mark Actions

- (void) duplicateLayer:(id)sender
{
    [self.painting duplicateActiveLayer];
}

- (void) transformLayer:(id)sender
{
    [canvas_ beginLayerTransformation];
}

- (void) clearLayer:(id)sender
{
    changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDClearLayer]);
}

- (void) fillLayer:(id)sender
{
    changeDocument(self.painting, [WDFillColor fillColor:[WDActiveState sharedInstance].paintColor inLayer:self.painting.activeLayer]);
}

- (void) desaturateLayer:(id)sender
{
    changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDDesaturateLayer]);
}

- (void) invertLayer:(id)sender
{
    changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDInvertLayerColor]);
}

- (void) flipHorizontally:(id)sender
{
    changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDFlipLayerHorizontal]);
}

- (void) flipVertically:(id)sender
{
    changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDFlipLayerVertical]);
}

#pragma mark - Sheets

- (void) actionSheetDismissed:(WDActionSheet *)actionSheet
{
    if (actionSheet == gearSheet) {
        self.gearSheet = nil;
    } else if (actionSheet == shareSheet) {
        self.shareSheet = nil;
    }
}

- (void) showActionSheet:(id)sender
{
    self.shareSheet = [WDActionSheet sheet];
    
    __unsafe_unretained WDCanvasController *canvasController = self;
    
    [shareSheet addButtonWithTitle:NSLocalizedString(@"Add to Photos", @"Add to Photos")
                            action:^(id sender) { [canvasController addToPhotoAlbum:sender]; }];
     
    [shareSheet addButtonWithTitle:NSLocalizedString(@"Copy to Pasteboard", @"Copy to Pasteboard")
                             action:^(id sender) { [canvasController copyPainting:sender]; }];
    
    if (self.document) {
        [shareSheet addButtonWithTitle:NSLocalizedString(@"Duplicate", @"Duplicate")
                                action:^(id sender) { [canvasController duplicatePainting:sender]; }];
    }
    
    if (NSClassFromString(@"SLComposeViewController")) { // if we can facebook
        [shareSheet addButtonWithTitle:NSLocalizedString(@"Post on Facebook", @"Post on Facebook")
                                action:^(id sender) { [canvasController postOnFacebook:sender]; }];
    }
    
    // could check this with [TWTweetComposeViewController canSendTweet], but the behavior seems okay without the check
    [shareSheet addButtonWithTitle:NSLocalizedString(@"Tweet", @"Tweet")
                             action:^(id sender) { [canvasController tweetPainting:sender]; }];
    
    if (self.document && [MFMailComposeViewController canSendMail]) {
        [shareSheet addButtonWithTitle:NSLocalizedString(@"Email", @"Email")
                                 action:^(id sender) { [canvasController emailPNG:sender]; }];
    }
    
    [shareSheet addCancelButton];
    
    shareSheet.delegate = self;
    [shareSheet.sheet showInView:self.view];
}

- (void) showGearSheet:(id)sender
{
    self.gearSheet = [WDActionSheet sheet];
    
    __unsafe_unretained WDCanvasController *canvasController = self;
    
    if (self.painting.canAddLayer) {
        [gearSheet addButtonWithTitle:NSLocalizedString(@"Place Photo", @"Place Photo")
                               action:^(id sender) { [canvasController showPhotoBrowser:sender]; }];
        
        if ([self canPasteImage]) {
            [gearSheet addButtonWithTitle:NSLocalizedString(@"Paste Image", @"Paste Image")
                                    action:^(id sender) { [canvasController pasteImage:sender]; }];
        }
    }
    
    if (self.painting.activeLayer.editable) {
        [gearSheet addButtonWithTitle:NSLocalizedString(@"Clear Layer", @"Clear Layer")
                               action:^(id sender) { [canvasController clearLayer:sender]; }];
        
        [gearSheet addButtonWithTitle:NSLocalizedString(@"Fill Layer", @"Fill Layer")
                               action:^(id sender) { [canvasController fillLayer:sender]; }];
        
        [gearSheet addButtonWithTitle:NSLocalizedString(@"Desaturate", @"Desaturate")
                               action:^(id sender) { [canvasController desaturateLayer:sender]; }];
        
        [gearSheet addButtonWithTitle:NSLocalizedString(@"Invert Color", @"Invert Color")
                               action:^(id sender) { [canvasController invertLayer:sender]; }];
        
        [gearSheet addButtonWithTitle:NSLocalizedString(@"Transform Layer", @"Transform Layer")
                          action:^(id sender) { [canvasController transformLayer:sender]; }];
    }
    
    [gearSheet addCancelButton];
    
    gearSheet.delegate = self;
    [gearSheet.sheet showInView:self.view];
}

#pragma mark -
#pragma mark Menus

- (void) showActionMenu:(id)sender
{
    if (popoverController_ && (popoverController_.contentViewController.view == actionMenu_)) {
        [self hidePopovers];
        return;
    }
    
    if (!actionMenu_) {
        NSMutableArray  *menus = [NSMutableArray array];
        WDMenuItem      *item;
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Add to Photos", @"Add to Photos")
                                  action:@selector(addToPhotoAlbum:) target:self];
        [menus addObject:item];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Copy to Pasteboard", @"Copy to Pasteboard")
                                  action:@selector(copyPainting:) target:self];
        [menus addObject:item];
        
        [menus addObject:[WDMenuItem separatorItem]];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Duplicate", @"Duplicate")
                                  action:@selector(duplicatePainting:) target:self];
        [menus addObject:item];
        
        [menus addObject:[WDMenuItem separatorItem]];
        
        if (NSClassFromString(@"SLComposeViewController")) {
            item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Post on Facebook", @"Post on Facebook")
                                      action:@selector(postOnFacebook:) target:self];
            [menus addObject:item];
        }
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Tweet", @"Tweet")
                                  action:@selector(tweetPainting:) target:self];
        [menus addObject:item];
        
        [menus addObject:[WDMenuItem separatorItem]];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Email JPEG", @"Email JPEG")
                                  action:@selector(emailJPEG:) target:self];
        [menus addObject:item];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Email PNG", @"Email PNG")
                                  action:@selector(emailPNG:) target:self];
        [menus addObject:item];
        
        actionMenu_ = [[WDMenu alloc] initWithItems:menus];
        actionMenu_.delegate = self;
    }
    
    UIViewController *controller = [[UIViewController alloc] init];
    controller.view = actionMenu_;
    controller.contentSizeForViewInPopover = actionMenu_.frame.size;
    
    visibleMenu_ = actionMenu_;
    [self validateVisibleMenuItems];
    
    actionMenu_.popover = [self runPopoverWithController:controller from:sender];
}

- (void) showGearMenu:(id)sender
{
    if (popoverController_ && (popoverController_.contentViewController.view == gearMenu_)) {
        [self hidePopovers];
        return;
    }
    
    if (!gearMenu_) {
        NSMutableArray  *menus = [NSMutableArray array];
        WDMenuItem      *item;
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Clear Layer", @"Clear Layer")
                                  action:@selector(clearLayer:) target:self];
        [menus addObject:item];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Fill Layer", @"Fill Layer")
                                  action:@selector(fillLayer:) target:self];
        [menus addObject:item];
        
        [menus addObject:[WDMenuItem separatorItem]];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Desaturate", @"Desaturate") action:@selector(desaturateLayer:) target:self];
        [menus addObject:item];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Invert Color", @"Invert Color")
                                  action:@selector(invertLayer:) target:self];
        [menus addObject:item];
        
        [menus addObject:[WDMenuItem separatorItem]];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Color Balance…", @"Color Balance…")
                                  action:@selector(showColorBalance:) target:self];
        [menus addObject:item];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Hue and Saturation…", @"Hue and Saturation…")
                                  action:@selector(showHueAndSaturation:) target:self];
        [menus addObject:item];
        
        [menus addObject:[WDMenuItem separatorItem]];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Flip Horizontally", @"Flip Horizontally")
                                  action:@selector(flipHorizontally:) target:self];
        [menus addObject:item];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Flip Vertically", @"Flip Vertically")
                                  action:@selector(flipVertically:) target:self];
        [menus addObject:item];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Transform", @"Transform")
                                  action:@selector(transformLayer:) target:self];
        [menus addObject:item];
        
        [menus addObject:[WDMenuItem separatorItem]];
        
        item = [WDMenuItem itemWithTitle:NSLocalizedString(@"Paste Image", @"Paste Image")
                                  action:@selector(pasteImage:) target:self];
        [menus addObject:item];
        
        gearMenu_ = [[WDMenu alloc] initWithItems:menus];
        gearMenu_.delegate = self;
    }
    
    UIViewController *controller = [[UIViewController alloc] init];
    controller.view = gearMenu_;
    controller.contentSizeForViewInPopover = gearMenu_.frame.size;
    
    visibleMenu_ = gearMenu_;
    [self validateVisibleMenuItems];
    
    gearMenu_.popover = [self runPopoverWithController:controller from:sender];
}

- (void) postOnFacebook:(id)sender
{
    SLComposeViewController *facebookSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    [facebookSheet addImage:[canvas_.painting imageForCurrentState]];
    [facebookSheet setInitialText:NSLocalizedString(@"Check out my Brushes painting! http://brushesapp.com",
                                                    @"Check out my Brushes painting! http://brushesapp.com")];
    
    [self presentModalViewController:facebookSheet animated:YES];
}

- (void) tweetPainting:(id)sender
{
    TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
    
    [tweetSheet addImage:[canvas_.painting imageForCurrentState]];
    [tweetSheet setInitialText:NSLocalizedString(@"Check out my Brushes #painting! @brushesapp",
                                                 @"Check out my Brushes #painting! @brushesapp")];
    
    [self presentModalViewController:tweetSheet animated:YES];
}

- (void) validateMenuItem:(WDMenuItem *)item
{
    // ACTION
    if (item.action == @selector(emailPNG:) ||
        item.action == @selector(emailJPEG:))
    {
        item.enabled = [MFMailComposeViewController canSendMail];
    }
    else if (item.action == @selector(duplicatePainting:))
             {
        item.enabled = (self.document != nil);
    }
    
    // LAYER
    else if (item.action == @selector(pasteImage:)) {
        item.enabled = [self canPasteImage];
    }
    else if (item.action == @selector(duplicateLayer:)) {
        item.enabled = [self.painting canAddLayer];
    }
    else if (item.action == @selector(clearLayer:) ||
             item.action == @selector(fillLayer:) ||
             item.action == @selector(invertLayer:) ||
             item.action == @selector(desaturateLayer:) ||
             item.action == @selector(flipHorizontally:) ||
             item.action == @selector(flipVertically:) ||
             item.action == @selector(transformLayer:) ||
             item.action == @selector(showHueAndSaturation:) ||
             item.action == @selector(showColorBalance:)) 
    {
        WDLayer *activeLayer = self.painting.activeLayer;
        item.enabled = !(activeLayer.locked || !activeLayer.visible);
    }
    
    // GENERIC CASE
    else {
        item.enabled = [self respondsToSelector:item.action];
    }
}

- (void) validateVisibleMenuItems
{
    if (!visibleMenu_) {
        return;
    }
    
    for (WDMenuItem *item in visibleMenu_.items) {
        [self validateMenuItem:item];
    }
}

#pragma mark -
#pragma mark Inspectors

- (void) showBrushPanel:(id)sender
{
    if ([self shouldDismissPopoverForClassController:[WDBrushesController class] insideNavController:YES]) {
        [self hidePopovers];
        return;
    }
    
    if (!self.brushController) {
        WDBrushesController *brushController = [[WDBrushesController alloc] initWithNibName:@"Brushes" bundle:nil];
        brushController.delegate = self;

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:brushController];
        self.brushController = navController;
    }
    
    [self showController:self.brushController fromBarButtonItem:sender animated:YES];
}

- (void) showColorPicker:(id)sender
{
    if ([self shouldDismissPopoverForClassController:[WDColorPickerController class] insideNavController:NO]) {
        [self hidePopovers];
        return;
    }

    if (!self.colorPickerController) {
        if (WDDeviceIs4InchPhone()) {
            self.colorPickerController = [[WDColorPickerController alloc] initWithNibName:@"ColorPicker~iphone5" bundle:nil];
        } else {
            self.colorPickerController = [[WDColorPickerController alloc] initWithNibName:@"ColorPicker" bundle:nil];
        }
        
        self.colorPickerController.delegate = self;
    }
    
    [self.colorPickerController setInitialColor:[WDActiveState sharedInstance].paintColor];
    
    if ([self runningOnPhone]) {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.colorPickerController];
        [self showController:navController fromBarButtonItem:sender animated:NO];
    } else {
        [self showController:self.colorPickerController fromBarButtonItem:sender animated:NO];
    }
}

- (void) dismissViewController:(UIViewController *)viewController
{
    if (popoverController_) {
        [self hidePopovers];
    } else {
        [viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) showLayers:(id)sender
{
    if ([self shouldDismissPopoverForClassController:[WDLayerController class] insideNavController:YES]) {
        [self hidePopovers];
        return;
    }
    
    if (!layerController_) {
        layerController_ = [[WDLayerController alloc] initWithNibName:@"Layers" bundle:nil];
        layerController_.painting = self.painting;
        layerController_.delegate = self;
    }
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:layerController_];
    [self showController:navController fromBarButtonItem:sender animated:YES];  
}

- (void) showHueAndSaturation:(id)sender
{
    if (!hueController_) {
        hueController_ = [[WDHueSaturationController alloc] initWithNibName:@"HueSaturation" bundle:nil];
        hueController_.painting = self.painting;
    }
    
    [hueController_ runModalOverView:canvas_];
}

- (void) showColorBalance:(id)sender
{
    if (!balanceController_) {
        balanceController_ = [[WDColorBalanceController alloc] initWithNibName:@"ColorBalance" bundle:nil];
        balanceController_.painting = self.painting;
    }
    
    [balanceController_ runModalOverView:canvas_];
}

#pragma mark -
#pragma mark Popover Management

- (void) showController:(UIViewController *)controller fromBarButtonItem:(UIBarButtonItem *)barButton animated:(BOOL)animated
{
    if (self.runningOnPhone) {
        [self presentViewController:controller animated:animated completion:nil];
    } else {
        [self runPopoverWithController:controller from:barButton];
    }
}

- (UIPopoverController *) runPopoverWithController:(UIViewController *)controller from:(id)sender
{
    [self hidePopovers];
    
    popoverController_ = [[UIPopoverController alloc] initWithContentViewController:controller];
	popoverController_.delegate = self;
    
    NSMutableArray *passthroughs = [NSMutableArray arrayWithObjects:self.topBar, self.bottomBar, nil];
    if (self.isEditing) {
        [passthroughs addObject:self.canvas];
    }
    popoverController_.passthroughViews = passthroughs;
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        [popoverController_ presentPopoverFromBarButtonItem:sender
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:YES];
    } else {
        [popoverController_ presentPopoverFromRect:CGRectInset(((UIView *) sender).bounds, 10, 10)
                                            inView:sender
                          permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown)
                                          animated:YES];
    }
    
    return popoverController_;
}

- (BOOL) popoverVisible
{
    return popoverController_ ? YES : NO;
}

- (void) hidePopovers
{
    if (popoverController_) {
        [popoverController_ dismissPopoverAnimated:NO];
        popoverController_ = nil;
        
        visibleMenu_ = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == popoverController_) {
        popoverController_ = nil;
        
        visibleMenu_ = nil;
    }
}

- (void) blueToothStatusChanged:(NSNotification *)aNotification
{
    if (self.interfaceMode == WDInterfaceModeEdit) {
        // need to reload these
        editingTopBarItems = nil;
        [self.topBar setItems:[self editingTopBarItems] animated:YES];
    }
    
    [[WDStylusManager sharedStylusManager].pogoManager registerView:canvas_];
}

- (void) stylusConnected:(NSNotification *)aNotification
{
    [self.actionNameView setConnectedDeviceName:(aNotification.userInfo)[@"name"]];
}

- (void) stylusDisconnected:(NSNotification *)aNotification
{
    [self.actionNameView setDisconnectedDeviceName:(aNotification.userInfo)[@"name"]];
}

#pragma mark - Undo/Redo

- (void) primaryStylusButtonPressed:(NSNotification *)aNotification
{
    if (!canvas_.currentlyPainting) {
        [self undo:nil];
    }
}

- (void) secondaryStylusButtonPressed:(NSNotification *)aNotification
{
    if (!canvas_.currentlyPainting) {
        [self redo:nil];
    }
}

- (void) undo:(id)sender
{
    if ([self.painting.undoManager canUndo]) {
        changeDocument(self.painting, [WDUndoChange undoChange]);
    }
}

- (void) redo:(id)sender
{
    if ([self.painting.undoManager canRedo]) {
        changeDocument(self.painting, [WDRedoChange redoChange]);
    }
}

#pragma mark -
#pragma mark Toolbar Stuff

- (void) enableItems
{
    album_.enabled = self.isEditing && self.painting.canAddLayer;
    
    if (self.runningOnPhone) {
        gear_.enabled = (self.painting.canAddLayer || self.painting.activeLayer.editable);
    }
}

- (BOOL) phoneLandscapeMode
{
    if ([self runningOnPhone]) {
        return UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    }
    
    return NO;
}

- (UIImage *) layerImage
{
    CGContextRef    ctx;
    UIBezierPath    *path;
    CGRect          layerBox;
    
    if ([self phoneLandscapeMode]) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(23,23), NO, 0.0f);
        ctx = UIGraphicsGetCurrentContext();
        
        // draw background outline
        [[UIColor whiteColor] set];
        layerBox = CGRectMake(3, 3, 19, 19);
        path = [UIBezierPath bezierPathWithRoundedRect:layerBox cornerRadius:3];
    } else {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(25,30), NO, 0.0f);
        ctx = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(ctx, 0, -2);
        
        // draw background outline
        [[UIColor whiteColor] set];
        layerBox = CGRectMake(0, 5, 19, 19);
        path = [UIBezierPath bezierPathWithRoundedRect:CGRectOffset(layerBox, 1, 1) cornerRadius:3];
        path.lineWidth = 2;
        [path stroke];

        // punch out a hole
        layerBox = CGRectOffset(layerBox, 5, 5);
        path = [UIBezierPath bezierPathWithRoundedRect:layerBox cornerRadius:3];
        CGContextSetBlendMode(ctx, kCGBlendModeClear);
        [path fill];
        path.lineWidth = 5;
        [path stroke];
    }
    
    // fill the foreground lightly
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    [[UIColor colorWithWhite:1.0 alpha:0.1f] set];
    [path fill];
    
    // stroke the foreground
    [[UIColor whiteColor] set];
    path.lineWidth = 2;
    [path stroke];
    
    // draw the layer number
    if (self.painting) {
        NSUInteger index = [self.painting indexOfActiveLayer];
        index = (index == NSNotFound) ? 1 : (index + 1);
        
        NSString *label = [NSString stringWithFormat:@"%lu", (unsigned long)index];
        
        [label drawInRect:CGRectOffset(layerBox, 0, 1)
                 withFont:[UIFont boldSystemFontOfSize:13]
            lineBreakMode:UILineBreakModeClip
                alignment:UITextAlignmentCenter];
    }

    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (void) setTitle:(NSString *)title
{
    [super setTitle:title];
    
    if (!(self.isEditing && self.runningOnPhone)) {
        self.topBar.title = title;
    }
}

- (void) goBack:(id)sender
{
    [[WDActiveState sharedInstance] resetActiveTool];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (self.isEditing) {
        if (!self.document && self.replay) {
            [self setUserInteractionEnabled:NO];
            WDDocument *document = [[WDPaintingManager sharedInstance] paintingWithName:self.replay.paintingName];
            self.document = document;
            [self.progressIndicator resetProgress];
            [self setInterfaceMode:WDInterfaceModeLoading];
            
            // save off the scale so we can correct for it later
            self.replayScale = @(replay.scale);
            
            [document openWithCompletionHandler:^(BOOL success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setInterfaceMode:WDInterfaceModeEdit];
                    [self setUserInteractionEnabled:YES];
                });
            }];
            self.replay = nil;
        } else if (!self.document) {
            [NSException raise:@"No replay or document" format:@"Either replay or document should not be nil"];
        } else {
            [self setInterfaceMode:WDInterfaceModeEdit];
            [self enableItems];
        }
    } else {
        [self setInterfaceMode:WDInterfaceModePlay];
    }
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

- (void) chooseTool:(id)sender
{
    [WDActiveState sharedInstance].activeTool = ((WDToolButton *)sender).tool;
}

- (void) addToolButtons:(NSArray *)inTools toArray:(NSMutableArray *)items
{
    // build tool buttons
    CGRect buttonRect = CGRectMake(0, 0, 36, 36);
    
    for (id tool in inTools) {
        WDToolButton *button = [WDToolButton buttonWithType:UIButtonTypeCustom];
        
        button.frame = buttonRect;
        [button addTarget:self action:@selector(chooseTool:) forControlEvents:UIControlEventTouchUpInside];
        button.adjustsImageWhenHighlighted = NO;
        
        button.tool = tool;
        if (tool == [WDActiveState sharedInstance].activeTool) {
            button.selected = YES;
        }
        
        WDBarItem *item = [WDBarItem barItemWithView:button];
        [items addObject:item];
    }
}

- (NSArray *) editingTopBarItems
{
    if (!editingTopBarItems) {
        WDBarItem *fixed = [WDBarItem fixedItemWithWidth:5];
        WDBarItem *backButton = [WDBarItem backButtonWithTitle:NSLocalizedString(@"Gallery", @"Gallery") target:self action:@selector(goBack:)];
        WDBarItem *action = [WDBarItem barItemWithImage:[UIImage relevantImageNamed:@"action.png"]
                                         landscapeImage:[UIImage relevantImageNamed:@"actionLandscape.png"]
                                                 target:self
                                                 action:self.runningOnPhone ? @selector(showActionSheet:) : @selector(showActionMenu:)];
        WDBarItem *bluetooth = [WDBarItem barItemWithImage:[UIImage imageNamed:@"BlueTooth.png"]
                                            landscapeImage:[UIImage imageNamed:@"BlueToothLandscape.png"]
                                                    target:self
                                                    action:@selector(showBlueToothPanel:)];
        
        NSMutableArray *items = [NSMutableArray arrayWithObjects:fixed, backButton, [WDBarItem flexibleItem], nil];
        
        if (self.runningOnPhone) {
            [self addToolButtons:[WDActiveState sharedInstance].tools toArray:items];
            
            if ([WDStylusManager sharedStylusManager].isBlueToothEnabled) {
                [items addObject:fixed];
                [items addObject:bluetooth];
                [items addObject:fixed];
            } else {
                [items addObject:[WDBarItem fixedItemWithWidth:15]];
            }
        } else {
            if ([WDStylusManager sharedStylusManager].isBlueToothEnabled) {
                [items addObject:bluetooth];
                [items addObject:fixed];
            }
            
            album_ = [WDBarItem barItemWithImage:[UIImage relevantImageNamed:@"album.png"]
                                          target:self
                                          action:@selector(showPhotoBrowser:)];
            
            [items addObject:album_];
            [items addObject:fixed];
        }
        
        [items addObject:action];
        
        editingTopBarItems = items;
    }
    
    [self enableItems];
    
    return editingTopBarItems;
}

- (NSArray *) replayTopBarItems
{
    WDBarItem *fixed = [WDBarItem fixedItemWithWidth:5];
    WDBarItem *backButton = [WDBarItem backButtonWithTitle:NSLocalizedString(@"Gallery", @"Gallery") target:self action:@selector(goBack:)];
    WDBarItem *action = [WDBarItem barItemWithImage:[UIImage relevantImageNamed:@"action.png"]
                                     landscapeImage:[UIImage relevantImageNamed:@"actionLandscape.png"]
                                             target:self
                                             action:self.runningOnPhone ? @selector(showActionSheet:) : @selector(showActionMenu:)];
    
    return @[fixed, backButton, [WDBarItem flexibleItem], action];
}

- (NSArray *) loadingTopBarItems
{
    WDBarItem *action = [WDBarItem barItemWithImage:[UIImage relevantImageNamed:@"action.png"]
                                     landscapeImage:[UIImage relevantImageNamed:@"actionLandscape.png"]
                                             target:nil
                                             action:nil];
    action.enabled = NO;
    
    WDBarItem *backButton = [WDBarItem backButtonWithTitle:NSLocalizedString(@"Gallery", @"Gallery") target:self action:@selector(goBack:)];
    
    return @[[WDBarItem fixedItemWithWidth:5], backButton, [WDBarItem flexibleItem], action];
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
        
        bottomBar.defaultFlexibleSpacing = 32;
        self.bottomBar.ignoreTouches = NO;
    }
    
    return bottomBar;
}

- (void) decrementBrushSize:(id)sender
{
    [[WDActiveState sharedInstance].brush.weight decrement];
    brushSlider_.value = [WDActiveState sharedInstance].brush.weight.value;
}

- (void) incrementBrushSize:(id)sender
{
    [[WDActiveState sharedInstance].brush.weight increment];
    brushSlider_.value = [WDActiveState sharedInstance].brush.weight.value;
}

- (void) takeBrushSizeFrom:(WDBarSlider *)sender
{
    [WDActiveState sharedInstance].brush.weight.value = roundf(sender.value);
}

- (void) brushSliderBegan:(id)sender
{
    [self hidePopovers];
}

- (NSArray *) bottomBarItems
{
    WDBarItem *fixed = [WDBarItem fixedItemWithWidth:5];
    
    undo_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"undo.png"]
                         landscapeImage:[UIImage imageNamed:@"undoLandscape.png"]
                                 target:self action:@selector(undo:)];
    
    redo_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"redo.png"]             
                         landscapeImage:[UIImage imageNamed:@"redoLandscape.png"]
                                 target:self action:@selector(redo:)];

    layer_ = [WDBarItem barItemWithImage:[self layerImage] target:self action:@selector(showLayers:)];
    
    WDBarItem *brushItem = [WDBarItem barItemWithImage:[UIImage imageNamed:@"style.png"]
                                        landscapeImage:[UIImage imageNamed:@"styleLandscape.png"]
                                                target:self
                                                action:@selector(showBrushPanel:)];
    
    gear_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"gear.png"]
                         landscapeImage:[UIImage imageNamed:@"gearLandscape.png"]
                                 target:self
                                 action:self.runningOnPhone ? @selector(showGearSheet:) : @selector(showGearMenu:)];
    
    CGRect wellFrame = self.runningOnPhone ? CGRectMake(0, 0, 44, 44) : CGRectMake(0, 0, 66, 44);
    colorWell_ = [[WDColorWell alloc] initWithFrame:wellFrame];
    WDBarItem *colorItem = [WDBarItem barItemWithView:colorWell_];
    colorWell_.color = [WDActiveState sharedInstance].paintColor;
    [colorWell_ addTarget:self action:@selector(showColorPicker:) forControlEvents:UIControlEventTouchUpInside];
    
    brushSlider_ = [[WDBarSlider alloc] initWithFrame:CGRectMake(0, 0, 290, 44)];
    WDBarItem *brushSizeItem = [WDBarItem barItemWithView:brushSlider_];
    brushSizeItem.flexibleContent = YES;
    brushSlider_.value = [WDActiveState sharedInstance].brush.weight.value;
    [brushSlider_ addTarget:self action:@selector(takeBrushSizeFrom:) forControlEvents:UIControlEventValueChanged];
    [brushSlider_ addTarget:self action:@selector(brushSliderBegan:) forControlEvents:UIControlEventTouchDown];
    
    NSMutableArray *items;
    if (self.runningOnPhone) {
        items = [NSMutableArray arrayWithObjects:
                 colorItem, [WDBarItem flexibleItem],
                 brushItem, [WDBarItem flexibleItem],
                 undo_, [WDBarItem flexibleItem],
                 redo_, [WDBarItem flexibleItem],
                 gear_, [WDBarItem flexibleItem],
                 layer_,
                 nil];
    } else {
        items = [NSMutableArray arrayWithObjects:
                 colorItem, [WDBarItem flexibleItem], nil];
        
        [self addToolButtons:[WDActiveState sharedInstance].tools toArray:items];
        
        [items addObjectsFromArray:@[[WDBarItem flexibleItem],
                                    brushItem, [WDBarItem flexibleItem],
                                    brushSizeItem, 
                                    [WDBarItem flexibleItem],
                                    undo_, fixed,
                                    redo_, fixed,
                                    gear_, fixed,
                                    layer_]];
    }
    
    return items;
}

#pragma mark -
#pragma mark Notifications
 
- (void) undoStatusDidChange:(NSNotification *)aNotification
{
    undo_.enabled = [self.painting.undoManager canUndo];
    redo_.enabled = [self.painting.undoManager canRedo];
}

- (void) layerVisibilityChanged:(NSNotification *)aNotification
{
    [canvas_ drawView];
    [self enableItems];
}

- (void) layerAdded:(NSNotification *)aNotification
{
    [self enableItems];
}

- (void) layerDeleted:(NSNotification *)aNotification
{
    [self enableItems];
}

- (void) layerLockedStatusChanged:(NSNotification *)aNotification
{
    [self enableItems];
}

- (void) activeLayerChanged:(NSNotification *)aNotification
{
    [layer_ setImage:[self layerImage]];
}

- (void) colorBalanceChanged:(NSNotification *)aNotification
{
    [canvas_ drawViewAtEndOfRunLoop];
}

- (void) hueSaturationChanged:(NSNotification *)aNotification
{
    [canvas_ drawViewAtEndOfRunLoop];
}

#pragma mark -
#pragma mark View Controller Stuff

- (void) brushChanged:(NSNotification *)aNotification
{
    [self.painting reloadBrush];
    brushSlider_.value = [WDActiveState sharedInstance].brush.weight.value;
}

- (void) paintColorChanged:(NSNotification *)aNotification
{
    colorWell_.color = [WDActiveState sharedInstance].paintColor;
}

- (void) loadView
{    
    UIView *background = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    background.opaque = YES;
    background.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.view = background;
    
    if (self.painting) {
        // background painting view
        canvas_ = [[WDCanvas alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        canvas_.painting = self.painting;
        canvas_.controller = self;
        
        [[WDStylusManager sharedStylusManager].pogoManager registerView:canvas_];
        
        [background addSubview:canvas_];
        
        if (self.canvasSettings) {
            [canvas_ updateFromSettings:self.canvasSettings];
            self.canvasSettings = nil;
        }
    }
}

- (void) viewWillUnload
{
    topBar = nil;
    bottomBar = nil;
    
    self.needsToResetInterfaceMode = YES;
    
    // cache the canvas zoom and position so that we can restore it
    self.canvasSettings = [canvas_ viewSettings];
}

- (void) sliderUnlocked:(id)sender
{
    [self setEditing:YES animated:YES];
}

- (void) didResign:(NSNotification *)aNotification
{
    [self.replay pause];
    [canvas_ cancelUpdate];
    [self showInterface];
    
    glFinish();
}

- (void) didEnterBackground:(NSNotification *)aNotification
{
    if ([self.document hasUnsavedChanges]) {
        // might get terminated while backgrounded, so save now        
        UIApplication   *app = [UIApplication sharedApplication];
        
        __block UIBackgroundTaskIdentifier task = [app beginBackgroundTaskWithExpirationHandler:^{
            if (task != UIBackgroundTaskInvalid) {
                [app endBackgroundTask:task];
            }
        }];
        
        [self.document saveToURL:self.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
               if (task != UIBackgroundTaskInvalid) {
                   [app endBackgroundTask:task];
               }
            });
        }];
    }
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
    // if the document has never saved and we go back to the gallery after a memory warning, the browser will be confused
    // because it reloads its view before the document is normally saved (during -viewWillDisappear:)
    [self.document autosaveWithCompletionHandler:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self hidePopovers];
}

- (void)sessionStateChanged:(NSNotification *)sessionStateChanged {
    [self updateTitle];
}

- (WDUnlockView *) unlockView
{
    if (!unlockView) {
        unlockView = [WDUnlockView unlockView];
        [unlockView addTarget:self action:@selector(sliderUnlocked:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:unlockView];
        
        int inset = [UIDevice currentDevice].userInterfaceIdiom ==  UIUserInterfaceIdiomPhone ? 22 : 44;
        inset += CGRectGetHeight(unlockView.bounds) / 2;
        unlockView.sharpCenter = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetHeight(self.view.bounds) - inset);
    }
    
    return unlockView;
}

- (void) oneTap:(UITapGestureRecognizer *)recognizer
{
    if (self.replay && !self.replay.paused) {
        [replay pause];
        [self showInterface];
    } else if (self.interfaceMode != WDInterfaceModeHidden) {
        [self hideInterface];
    } else {
        [self showInterface];
    }
}

- (void) replayPainting:(id)obj
{
    self.interfaceMode = WDInterfaceModeHidden;

    if (!self.replay) {
        float scale = 1.0f;
        
        #if RESCALE_REPLAY
            // either have a Replay xor a Document at any time; both doubles memory requirements
            CGSize displaySize = WDMultiplySizeScalar([UIScreen mainScreen].bounds.size, [UIScreen mainScreen].scale);
            CGSize paintingSize = self.document.painting.dimensions;

            float longestEdge = MAX(paintingSize.width, paintingSize.height);
            float maxEdge = MAX(displaySize.width, displaySize.height);
            scale = WDClamp(0.25f, 2.0f, maxEdge / longestEdge);
        #endif

        self.replay = [[WDDocumentReplay alloc] initWithDocument:self.document includeUndos:NO scale:scale];
        self.document = nil;
        
        self.canvas.painting = replay.painting;
        if (scale != 1) {
            [self.canvas adjustForReplayScale:scale];
        }
        
        replay.replayDelegate = self;
    } else if ([self.replay isFinished]) {
        [self.replay restart];
        self.canvas.painting = replay.painting;
    }
    
    [replay play];
}

- (void) replayFinished
{
    [self performSelector:@selector(showInterface) withObject:nil afterDelay:0];
}

- (void) replayError
{
    NSString *title = NSLocalizedString(@"Replay Error", @"Replay Error");
    NSString *message = NSLocalizedString(@"There was a problem replaying this painting. It may have been created with a newer version of Brushes. Check the App Store for an update.", @"There was a problem replaying this painting. It may have been created with a newer version of Brushes. Check the App Store for an update.");
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
    
    [self.replay pause];
    [self showInterface];
}

- (UIButton *) playButton
{
    if (!playButton) {
        playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [playButton addTarget:self action:@selector(replayPainting:) forControlEvents:UIControlEventTouchUpInside];
        playButton.opaque = NO;
        playButton.backgroundColor = nil;
        UIImage *image = [UIImage imageNamed:@"play.png"];
        [playButton setImage:image forState:UIControlStateNormal];
        playButton.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        
        playButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        playButton.sharpCenter = WDCenterOfRect(self.view.bounds);
        [self.view addSubview:playButton];
    }
    
    return playButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.hasAppearedBefore) {
        // hide the default navbar and toolbar
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController setToolbarHidden:YES animated:YES];
        
        self.interfaceMode = WDInterfaceModeLoading;
        self.hasAppearedBefore = YES;
        
        self.bottomBar.items = [self bottomBarItems];
    } else if (self.needsToResetInterfaceMode) {
        self.bottomBar.items = [self bottomBarItems];
        [self setInterfaceMode:interfaceMode force:YES];
        self.needsToResetInterfaceMode = NO;
    }
        
    [self undoStatusDidChange:nil];
    [self configureForOrientation:self.interfaceOrientation];
    [self enableItems];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (document_.documentState != UIDocumentStateClosed) {
        [document_ closeWithCompletionHandler:nil];
    }
}

#pragma mark -
#pragma mark Miscellaneous

- (void) updateTitle
{
    NSString    *filename = self.document ? self.document.displayName : self.replay.paintingName;

    if (self.runningOnPhone) {
        self.title = filename;
    } else {
        int     zoom = round(canvas_.displayableScale);
        int     maxDisplayableFilename = 18;
        
        if (filename.length > maxDisplayableFilename + 3) { // add 3 to account for the ellipsis
            filename = [[filename substringToIndex:maxDisplayableFilename] stringByAppendingString:@"…"];
        }

        self.title = [NSString stringWithFormat:NSLocalizedString(@"%@ @ %d%%", @"Painting Title Format"), filename, zoom];
    }
}

- (void) registerNotifications
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
    [nc addObserver:self selector:@selector(didResign:)
               name:UIApplicationWillResignActiveNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(didEnterBackground:)
               name:UIApplicationDidEnterBackgroundNotification
             object:nil];
    
    [nc addObserver:self selector:@selector(paintColorChanged:) name:WDActivePaintColorDidChange object:nil];
    [nc addObserver:self selector:@selector(brushChanged:) name:WDActiveBrushDidChange object:nil];
    
    if (self.document) {
        [nc addObserver:self selector:@selector(loadProgress:) name:WDCodingProgressNotification object:self.document];
        [nc addObserver:self selector:@selector(documentStateChanged:) name:UIDocumentStateChangedNotification object:self.document];
    }
    
    if (self.painting) {
        [nc addObserver:self selector:@selector(layerLockedStatusChanged:) name:WDLayerLockedStatusChanged object:self.painting];
        [nc addObserver:self selector:@selector(layerVisibilityChanged:) name:WDLayerVisibilityChanged object:self.painting];
        
        [nc addObserver:self selector:@selector(activeLayerChanged:) name:WDActiveLayerChangedNotification object:self.painting];
        [nc addObserver:self selector:@selector(layerDeleted:) name:WDLayerDeletedNotification object:self.painting];
        [nc addObserver:self selector:@selector(layerAdded:) name:WDLayerAddedNotification object:self.painting];
        
        [nc addObserver:self selector:@selector(colorBalanceChanged:) name:WDColorBalanceChanged object:self.painting];
        [nc addObserver:self selector:@selector(hueSaturationChanged:) name:WDHueSaturationChanged object:self.painting];
    }

    NSUndoManager *undoManager = self.painting.undoManager;
    [self undoStatusDidChange:nil];
    if (undoManager) {
        [nc addObserver:self selector:@selector(willUndo:)
                   name:NSUndoManagerWillUndoChangeNotification
                 object:undoManager];
        
        [nc addObserver:self selector:@selector(willRedo:)
                   name:NSUndoManagerWillRedoChangeNotification
                 object:undoManager];
        
        
        [nc addObserver:self selector:@selector(undoStatusDidChange:)
                                                     name:NSUndoManagerDidUndoChangeNotification object:undoManager];
        [nc addObserver:self selector:@selector(undoStatusDidChange:)
                                                     name:NSUndoManagerDidRedoChangeNotification object:undoManager];
        [nc addObserver:self selector:@selector(undoStatusDidChange:)
                                                     name:NSUndoManagerWillCloseUndoGroupNotification object:undoManager];
    }
    
    // listen for stylus buttons too
    [nc addObserver:self selector:@selector(primaryStylusButtonPressed:)
               name:WDStylusPrimaryButtonPressedNotification object:nil];
    
    [nc addObserver:self selector:@selector(secondaryStylusButtonPressed:)
               name:WDStylusSecondaryButtonPressedNotification object:nil];
    
    // and stylus connections
    [nc addObserver:self selector:@selector(stylusConnected:)
               name:WDStylusDidConnectNotification object:nil];
    [nc addObserver:self selector:@selector(stylusDisconnected:)
               name:WDStylusDidDisconnectNotification object:nil];
    
    [nc addObserver:self selector:@selector(blueToothStatusChanged:) name:WDBlueToothStateChangedNotification object:nil];
}

- (void) fadingOutActionNameView:(WDActionNameView *)inActionNameView
{
    actionNameView = nil;
}

- (WDActionNameView *) actionNameView
{
    if (!actionNameView) {
        self.actionNameView = [[WDActionNameView alloc] initWithFrame:CGRectMake(0,0,180,60)];
        [self.view addSubview:actionNameView];
        actionNameView.center = WDCenterOfRect(self.view.bounds);
        actionNameView.delegate = self;
    }
    
    return actionNameView;
}

- (void) willUndo:(NSNotification *)aNotification
{
    NSString *actionName = self.painting.undoManager.undoActionName;
    
    if (actionName && ![actionName isEqualToString:@""]) {
        [self.actionNameView setUndoActionName:actionName];
    } else {
        WDLog(@"Undo with no action name.");
    }
}

- (void) willRedo:(NSNotification *)aNotification
{
    NSString *actionName = self.painting.undoManager.redoActionName;
    
    if (actionName && ![actionName isEqualToString:@""]) {
        [self.actionNameView setRedoActionName:actionName];
    } else {
        WDLog(@"Redo with no action name.");
    }
}

- (void) setDocument:(WDDocument *)document
{
    if (document != self.document) {
        if (document_.documentState != UIDocumentStateClosed) {
            [document_ closeWithCompletionHandler:nil];
        }
        
        if (layerController_) {
            // make sure to clear the old painting or it will show the wrong layers
            layerController_.painting = document.painting;
        }
        
        [self hidePopovers];
    }
    
    document_ = document;
    
    [self documentStateChanged:nil];
}

- (void) loadProgress:(NSNotification *)aNotification
{
    WDCodingProgress *progress = (aNotification.userInfo)[@"progress"];
    self.progressIndicator.progress = progress.progress;
}

- (void) documentStateChanged:(NSNotification *)aNotification
{
    if (self.document && self.document.documentState == UIDocumentStateNormal) {
        if (self.painting) {
            if (canvas_) {
                if (replayScale) {
                    [self.canvas adjustForReplayScale:(1.0f / replayScale.floatValue)];
                    self.replayScale = nil;
                }
                canvas_.painting = self.painting;
            } else {
                canvas_ = [[WDCanvas alloc] initWithFrame:self.view.bounds];
                canvas_.painting = self.painting;
                canvas_.controller = self;

                [[WDStylusManager sharedStylusManager].pogoManager registerView:canvas_];
                
                [self.view insertSubview:canvas_ atIndex:0];
            }
            
            if (!canvas_.hasEverBeenScaledToFit) {
                [canvas_ scaleDocumentToFit:NO];
            }
            
            // display the correct layer index in the nav bar
            [layer_ setImage:[self layerImage]];
        }
        
        [self updateTitle];
    }
    
    [self registerNotifications];
    
    [self enableItems];
    
    [self undoStatusDidChange:nil];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

#pragma mark -
#pragma mark Action Menu

- (void) addToPhotoAlbum:(id)sender
{
    UIImage *image = [canvas_.painting image];

    // this will write a JPEG
    UIImageWriteToSavedPhotosAlbum(image, self, nil, NULL);    

    // this will write a PNG
    //NSData *pngData = UIImagePNGRepresentation(image);
    //UIImage *pngImage = [UIImage imageWithData:pngData];
    //UIImageWriteToSavedPhotosAlbum(pngImage, self, nil, NULL);
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[controller dismissViewControllerAnimated:YES completion:nil];
}

- (void) emailPainting:(id)sender mimeType:(NSString *)mimeType data:(NSData *)data
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    NSString *subject = NSLocalizedString(@"Brushes Painting: ", @"Brushes Painting: ");
    NSString *filename = self.document ? self.document.displayName : self.replay.paintingName;
    subject = [subject stringByAppendingString:filename];
    [picker setSubject:subject];    
    
    [picker addAttachmentData:data mimeType:mimeType fileName:filename];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (BOOL) canPasteImage
{
    if (!self.isEditing) {
        return NO;
    }
    
    return [UIPasteboard generalPasteboard].image ? YES : NO;
}

- (void) pasteImage:(id)sender
{
    [canvas_ beginPhotoPlacement:[UIPasteboard generalPasteboard].image];
}

- (void) copyPainting:(id)sender
{
    [UIPasteboard generalPasteboard].image = [canvas_.painting image];
}

- (void) setUserInteractionEnabled:(BOOL)enabled
{
    self.canvas.userInteractionEnabled = enabled;
    self.topBar.userInteractionEnabled = enabled;
    self.bottomBar.userInteractionEnabled = enabled;
}

- (void) duplicatePainting:(id)sender
{
    // prevent anything being done to the old document before the new is loaded
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WDCodingProgressNotification object:self.document];
    [self setUserInteractionEnabled:NO];
    [self.document closeWithCompletionHandler:^(BOOL success) {
        if (!success) {
            WDLog(@"ERROR: Duplicate failed in close!");
            return;
        }
        self.progressIndicator.progress = 0.60f;
        WDDocument *duplicate = [[WDPaintingManager sharedInstance] duplicatePainting:self.document];
        [duplicate openWithCompletionHandler:^(BOOL success) {
            if (!success) {
                WDLog(@"ERROR: Duplicate failed in open!");
                return;
            }
            self.progressIndicator.progress = 0.90f;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.document = duplicate;
                [self setUserInteractionEnabled:YES];
            });
        }];
    }];

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.0f];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:canvas_ cache:YES];
    [UIView commitAnimations];
}

- (void) emailPNG:(id)sender
{
    NSData *imageData = [canvas_.painting PNGRepresentationForCurrentState];
    [self emailPainting:sender mimeType:@"image/png" data:imageData];
}

- (void) emailJPEG:(id)sender
{
    NSData *imageData = [canvas_.painting JPEGRepresentationForCurrentState];
    [self emailPainting:sender mimeType:@"image/jpeg" data:imageData];
}

#pragma mark - Interface Visibility

- (void) fadePlayControls
{
    if (!unlockView && !playButton) {
        return;
    }
    
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration
                     animations:^{
                         unlockView.alpha = 0.0f;
                         playButton.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         [unlockView removeFromSuperview];
                         unlockView = nil;
                         
                         [playButton removeFromSuperview];
                         playButton = nil;
                     }];
}

- (void) showInterface
{    
    if (replay && replay.isPlaying) {
        return;
    }
    
    if (canvas_.isZooming) {
        return;
    }
    
    if (!self.document && !self.replay) {
        self.interfaceMode = WDInterfaceModeLoading;
    } else {
        self.interfaceMode = self.isEditing ? WDInterfaceModeEdit : WDInterfaceModePlay;
    }
}

- (void) hideInterface
{
    self.interfaceMode = WDInterfaceModeHidden;
}

- (BOOL) interfaceHidden
{
    return (self.interfaceMode == WDInterfaceModeHidden) ? YES : NO;
}

- (WDProgressView *) progressIndicator 
{
    if (!progressIndicator) {
        progressIndicator = [[WDProgressView alloc] initWithFrame:CGRectMake(0,0,72,72)];
        progressIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        progressIndicator.sharpCenter = WDCenterOfRect(self.view.bounds);
        progressIndicator.fancyStyle = YES;
        [self.view addSubview:progressIndicator];
    }
    
    return progressIndicator;
}

- (void) setInterfaceMode:(WDInterfaceMode)inInterfaceMode
{
    [self setInterfaceMode:inInterfaceMode force:NO];
}

- (void) setInterfaceMode:(WDInterfaceMode)inInterfaceMode force:(BOOL)force
{
    if (!force && interfaceMode == inInterfaceMode) {
        return;
    }
    
    interfaceMode = inInterfaceMode;
    
    if (interfaceMode == WDInterfaceModePlay) {
        self.playButton.hidden = NO;
        self.unlockView.hidden = NO;
        
        self.topBar.hidden = NO;
        self.bottomBar.hidden = YES;
        
        // don't use the accessor when hiding -- if it's nil we don't want to create it
        progressIndicator.hidden = YES;
        
        self.topBar.items = [self replayTopBarItems];
    } else if (interfaceMode == WDInterfaceModeEdit) {
        [self fadePlayControls];
        
        self.topBar.hidden = NO;
        self.bottomBar.hidden = NO;
        
        if (self.runningOnPhone) {
            self.topBar.title = nil;
        }
        [self.topBar setItems:[self editingTopBarItems] animated:YES];
        
        [self.painting preloadPaintTexture];
        
        progressIndicator.hidden = YES;
    } else if (interfaceMode == WDInterfaceModeHidden) {
        // don't use the accessor when hiding -- if it's nil we don't want to create it
        playButton.hidden = YES;
        unlockView.hidden = YES;
        progressIndicator.hidden = YES;
        
        self.topBar.hidden = YES;
        self.bottomBar.hidden = YES;
    } else if (interfaceMode == WDInterfaceModeLoading) {
        // don't use the accessor when hiding -- if it's nil we don't want to create it
        playButton.hidden = YES;
        unlockView.hidden = YES;

        self.topBar.hidden = NO;
        self.bottomBar.hidden = YES;
        
        progressIndicator.hidden = YES;
        [self performSelector:@selector(showProgress) withObject:nil afterDelay:0.5];

        self.topBar.items = [self loadingTopBarItems];
        [self.topBar setTitle:NSLocalizedString(@"Loading…", @"Loading…")];
    }
}

- (void) showProgress
{
    if (self.interfaceMode == WDInterfaceModeLoading) {
        self.progressIndicator.hidden = NO;
    }
}

- (UIView *) rotatingHeaderView
{
    return self.topBar;
}

- (UIView *) rotatingFooterView
{
    return self.bottomBar;
}

@end
