//
//  WDBrowserController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <DropboxSDK/DropboxSDK.h>
#import "UIView+Additions.h"
#import "WDActiveState.h"
#import "WDActivity.h"
#import "WDActivityController.h"
#import "WDActivityManager.h"
#import "WDAppDelegate.h"
#import "WDBlockingView.h"
#import "WDBrowserController.h"
#import "WDCanvasController.h"
#import "WDDocument.h"
#import "WDEmail.h"
#import "WDExportController.h"
#import "WDMenuItem.h"
#import "WDPaintingManager.h"
#import "WDPaintingSizeController.h"
#import "WDThumbnailView.h"
#import "WDUtilities.h"
#import "WDPaintingIterator.h"

#define ALLOW_CAMERA_IMPORT NO

static NSString *WDAttachmentNotification = @"WDAttachmentNotification";

@implementation WDBrowserController {
    UIImageView *snapshotBeforeRotation;
    UIImageView *snapshotAfterRotation;
    CGRect frameBeforeRotation;
    CGRect frameAfterRotation;
    NSUInteger centeredIndex;
    NSMutableSet *savingPaintings;
}

@synthesize currentPopoverViewController;
@synthesize activityIndicator;
@synthesize gridView;

- (void) buildDefaultNavBar
{
    [self updateTitle];
    
    // Create an add button to display in the top right corner.
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:self
                                                                             action:@selector(addPainting:)];
    
    
    UIBarButtonItem *importItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize
                                                                                target:self
                                                                                action:@selector(showDropboxImportPanel:)];
    
    UIBarButtonItem *cameraItem = nil;
    if (ALLOW_CAMERA_IMPORT && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        cameraItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                   target:self
                                                                   action:@selector(importFromCamera:)];
        self.navigationItem.rightBarButtonItems = @[addItem, importItem, cameraItem];
        
    } else {
        self.navigationItem.rightBarButtonItems = @[addItem, importItem];
    }
    
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", @"Select")
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(startEditing:)];
    self.navigationItem.leftBarButtonItem = leftItem;
}

- (UIPopoverController *) runPopoverWithController:(UIViewController *)controller from:(id)sender
{
    [self hidePopovers];
    
    popoverController_ = [[UIPopoverController alloc] initWithContentViewController:controller];
	popoverController_.delegate = self;
    popoverController_.passthroughViews = @[self.navigationController.navigationBar];
    [popoverController_ presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
    return popoverController_;
}

- (void) hidePopovers
{
    if (popoverController_) {
        [popoverController_ dismissPopoverAnimated:NO];
        popoverController_ = nil;
    }
}

- (void) emailPaintings:(NSString *)format
{
    [self dismissPopoverAnimated:YES];
    
    NSString *contentType = [WDDocument contentTypeForFormat:format];
    [self startExportActivity:contentType];
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    WDEmail *email = [[WDEmail alloc] init];
    email.completeAttachments = 0;
    email.expectedAttachments = [selectedPaintings_ count];
    email.picker = picker;
    
    WDPaintingIterator *iterator = [[WDPaintingIterator alloc] init];
    iterator.paintings = [selectedPaintings_ allObjects];
    iterator.block = ^void(WDDocument *document) {
        NSError *err = nil;
        NSData  *data = [document contentsForType:contentType error:&err];
        NSString *mimeType = [document mimeTypeForContentType:contentType];
        NSString *extension = [document fileNameExtensionForType:contentType saveOperation:UIDocumentSaveForCreating];
        NSString *fullName = [document.displayName stringByAppendingPathExtension:extension];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fullName];
        [activities_ removeActivityWithFilepath:path];
        [picker addAttachmentData:data mimeType:mimeType fileName:fullName];

        [[NSNotificationCenter defaultCenter] postNotificationName:WDAttachmentNotification object:email userInfo:@{@"path": document.displayName}];
    };
    [iterator processNext];
    
    NSString *subject = NSLocalizedString(@"Brushes Paintings", @"Brushes Paintings");
    if (selectedPaintings_.count == 1) {
        subject = NSLocalizedString(@"Brushes Painting: ", @"Brushes Painting: ");
        subject = [subject stringByAppendingString:[[selectedPaintings_ anyObject] stringByDeletingPathExtension]];
    }
    [picker setSubject:subject];
}

