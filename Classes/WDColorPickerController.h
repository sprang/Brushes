//
//  WDColorPickerController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import "WDSwatches.h"

@class WDBar;
@class WDColor;
@class WDColorComparator;
@class WDColorSquare;
@class WDColorWheel;
@class WDColorSlider;
@class WDMatrix;

@interface WDColorPickerController : UIViewController <WDSwatchesDelegate>

@property (nonatomic) WDColor *color;
@property (nonatomic) IBOutlet WDColorComparator *colorComparator;
@property (nonatomic) IBOutlet WDColorWheel *colorWheel;
@property (nonatomic) IBOutlet WDColorSquare *colorSquare;
@property (nonatomic) IBOutlet WDSwatches *swatches;
@property (nonatomic) IBOutlet WDColorSlider *alphaSlider;

// iPhone
@property (nonatomic) WDMatrix *matrix;
@property (nonatomic) IBOutlet UIView *firstCell;
@property (nonatomic) IBOutlet UIView *secondCell;

@property (nonatomic, weak) WDBar *bottomBar;

@property (nonatomic, weak) id delegate;

- (IBAction)dismiss:(id)sender;
- (void) setInitialColor:(WDColor *)color;

@end
