//
//  WDSplatGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDPath.h"
#import "WDSplatGenerator.h"
#import "WDRandom.h"

@implementation WDSplatGenerator

- (void) buildProperties
{
    WDProperty *splotchiness = [WDProperty property];
    splotchiness.title = NSLocalizedString(@"Splotchiness", @"Splotchiness");
    splotchiness.minimumValue = 0;
    splotchiness.maximumValue = 25;
    splotchiness.conversionFactor = 1;
    splotchiness.delegate = self;
    (self.rawProperties)[@"splotchiness"] = splotchiness;
    
    self.blurRadius = 10;
}

- (WDProperty *) splotchiness
{
    return (self.rawProperties)[@"splotchiness"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    // draw base splat
    CGContextSetGrayFillColor(ctx, 1, 1);
    WDPath *path = [self splatInRect:self.baseBounds maxDeviation:0.1 randomizer:randomizer];
    CGContextAddPath(ctx, [path pathRef]);
    CGContextFillPath(ctx);
    
    // draw holes
    for (int i = 0; i < self.splotchiness.value; i++) {
        path = [self splatInRect:[self randomRect:randomizer minPercentage:0.3f maxPercentage:0.6f] maxDeviation:0.1 randomizer:randomizer];
        CGContextAddPath(ctx, [path pathRef]);
        CGContextSetGrayFillColor(ctx, 0, 1);
        CGContextFillPath(ctx);
    }
}

@end