- (void) startExportActivity:(NSString *)contentType
{
    for (NSString *name in selectedPaintings_) {
        WDDocument *document = [[WDPaintingManager sharedInstance] paintingWithName:name];
        NSString *extension = [document fileNameExtensionForType:contentType saveOperation:UIDocumentSaveForCreating];
        NSString *fullName = [name stringByAppendingPathExtension:extension];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fullName];
        WDActivity *exportActivity = [WDActivity activityWithFilePath:path type:WDActivityTypeExport];
        [activities_ addActivity:exportActivity];
    }
}

- (void) reallySendToDropbox:(NSString *)format
{
    if (!restClient_) {
        restClient_ = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient_.delegate = self;
        
        [restClient_ loadMetadata:@"/"];
    }
    
    NSString *contentType = [WDDocument contentTypeForFormat:format];
    [self startExportActivity:contentType];
    
    WDPaintingIterator *iterator = [[WDPaintingIterator alloc] init];
    iterator.paintings = [selectedPaintings_ allObjects];
    iterator.block = ^void(WDDocument *document) {
        NSString *extension = [document fileNameExtensionForType:contentType saveOperation:UIDocumentSaveForCreating];
        NSString *fullName = [document.displayName stringByAppendingPathExtension:extension];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:fullName];

        NSError *err = nil;
        if ([document writeTemp:path type:contentType error:&err]) {
            [restClient_ uploadFile:[path lastPathComponent] toPath:[self appFolderPath]
                    withParentRev:nil fromPath:path];
            [activities_ removeActivityWithFilepath:path];
            [activities_ addActivity:[WDActivity activityWithFilePath:path type:WDActivityTypeUpload]];
            [filesBeingUploaded_ addObject:path];
        } else {
            [activities_ removeActivityWithFilepath:path];
            WDLog(@"ERROR: Failed to write file %@ for upload: %@", document.displayName, err);
        }
    };
    [iterator processNext];
}

- (void) sendToDropbox:(NSString *)format
{
    [self dismissPopoverAnimated:[[DBSession sharedSession] isLinked]];
    
    if (![self dropboxIsLinked]) {
        WDAppDelegate *delegate = (WDAppDelegate *) [UIApplication sharedApplication].delegate;
        delegate.performAfterDropboxLoginBlock = ^{ [self reallySendToDropbox:format]; };
    } else {
        [self reallySendToDropbox:format];
    }
}

- (void) buildEditingNavBar
{
    [self updateTitle];
    
    if (!deleteItem_) {
        deleteItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                    target:self
                                                                    action:@selector(showDeleteMenu:)];
    }
    
    if (!shareItem_) {
        shareItem_ = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction 
                                                                   target:self
                                                                   action:@selector(showExportPanel:)];
    }
    
    self.navigationItem.rightBarButtonItems = @[shareItem_, deleteItem_];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(stopEditing:)];
    self.navigationItem.leftBarButtonItem = leftItem;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    selectedPaintings_ = [[NSMutableSet alloc] init];
    filesBeingUploaded_ = [[NSMutableSet alloc] init];
    activities_ = [[WDActivityManager alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(paintingAdded:)
                                                 name:WDPaintingAdded
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(paintingsDeleted:)
                                                 name:WDPaintingsDeleted
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dropboxUnlinked:)
                                                 name:WDDropboxWasUnlinkedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activityCountChanged:)
                                                 name:WDActivityAddedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activityCountChanged:)
                                                 name:WDActivityRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(emailAttached:) 
                                                name:WDAttachmentNotification 
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(paintingStartedSaving:)
                                                 name:WDDocumentStartedSavingNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(paintingFinishedSaving:)
                                                 name:WDDocumentFinishedSavingNotification
                                               object:nil];

    [self buildDefaultNavBar];

    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (NSInteger) thumbnailDimension
{
    return self.runningOnPhone ? 96 : 235; // 148 for big thumbs on the iPhone
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // force initialization
    [WDActiveState sharedInstance];    
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    NSUInteger currentCenteredIndex = [gridView approximateIndexOfCenter];
    if (centeredIndex != 0 && centeredIndex != currentCenteredIndex) {
        [self.gridView centerIndex:centeredIndex];
    }
}

