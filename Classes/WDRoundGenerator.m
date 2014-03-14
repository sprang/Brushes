//
//  WDRoundGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDRoundGenerator.h"

@implementation WDRoundGenerator

- (void) buildProperties
{
    WDProperty *hardness = [WDProperty property];
    hardness.title = NSLocalizedString(@"Hardness", @"Hardness");
    hardness.delegate = self;
    (self.rawProperties)[@"hardness"] = hardness;
}

- (BOOL) canRandomize
{
    return NO;
}

- (WDProperty *) hardness
{
    return (self.rawProperties)[@"hardness"];
}

- (void) renderStamp:(CGContextRef)context randomizer:(WDRandom *)randomizer
{
    CGContextDrawImage(context, self.baseBounds, [self radialFadeWithHardness:self.hardness.value]);
}

@end
