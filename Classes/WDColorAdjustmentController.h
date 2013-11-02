//
//  WDColorBalanceController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDBlockingView;
@class WDCanvas;
@class WDPaintingController;
@class WDModalTitleBar;
@class WDPaletteBackgroundView;
@class WDPainting;

@interface WDColorAdjustmentController : UIViewController <UIGestureRecognizerDelegate> {
    IBOutlet WDModalTitleBar            *navBar_;
    IBOutlet WDPaletteBackgroundView    *background_;
    
    NSNumberFormatter                   *formatter_;
    
    WDBlockingView                      *blockingView_;
}

@property (nonatomic) NSString *defaultsName;
@property (nonatomic, readonly) NSNumberFormatter *formatter;
@property (nonatomic, weak) WDPainting *painting;
@property (nonatomic, weak) WDCanvas *canvas;

- (IBAction) cancel:(id)sender;
- (IBAction) accept:(id)sender;

- (void) bringOnScreenAnimated:(BOOL)animated;
- (void) runModalOverView:(UIView *)view;

- (void) resetShiftsToZero;

@end