- (void) showOpenFailure:(WDDocument *)document
{
    NSString *title = NSLocalizedString(@"Could Not Open Painting", @"Could Not Open Painting");
    NSString *format = NSLocalizedString(@"There was a problem opening “%@”.", @"There was a problem opening “%@”.");
                              
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:[NSString stringWithFormat:format, document.displayName]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) openDocument:(WDDocument *)document editing:(BOOL)editing
{
    WDCanvasController *canvasController = [[WDCanvasController alloc] init];
    [self.navigationController pushViewController:canvasController animated:YES];
    // set the document before setting the editing flag
    canvasController.document = document;

    [document openWithCompletionHandler:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                canvasController.editing = editing || ([document.history count] <= 4);
            } else {
                [self showOpenFailure:document];
            }
        });
    }];
}

- (void) alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.navigationController popToViewController:self animated:YES];
}

- (void) updateTitle
{
    if (self.isEditing) {
        NSString *format = NSLocalizedString(@"%d Selected", @"%d Selected");
        self.title = [NSString stringWithFormat:format, selectedPaintings_.count];
    } else {
        NSInteger count = [[WDPaintingManager sharedInstance] numberOfPaintings];
        NSString *format = NSLocalizedString(@"Gallery: %d", @"Gallery: %d");
        self.title = [NSString stringWithFormat:format, count];
    }
}

- (void) tappedOnPainting:(id)sender
{
    if (editingThumbnail_) {
        return;
    }
    
    if (!self.isEditing) {
        NSUInteger index = [(UIView *)sender tag];
        WDDocument *document = [[WDPaintingManager sharedInstance] paintingAtIndex:index];
        [self openDocument:document editing:NO];
    } else {
        WDThumbnailView     *thumbnail = (WDThumbnailView *)sender;
        NSString            *filename = [[WDPaintingManager sharedInstance] fileAtIndex:[thumbnail tag]];
        
        if ([selectedPaintings_ containsObject:filename]) {
            thumbnail.selected = NO;
            [selectedPaintings_ removeObject:filename];
        } else {
            thumbnail.selected = YES;
            [selectedPaintings_ addObject:filename];
        }
        
        [self updateTitle];
        
        [self properlyEnableNavBarItems];
    }
}

- (void) createNewPainting:(CGSize)size
{   
    [self dismissPopoverAnimated:NO];
    
    WDCanvasController *canvasController = [[WDCanvasController alloc] init];
    [self.navigationController pushViewController:canvasController animated:YES];
    
    [[WDPaintingManager sharedInstance] createNewPaintingWithSize:size afterSave:^(WDDocument *document) {
        // set the document before setting the editing flag
        canvasController.document = document;
        canvasController.editing = YES;
    }];

    [gridView scrollToBottom];
    centeredIndex = 0;
}

- (NSInteger) cellDimension
{
    return self.runningOnPhone ? 96 : 235; // 148 for big thumbs on the iPhone
}

- (NSUInteger)numberOfItemsInGridView:(WDGridView *)inGridView
{
    return [[WDPaintingManager sharedInstance] numberOfPaintings];
}

- (UIView *) gridView:(WDGridView *)inGridView cellForIndex:(NSUInteger)index
{
    WDThumbnailView *thumbview = [inGridView dequeueReusableCellWithReuseIdentifier:@"thumbnail" forIndex:index];
    
    NSArray *paintings = [[WDPaintingManager sharedInstance] paintingNames];
    
    thumbview.target = self;
    thumbview.action = @selector(tappedOnPainting:);
    thumbview.delegate = self;
    thumbview.filename = paintings[index];
    thumbview.tag = index;
    [savingPaintings containsObject:thumbview.filename] ? [thumbview startActivity] : [thumbview stopActivity];
    
    // selectedPaintings_ should be empty if we're not editing
    thumbview.selected = [selectedPaintings_ containsObject:thumbview.filename] ? YES : NO;

    return thumbview;
}

- (void)loadView
{
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
    
    gridView = [[WDGridView alloc] initWithFrame:frame];
    gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	gridView.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1];
    gridView.delegate = self;
    gridView.alwaysBounceVertical = YES;
    gridView.dataSource = self;
    [gridView registerClass:[WDThumbnailView class] forCellWithReuseIdentifier:@"thumbnail"];
    
    [self.view addSubview:gridView];
    [gridView scrollToBottom];
}

- (BOOL) thumbnailShouldBeginEditing:(WDThumbnailView *)thumb
{
    if (self.isEditing) {
        return NO;
    }
    
    // can't start editing if we're already editing another thumbnail
    return (editingThumbnail_ ? NO : YES);
}

- (void) blockingViewTapped:(id)sender
{
    [editingThumbnail_ stopEditing];
}

