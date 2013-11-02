//
//  WDBrowserController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "WDImportController.h"
#import "WDGridView.h"
#import <DropboxSDK/DBRestClient.h>

@class WDActivityManager;
@class WDLabel;
@class WDPainting;
@class WDThumbnailView;

#define kMaximumThumbnails      18

@class WDBlockingView;
@class WDDocument;
@class WDMenu;

@interface WDBrowserController : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, WDGridViewDataSource,
                                                    DBRestClientDelegate, MFMailComposeViewControllerDelegate, WDImportControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>
{
    UIActionSheet           *deleteSheet_;
    
    NSMutableArray          *toolbarItems_;
    NSMutableArray          *editingToolbarItems_;
    
    UIPopoverController     *popoverController_;
    UIBarButtonItem         *selectItem_;
    UIBarButtonItem         *deleteItem_;
    UIBarButtonItem         *shareItem_;
    
    NSMutableSet            *selectedPaintings_;
    
    UIImagePickerController *pickerController_;
    
    DBRestClient            *restClient_;
    NSMutableSet            *filesBeingUploaded_;
    WDActivityManager       *activities_;

    WDBlockingView          *blockingView_;
    WDThumbnailView         *editingThumbnail_;
}

@property (nonatomic, readonly) BOOL runningOnPhone;
@property (nonatomic, readonly) NSInteger thumbnailDimension;
@property (nonatomic, weak) UIViewController *currentPopoverViewController;
@property (nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) WDGridView *gridView;

- (void) openDocument:(WDDocument *)document editing:(BOOL)editing;
- (void) showOpenFailure:(WDDocument *)document;

- (void) properlyEnableNavBarItems;

- (void) emailPaintings:(NSString *)format;
- (void) sendToDropbox:(NSString *)format;

- (void) createNewPainting:(CGSize)size;

@end
