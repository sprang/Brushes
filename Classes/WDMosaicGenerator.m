//
//  WDMosaicGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//
#import "WDBrush.h"
#import "WDMosaicGenerator.h"
#import "WDRandom.h"

@implementation WDMosaicGenerator

- (void) buildProperties
{
    WDProperty *density = [WDProperty property];
    density.title = NSLocalizedString(@"Density", @"Density");
    density.minimumValue = 2;
    density.maximumValue = 50;
    density.conversionFactor = 1;
    density.delegate = self;
    (self.rawProperties)[@"density"] = density;
    
    WDProperty *deviation = [WDProperty property];
    deviation.title = NSLocalizedString(@"Deviation", @"Deviation");
    deviation.minimumValue = 0.0;
    deviation.maximumValue = 1.0;
    deviation.percentage = YES;
    deviation.delegate = self;
    (self.rawProperties)[@"deviation"] = deviation;
}

- (WDProperty *) density
{
    return (self.rawProperties)[@"density"];
}

- (WDProperty *) deviation
{
    return (self.rawProperties)[@"deviation"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    size_t  width = self.baseDimension;
    
    int steps = self.density.value;
    float dim = (float) width / steps;
    CGRect box = CGRectMake(0, 0, dim, dim);
    
    for (float y = 0; y < steps; y++) {
        for (float x = 0; x < steps; x++) {
            box.origin = CGPointMake(x * dim, y * dim);
            float inset = (0.25 * dim) * [randomizer nextFloat] * self.deviation.value;
            
            CGContextSetGrayFillColor(ctx, [randomizer nextFloat], 1.0f);
            CGContextFillRect(ctx, CGRectInset(box, inset, inset));
        }
    }
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.2f;
    brush.angle.value = 0.0f;
    brush.spacing.value = 0.02;
    brush.rotationalScatter.value = 0.0f;
    brush.positionalScatter.value = 0.5f;
    brush.angleDynamics.value = 1.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 1.0f;
}

@end