- (void) didEnterBackground:(NSNotification *)aNotification
{
    if (!editingThumbnail_) {
        return;
    }
    
    [editingThumbnail_ stopEditing];
}

- (void) thumbnailDidBeginEditing:(WDThumbnailView *)thumbView
{
    editingThumbnail_ = thumbView;
}

- (void) thumbnailDidEndEditing:(WDThumbnailView *)thumbView
{
    [UIView animateWithDuration:0.2f
                     animations:^{ blockingView_.alpha = 0; }
                     completion:^(BOOL finished) {
                         [blockingView_ removeFromSuperview];
                         blockingView_ = nil;
                     }];
    
    editingThumbnail_ = nil;
}

- (void) keyboardWillShow:(NSNotification *)aNotification
{
    if (!editingThumbnail_ || blockingView_) {
        return;
    }
    
    NSValue     *endFrame = [aNotification userInfo][UIKeyboardFrameEndUserInfoKey];
    CGRect      frame = [endFrame CGRectValue];
    float       delta = 0;
    
    CGRect thumbFrame = editingThumbnail_.frame;
    thumbFrame.size.height += 20; // add a little extra margin between the thumb and the keyboard
    frame = [gridView convertRect:frame fromView:nil];
    
    if (CGRectIntersectsRect(thumbFrame, frame)) {
        delta = CGRectGetMaxY(thumbFrame) - CGRectGetMinY(frame);
        
        CGPoint offset = gridView.contentOffset;
        offset.y += delta;
        [gridView setContentOffset:offset animated:YES];
    }
    
    blockingView_ = [[WDBlockingView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    WDAppDelegate *delegate = (WDAppDelegate *) [UIApplication sharedApplication].delegate;
    
    blockingView_.passthroughViews = @[editingThumbnail_.titleField];
    [delegate.window addSubview:blockingView_];
    
    blockingView_.target = self;
    blockingView_.action = @selector(blockingViewTapped:);
}

- (void) paintingStartedSaving:(NSNotification *)aNotification
{
    if (!savingPaintings) {
        savingPaintings = [NSMutableSet set];
    }
    WDDocument *doc = (WDDocument *)aNotification.object;
    NSArray *paintings = [[WDPaintingManager sharedInstance] paintingNames];
    WDThumbnailView *thumbview = (WDThumbnailView *) [gridView visibleCellForIndex:[paintings indexOfObject:doc.displayName]];
    [savingPaintings addObject:doc.displayName];
    [thumbview startActivity];
}

- (void) paintingFinishedSaving:(NSNotification *)aNotification
{
    WDDocument *doc = (WDDocument *)aNotification.object;
    NSArray *paintings = [[WDPaintingManager sharedInstance] paintingNames];
    WDThumbnailView *thumbview = (WDThumbnailView *) [gridView visibleCellForIndex:[paintings indexOfObject:doc.displayName]];
    [thumbview updateThumbnail:doc.thumbnail];
    [savingPaintings removeObject:doc.displayName];
    [thumbview stopActivity];
}

- (void) paintingAdded:(NSNotification *)aNotification
{
    [gridView setNeedsLayout];
    [self updateTitle];
}

- (void) paintingsDeleted:(NSNotification *)aNotification
{
    NSSet *deletedNames = aNotification.object;
    NSArray *paintings = [[WDPaintingManager sharedInstance] paintingNames];
    for (NSString *name in deletedNames) {
        WDThumbnailView *thumbview = (WDThumbnailView *) [gridView visibleCellForIndex:[paintings indexOfObject:name]];
        [thumbview clear];
    }

    // do after thumbnails are cleared or they shuffle around
    [selectedPaintings_ removeAllObjects];
    
    [gridView cellsDeleted];
    [self updateTitle];
    
    [self properlyEnableNavBarItems];
}

- (void) viewDidUnload
{
    // don't try to reference these any more
    gridView = nil;
}

- (NSString*) appFolderPath
{
    NSString* appFolderPath = @"Brushes";
    if (![appFolderPath isAbsolutePath]) {
        appFolderPath = [@"/" stringByAppendingString:appFolderPath];
    }
    
    return appFolderPath;    
}

- (void) properlyEnableNavBarItems
{
    deleteItem_.enabled = [selectedPaintings_ count] == 0 ? NO : YES;
    shareItem_.enabled = [selectedPaintings_ count] == 0 ? NO : YES;
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    [self stopUploadActivity:srcPath];
}

- (void) deleteSelectedPaintings
{
    NSString *format = NSLocalizedString(@"Delete %d Paintings", @"Delete %d Paintings");
    NSString *title = (selectedPaintings_.count) == 1 ? NSLocalizedString(@"Delete Painting", @"Delete Painting") :
    [NSString stringWithFormat:format, selectedPaintings_.count];
    
    NSString *message;
    
    if (selectedPaintings_.count == 1) {
        message = NSLocalizedString(@"Once deleted, this painting cannot be recovered.", @"Alert text when deleting 1 painting");
    } else {
        message = NSLocalizedString(@"Once deleted, these paintings cannot be recovered.", @"Alert text when deleting multiple paintings");
    }
    
    NSString *deleteButtonTitle = NSLocalizedString(@"Delete", @"Title of Delete button");
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Title of Cancel button");

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:nil
                                              otherButtonTitles:deleteButtonTitle, cancelButtonTitle, nil];
    alertView.cancelButtonIndex = 1;
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    
    [[WDPaintingManager sharedInstance] deletePaintings:selectedPaintings_];
    
    [self updateTitle];
}

#pragma mark - Delete Action Sheet

- (void) showDeleteMenu:(id)sender
{
    if (deleteSheet_) {
        [self dismissPopoverAnimated:YES];
        return;
    }
    
    [self dismissPopoverAnimated:NO];
    
    NSString *format = NSLocalizedString(@"Delete %d Paintings", @"Delete %d Paintings");
    NSString *action = (selectedPaintings_.count) == 1 ? NSLocalizedString(@"Delete Painting", @"Delete Painting") :
                            [NSString stringWithFormat:format, selectedPaintings_.count];
    if (self.runningOnPhone) {
        deleteSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        deleteSheet_.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        
        deleteSheet_.destructiveButtonIndex = [deleteSheet_ addButtonWithTitle:action];
        deleteSheet_.cancelButtonIndex = [deleteSheet_ addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")];
    } else {
        deleteSheet_ = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@""
                                     destructiveButtonTitle:action otherButtonTitles:nil];
    }
    
    [deleteSheet_ showFromBarButtonItem:sender animated:YES];
}
     
 - (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == deleteSheet_) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self deleteSelectedPaintings];
        }
    }
    
    deleteSheet_ = nil;
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self dismissPopoverAnimated:NO];
    
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [self buildEditingNavBar];
        [self properlyEnableNavBarItems];
    } else {
        for (WDThumbnailView *thumbview in gridView.visibleCells) {
            thumbview.selected = NO;
        }
        
        [selectedPaintings_ removeAllObjects];
        
        [self buildDefaultNavBar];
    }
}

