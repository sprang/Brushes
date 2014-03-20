//
//  WDCrossHatchGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDCrossHatchGenerator.h"
#import "WDRandom.h"

@implementation WDCrossHatchGenerator

- (void) buildProperties
{
    WDProperty *density = [WDProperty property];
    density.title = NSLocalizedString(@"Density", @"Density");
    density.minimumValue = 1;
    density.maximumValue = 15;
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
    
    int hatches = self.density.value;
    float step = (float) width / (hatches + 1);
    float dev = 0;
    
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    for (float x = 1; x <= hatches; x++) {
        CGContextSetLineWidth(ctx, 5.0f + [randomizer nextFloat] * 5.0f);
        CGContextSetGrayStrokeColor(ctx, MAX(0.5, [randomizer nextFloat]), 1.0f);
        
        dev = (step / 2) * [randomizer nextFloat] * self.deviation.value;
        CGContextMoveToPoint(ctx, x*step + dev, 6);
        
        dev = (step / 2) * [randomizer nextFloat] * self.deviation.value;
        CGContextAddLineToPoint(ctx, x*step + dev, width - 6);
        CGContextStrokePath(ctx);
    }
    
    for (float y = 1; y <= hatches; y++) {
        CGContextSetLineWidth(ctx, 5.0f + [randomizer nextFloat] * 5.0f);
        CGContextSetGrayStrokeColor(ctx, MAX(0.5, [randomizer nextFloat]), 1.0f);
        
        dev = (step / 2) * [randomizer nextFloat] * self.deviation.value;
        CGContextMoveToPoint(ctx, 6, y*step + dev);
        
        dev = (step / 2) * [randomizer nextFloat] * self.deviation.value;
        CGContextAddLineToPoint(ctx, width - 6, y*step + dev);
        CGContextStrokePath(ctx);
    }
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.3f;
    brush.angle.value = 0.0f;
    brush.spacing.value = 0.02;
    brush.rotationalScatter.value = 0.0f;
    brush.positionalScatter.value = 0.5f;
    brush.angleDynamics.value = 1.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 1.0f;
}

@end
