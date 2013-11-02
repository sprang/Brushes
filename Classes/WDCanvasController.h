//
//  WDCanvasController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import "WDActionNameView.h"
#import "WDActionSheet.h"
#import "WDBar.h"
#import "WDDocumentReplay.h"
#import <MessageUI/MFMailComposeViewController.h>

typedef enum {
    WDInterfaceModeHidden, // all adornments are hidden
    WDInterfaceModeLoading,   // only progress indicator and top bar
    WDInterfaceModePlay, // play button, unlock slider and top bar
    WDInterfaceModeEdit // brush control, bottom bar and top bar
} WDInterfaceMode;

@class WDActionNameView;
@class WDArtStoreController;
@class WDBarColorWell;
@class WDBarSlider;
@class WDCanvas;
@class WDColorBalanceController;
@class WDColorPickerController;
@class WDColorWell;
@class WDDocument;
@class WDHueSaturationController;
@class WDLayerController;
@class WDLobbyController;
@class WDMenu;
@class WDMenuItem;
@class WDPainting;
@class WDProgressView;
@class WDUnlockView;

@interface WDCanvasController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate,
                                                    MFMailComposeViewControllerDelegate, UIPopoverControllerDelegate,
                                                        WDActionSheetDelegate, WDDocumentReplayDelegate, WDActionNameViewDelegate>
{
    WDBarItem           *album_;
    WDBarItem           *undo_;
    WDBarItem           *redo_;
    WDBarItem           *gear_;
    WDBarItem           *layer_;
    WDColorWell         *colorWell_;
    WDBarSlider         *brushSlider_;
    
    WDMenu              *gearMenu_;
    WDMenu              *actionMenu_;
    WDMenu              *visibleMenu_; // pointer to currently active menu
    
    UIPopoverController *popoverController_;
    
    WDLayerController   *layerController_;
    WDLobbyController   *lobbyController_;

    WDHueSaturationController   *hueController_;
    WDColorBalanceController   *balanceController_;
}

@property (nonatomic) WDDocument *document;
@property (nonatomic, strong) WDDocumentReplay *replay;
@property (weak, nonatomic, readonly) WDPainting *painting;
@property (nonatomic) NSDictionary *canvasSettings;

@property (nonatomic, readonly) WDCanvas *canvas;

@property (nonatomic) UINavigationController *brushController;
@property (nonatomic, strong) WDColorPickerController *colorPickerController;

@property (nonatomic) WDActionSheet *shareSheet;
@property (nonatomic) WDActionSheet *gearSheet;

@property (nonatomic, weak) WDBar *topBar;
@property (nonatomic, weak) WDBar *bottomBar;
@property (nonatomic) WDUnlockView *unlockView;
@property (nonatomic) UIButton *playButton;
@property (nonatomic) WDProgressView *progressIndicator;
@property (nonatomic) NSArray *editingTopBarItems;
@property (nonatomic) BOOL popoverVisible;

@property (nonatomic, readonly) BOOL runningOnPhone;
@property (nonatomic) WDInterfaceMode interfaceMode;
@property (nonatomic, readonly) BOOL interfaceHidden;
@property (nonatomic) BOOL hasAppearedBefore;
@property (nonatomic) BOOL needsToResetInterfaceMode;
@property (nonatomic) NSNumber *replayScale;

@property (nonatomic) WDActionNameView *actionNameView;
@property (nonatomic) BOOL wasPlayingBeforeRotation;

@property (nonatomic) WDArtStoreController *artStoreController;

- (void) updateTitle;
- (void) hidePopovers;

- (BOOL) shouldDismissPopoverForClassController:(Class)controllerClass insideNavController:(BOOL)insideNav;
- (void) showController:(UIViewController *)controller fromBarButtonItem:(UIBarButtonItem *)barButton animated:(BOOL)animated;
- (UIPopoverController *) runPopoverWithController:(UIViewController *)controller from:(id)sender;

- (void) validateMenuItem:(WDMenuItem *)item;
- (void) validateVisibleMenuItems;

- (void) undoStatusDidChange:(NSNotification *)aNotification;

- (UIImage *) layerImage;

- (void) showInterface;
- (void) hideInterface;

- (void) oneTap:(UITapGestureRecognizer *)recognizer;

- (void) undo:(id)sender;
- (void) redo:(id)sender;

@end