#pragma mark -
#pragma mark Import/Export

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void) emailAttached:(NSNotification *)aNotification
{
    WDEmail *email = aNotification.object;
    if (++email.completeAttachments == email.expectedAttachments) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentModalViewController:email.picker animated:YES];
        });
    }
}

- (void) dropboxUnlinked:(NSNotification *)aNotification
{
    [self dismissPopoverAnimated:YES];
}

- (BOOL) dropboxIsLinked
{
    if ([[DBSession sharedSession] isLinked]) {
        return YES;
    } else {
        [self dismissPopoverAnimated:NO];
        [[DBSession sharedSession] linkUserId:nil fromController:self];
        return NO;
    }
}

#pragma mark - Managing View Controllers

- (void) dismissPopoverAnimated:(BOOL)animated
{    
    if (popoverController_) {
        [popoverController_ dismissPopoverAnimated:animated];
        popoverController_ = nil;
        self.currentPopoverViewController = nil;
    }
    
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
    
    if (deleteSheet_) {
        [deleteSheet_ dismissWithClickedButtonIndex:deleteSheet_.cancelButtonIndex animated:NO];
        deleteSheet_ = nil;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == popoverController_) {
        self.currentPopoverViewController = nil;
        popoverController_ = nil;
    }
}

- (void) showController:(UIViewController *)controller from:(id)sender
{
    if (!controller) {
        // we're trying to show the currently visible popover, so dismiss it and quit
        [self dismissPopoverAnimated:NO];
        return;
    }
    
    // hide any other popovers
    [self dismissPopoverAnimated:NO];
    
    // embed in a nav controller
    UIViewController *presentedController;
    
    if ([controller isKindOfClass:[UIImagePickerController class]]) {
        presentedController = controller;
    } else {
        presentedController = [[UINavigationController alloc] initWithRootViewController:controller];
    }
    
    if (self.runningOnPhone) {
        [self presentViewController:presentedController animated:YES completion:nil];
    } else {
        popoverController_ = [[UIPopoverController alloc] initWithContentViewController:presentedController];
        popoverController_.delegate = self;
        
        if ([sender isKindOfClass:[UIBarButtonItem class]]) {
            [popoverController_ presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender
                                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                                       animated:NO];
        } else {
            UIView *view = (UIView *) sender;
            [popoverController_ presentPopoverFromRect:view.bounds
                                                inView:view
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:NO];
        }
        
        self.currentPopoverViewController = controller;
    }
}


