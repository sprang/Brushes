//
//  WDBlendModes.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBlendModes.h"

NSArray * WDBlendModes()
{
    static NSArray *modes = nil;
    
    if (!modes) {
        modes = @[@(WDBlendModeNormal),
                 @(WDBlendModeMultiply),
                 @(WDBlendModeScreen),
                 @(WDBlendModeExclusion)];
    }
    
    return modes;
}

NSArray * WDBlendModeDisplayNames()
{
    static NSArray *displayNames = nil;
    
    if (!displayNames) {
        displayNames = @[NSLocalizedString(@"Normal", @"Normal blending mode"),
                        NSLocalizedString(@"Multiply", @"Multiply blending mode"),
                        NSLocalizedString(@"Screen", @"Screen blending mode"),
                        NSLocalizedString(@"Exclude", @"Exclusion blending mode")];
    }
    
    return displayNames;
}

NSString * WDDisplayNameForBlendMode(WDBlendMode blendMode)
{
    static NSDictionary *map = nil;
    
    if (!map) {
        map = [NSDictionary dictionaryWithObjects:WDBlendModeDisplayNames() forKeys:WDBlendModes()];
    }
    
    return map[@(blendMode)];
}

WDBlendMode WDValidateBlendMode(WDBlendMode blendMode)
{
    NSNumber *test = @(blendMode);
    
    NSUInteger oldBlendModes[] = {
        WDBlendModeNormal,
        WDBlendModeMultiply,
        WDBlendModeScreen,
        WDBlendModeNormal, // old lighten mode
        WDBlendModeExclusion,
        WDBlendModeNormal, // old add mode
        WDBlendModeNormal // old subtract mode
    };
    
    if ([WDBlendModes() containsObject:test]) {
        return blendMode;
    } else if (blendMode < 7) {
        return (WDBlendMode) oldBlendModes[blendMode];
    } else {
        return WDBlendModeNormal;
    }
}

