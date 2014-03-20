//
//  WDVerticalBristleGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDVerticalBristleGenerator.h"
#import "WDRandom.h"

@implementation WDVerticalBristleGenerator

- (void) buildProperties
{
    WDProperty *bristleDensity = [WDProperty property];
    bristleDensity.title = NSLocalizedString(@"Bristle Density", @"Bristle Density");
    bristleDensity.minimumValue = 2;
    bristleDensity.maximumValue = 20;
    bristleDensity.conversionFactor = 1;
    bristleDensity.delegate = self;
    (self.rawProperties)[@"bristleDensity"] = bristleDensity;
    
    self.blurRadius = 5;
}

- (WDProperty *) bristleDensity
{
    return (self.rawProperties)[@"bristleDensity"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    size_t  width = self.baseDimension;
	size_t  height = self.baseDimension;
    size_t  halfWidth = width / 2;
    
    int steps = self.bristleDensity.value;
    float dim = (float) height / steps;
    CGRect box = CGRectMake(0, 0, dim, dim);
    
    for (float y = 0; y < steps; y++) {
        box.origin = CGPointMake(halfWidth - (dim / 2), y * dim);
        float inset = [randomizer nextFloat] * 0.1f * dim;
        
        CGContextSetGrayFillColor(ctx, MAX(0.25, [randomizer nextFloat]), 1.0f);
        CGContextFillEllipseInRect(ctx, CGRectInset(box, inset, inset));
    }
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.25f;
    brush.angle.value = 0.0f;
    brush.spacing.value = 0.02f;
    brush.rotationalScatter.value = 0.0f;
    brush.positionalScatter.value = 0.0f;
    brush.angleDynamics.value = 1.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 0.0f;
}

@end