#pragma mark - Show Panels

- (void) showExportPanel:(id)sender
{
    WDExportController *controller = nil;
    
    if (![self.currentPopoverViewController isKindOfClass:[WDExportController class]]) {
        controller = [[WDExportController alloc] initWithNibName:@"Export" bundle:nil];
        controller.browserController = self;
    }
    
    [self showController:controller from:sender];
}

- (void) addPainting:(id)sender
{
    WDPaintingSizeController *controller = nil;
    
    if (![self.currentPopoverViewController isKindOfClass:[WDPaintingSizeController class]]) {
        controller = [[WDPaintingSizeController alloc] initWithNibName:@"SizeChooser" bundle:nil];
        controller.browserController = self;
    }
    
    [self showController:controller from:sender];
}

- (void) reallyShowDropboxImportPanel:(id)sender
{
	WDImportController *controller = nil;
    
    if (![self.currentPopoverViewController isKindOfClass:[WDImportController class]]) {
        controller = [[WDImportController alloc] initWithNibName:@"Import" bundle:nil];
        controller.delegate = self;
    }
    
    [self showController:controller from:sender];
}

- (void) showDropboxImportPanel:(id)sender
{
    if (![self dropboxIsLinked]) {
        WDAppDelegate *delegate = (WDAppDelegate *) [UIApplication sharedApplication].delegate;
        delegate.performAfterDropboxLoginBlock = ^{ [self reallyShowDropboxImportPanel:sender]; };
	} else {
        [self reallyShowDropboxImportPanel:sender];
    }
}

- (void) stopUploadActivity:(NSString *)filename
{
    [activities_ removeActivityWithFilepath:filename];
    [filesBeingUploaded_ removeObject:filename];
    
    [self properlyEnableNavBarItems];
}

- (void) activityTapped:(UITapGestureRecognizer *)recognizer
{
    WDActivityController *controller = nil;
    
    if (![self.currentPopoverViewController isKindOfClass:[WDActivityController class]]) {
        controller = [[WDActivityController alloc] initWithNibName:nil bundle:nil];
        controller.activityManager = activities_;
    }
    
    [self showController:controller from:recognizer.view];
}

- (void) createActivityIndicator
{
    UIActivityIndicatorViewStyle style = self.runningOnPhone ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleWhiteLarge;
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    self.activityIndicator = activity;
    
    // create a background view to make the indicator more visible
    CGRect frame = CGRectInset(self.activityIndicator.frame, -10, -10);
    UIView *bgView = [[UIView alloc] initWithFrame:frame];
    bgView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.333f];
    bgView.opaque = NO;
    bgView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
    
    // adjust the layer properties to get the appearance that we want
    CALayer *layer = bgView.layer;
    layer.cornerRadius = CGRectGetWidth(frame) / 2;
    layer.borderColor = [UIColor whiteColor].CGColor;
    layer.borderWidth = 1;
    
    [bgView addSubview:self.activityIndicator];

    // position the views properly
    self.activityIndicator.sharpCenter = WDCenterOfRect(bgView.bounds);
    CGPoint corner = CGPointMake(0.0f, CGRectGetMaxY(self.view.superview.bounds));
    corner = WDAddPoints(corner, CGPointMake(CGRectGetWidth(frame) * 0.75f, -CGRectGetHeight(frame) * 0.75f));
    bgView.sharpCenter = corner;
    [self.view addSubview:bgView];
    
    // respond to taps
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(activityTapped:)];
    [bgView addGestureRecognizer:tapRecognizer];
    
    [self.activityIndicator startAnimating];
}

