//
//  WDBlendModes.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

typedef enum {
    WDBlendModeNormal = 'norm',
    WDBlendModeMultiply = 'mult',
    WDBlendModeScreen = 'scrn',
    WDBlendModeExclusion = 'excl',
} WDBlendMode;

NSArray * WDBlendModes();
NSArray * WDBlendModeDisplayNames();
NSString * WDDisplayNameForBlendMode(WDBlendMode blendMode);
WDBlendMode WDValidateBlendMode(WDBlendMode blendMode);
