//
//  WDSplotchGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDPath.h"
#import "WDSplotchGenerator.h"
#import "WDRandom.h"

@implementation WDSplotchGenerator

- (void) buildProperties
{
    WDProperty *splotchiness = [WDProperty property];
    splotchiness.title = NSLocalizedString(@"Splotchiness", @"Splotchiness");
    splotchiness.minimumValue = 5;
    splotchiness.maximumValue = 50;
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
    WDPath *path = nil;
    
    // draw splotches
    for (int i = 0; i < self.splotchiness.value; i++) {
        path = [self splatInRect:[self randomRect:randomizer minPercentage:0.2f maxPercentage:1.0f] maxDeviation:0.1 randomizer:randomizer];
        CGContextAddPath(ctx, [path pathRef]);
        CGContextSetGrayFillColor(ctx, [randomizer nextFloatMin:0.5f max:1.0f], 0.5f);
        CGContextFillPath(ctx);
    }
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.25f;
    brush.angle.value = 0.0f;
    brush.spacing.value = 0.1f;
    brush.rotationalScatter.value = 1.0f;
    brush.positionalScatter.value = 0.2f;
    brush.angleDynamics.value = 0.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 0.75f;
}

@end