- (void) activityCountChanged:(NSNotification *)aNotification
{
    NSUInteger numActivities = activities_.count;
    
    if (numActivities) {
        if (!self.activityIndicator) {
            [self createActivityIndicator];
        }
    } else {
        [self.activityIndicator.superview removeFromSuperview];
        self.activityIndicator = nil;
    }
    
    if (numActivities == 0 && [self.currentPopoverViewController isKindOfClass:[WDActivityController class]]) {
        [self dismissPopoverAnimated:YES];
    }
}

- (void) importController:(WDImportController *)controller didSelectDropboxItems:(NSArray *)dropboxItems
{
	if (!restClient_) {
		restClient_ = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
		restClient_.delegate = self;
	}
    
    NSString    *downloadsDirectory = [NSTemporaryDirectory() stringByAppendingString:@"Downloads/"];
    BOOL        isDirectory = NO;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadsDirectory isDirectory:&isDirectory] || !isDirectory) {
        [[NSFileManager defaultManager] createDirectoryAtPath:downloadsDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
	for (DBMetadata *item in dropboxItems) {
		NSString *downloadPath = [downloadsDirectory stringByAppendingFormat:@"%@", [item.path lastPathComponent]];
        
        // make sure we're not already downloading/importing this file
        if (!activities_.count || ![activities_ activityWithFilepath:downloadPath]) {
            [restClient_ loadFile:item.path intoPath:downloadPath];
            [activities_ addActivity:[WDActivity activityWithFilePath:downloadPath type:WDActivityTypeDownload]];
        }
	}
	
	[self dismissPopoverAnimated:NO];
}

- (void) showImportErrorMessage:(NSString *)filename
{
    NSString *format = NSLocalizedString(@"Brushes could not import “%@”. It may be corrupt or in a format that's not supported.",
                                         @"Brushes could not import “%@”. It may be corrupt or in a format that's not supported.");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import Problem", @"Import Problem")
                                                        message:[NSString stringWithFormat:format, filename]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) showImportTooLargeMessage:(NSString *)filename
{
    NSString *format = NSLocalizedString(@"Brushes could not import “%@”. The resolution is too high for this device.",
                                         @"Brushes could not import “%@”. The resolution is too high for this device.");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import Problem", @"Import Problem")
                                                        message:[NSString stringWithFormat:format, filename]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) showImportMemoryWarningMessage:(NSString *)filename
{
    NSString *format = NSLocalizedString(@"Brushes could not import “%@”. There is not enough available memory.",
                                         @"Brushes could not import “%@”. There is not enough available memory.");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import Problem", @"Import Problem")
                                                        message:[NSString stringWithFormat:format, filename]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath;
{
    [activities_ updateProgressForFilepath:srcPath progress:progress];
}

- (void) restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath
{
    [activities_ updateProgressForFilepath:destPath progress:progress];
}

- (void) restClient:(DBRestClient*)client loadedFile:(NSString*)downloadPath
{
    NSString    *extension = [[downloadPath pathExtension] lowercaseString];
    NSString    *filename = [downloadPath lastPathComponent];
    
    WDActivity  *downloadActivity = [activities_ activityWithFilepath:downloadPath];
    
    if ([extension isEqualToString:@"brushes"]) {
        WDActivity *importActivity = [WDActivity activityWithFilePath:downloadPath type:WDActivityTypeImport];
        [activities_ addActivity:importActivity];
           
        NSError *error;
        [[WDPaintingManager sharedInstance] installPaintingFromURL:[NSURL fileURLWithPath:downloadPath] error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:NULL];
        [activities_ removeActivity:importActivity];
        if (error && error.code == 2) {
            [self showImportTooLargeMessage:filename];
        } else if (error) {
            [self showImportErrorMessage:filename];
        }
    } else if ([WDImportController canImportType:extension]) {
		BOOL success = [[WDPaintingManager sharedInstance] createNewPaintingWithImageAtURL:[NSURL fileURLWithPath:downloadPath]];
        if (!success) {
            [self showImportErrorMessage:filename];
        }
        
        [[NSFileManager defaultManager] removeItemAtPath:downloadPath error:NULL];
	}
    
    // remove the download activity. do this last so the activity count doesn't drop to 0
    [activities_ removeActivity:downloadActivity];
}

- (void) restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error
{
	NSString *downloadPath = [[error userInfo] valueForKey:@"destinationPath"];
	
    [activities_ removeActivityWithFilepath:downloadPath];
	[[NSFileManager defaultManager] removeItemAtPath:downloadPath error:NULL];

    NSString *format = NSLocalizedString(@"There was a problem downloading “%@”. Check your network connection and try again.",
                                         @"There was a problem downloading“%@”. Check your network connection and try again.");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Download Problem", @"Download Problem")
                                                        message:[NSString stringWithFormat:format, [downloadPath lastPathComponent]]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSString *srcPath = [[error userInfo] valueForKey:@"sourcePath"];
	
    [self stopUploadActivity:srcPath];
    
    NSString *format = NSLocalizedString(@"There was a problem uploading “%@”. Check your network connection and try again.",
                                         @"There was a problem uploading“%@”. Check your network connection and try again.");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Upload Problem", @"Upload Problem")
                                                        message:[NSString stringWithFormat:format, [srcPath lastPathComponent]]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void) stopEditing:(id)sender
{
    [self setEditing:NO animated:YES];
}

- (void) startEditing:(id)sender
{
    [self setEditing:YES animated:YES];
}

- (void)didDismissModalView {
    // Dismiss the modal view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}    

- (BOOL) ignoreOrientationChange:(UIInterfaceOrientation)inOrientation
{
    BOOL inPortrait = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
    BOOL goingToPortrait = UIInterfaceOrientationIsPortrait(inOrientation);
    
    return (inPortrait == goingToPortrait) ? YES : NO;
}

- (void) viewWillDisappear:(BOOL)animated
{    
    centeredIndex = [gridView approximateIndexOfCenter];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self ignoreOrientationChange:toInterfaceOrientation]) {
        return;
    }
    
    frameBeforeRotation = gridView.frame;
    
    centeredIndex = [gridView approximateIndexOfCenter];
    
    UIImage *snapshot = [gridView imageForViewWithScale:1.0f];
    snapshotBeforeRotation = [[UIImageView alloc] initWithImage:snapshot];
    snapshotBeforeRotation.frame = gridView.frame;
    snapshotBeforeRotation.contentMode = UIViewContentModeCenter;
    [self.view insertSubview:snapshotBeforeRotation aboveSubview:gridView];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (!snapshotBeforeRotation) {
        return;
    }
    
    frameAfterRotation = gridView.frame;
    
    [UIView setAnimationsEnabled:NO];
    
    [self.gridView centerIndex:centeredIndex];
    
    UIImage *snapshot = [gridView imageForViewWithScale:1.0f];
    snapshotAfterRotation = [[UIImageView alloc] initWithImage:snapshot];
    snapshotAfterRotation.frame = gridView.frame;
    snapshotAfterRotation.contentMode = UIViewContentModeCenter;
    [snapshotAfterRotation setFramePreservingHeight:frameBeforeRotation];
    
    [UIView setAnimationsEnabled:YES];
    
    if (snapshotAfterRotation.image.size.height > snapshotBeforeRotation.image.size.height) {
        snapshotAfterRotation.alpha = 0.0f;
        [self.view insertSubview:snapshotAfterRotation aboveSubview:snapshotBeforeRotation];
        snapshotAfterRotation.alpha = 1.0f;
    } else {
        [self.view insertSubview:snapshotAfterRotation belowSubview:snapshotBeforeRotation];
        snapshotBeforeRotation.alpha = 0.0f;
    }
    
    snapshotAfterRotation.frame = frameAfterRotation;
    [snapshotBeforeRotation setFramePreservingHeight:frameAfterRotation];
    gridView.hidden = YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (!snapshotBeforeRotation) {
        return;
    }
    
    [snapshotAfterRotation removeFromSuperview];
    [snapshotBeforeRotation removeFromSuperview];
    snapshotBeforeRotation = nil;
    snapshotAfterRotation = nil;
    gridView.hidden = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (editingThumbnail_) {
        [editingThumbnail_ stopEditing];
    }

    return YES;
}

#pragma mark -
#pragma mark Camera

- (void) importFromCamera:(id)sender
{
	UIImagePickerController *controller = nil;
    
    if (![self.currentPopoverViewController isKindOfClass:[UIImagePickerController class]]) {
        controller = [[UIImagePickerController alloc] init];
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        controller.delegate = self;
    }
    
    [self showController:controller from:sender];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo
{
    [self dismissPopoverAnimated:NO];
    [[WDPaintingManager sharedInstance] createNewPaintingWithImage:image];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissPopoverAnimated:NO];
}

@end

