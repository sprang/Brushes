//
//  WDColorWheel.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDColor;
@class WDColorIndicator;

@interface WDColorWheel : UIControl {
    CGImageRef          wheelImage_;
    WDColorIndicator    *indicator_;
    CGPoint             value_;
}

@property (nonatomic) WDColor *color;
@property (nonatomic, readonly) int radius;
@property (nonatomic, assign) float hue;

@end
