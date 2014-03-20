//
//  WDBristleGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDBristleGenerator.h"
#import "WDUtilities.h"
#import "WDRandom.h"

@implementation WDBristleGenerator

- (void) buildProperties
{
    WDProperty *bristleDensity = [WDProperty property];
    bristleDensity.title = NSLocalizedString(@"Bristle Density", @"Bristle Density");
    bristleDensity.minimumValue = 0.01f;
    bristleDensity.delegate = self;
    (self.rawProperties)[@"bristleDensity"] = bristleDensity;
    
    WDProperty *bristleSize = [WDProperty property];
    bristleSize.title = NSLocalizedString(@"Bristle Size", @"Bristle Size");
    bristleSize.minimumValue = 0.01f;
    bristleSize.delegate = self;
    (self.rawProperties)[@"bristleSize"] = bristleSize;
}

- (WDProperty *) bristleDensity
{
    return (self.rawProperties)[@"bristleDensity"];
}

- (WDProperty *) bristleSize
{
    return (self.rawProperties)[@"bristleSize"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    size_t  width = self.baseDimension;
	size_t  height = self.baseDimension;
    CGRect  bounds = CGRectMake(0, 0, width, height);
    CGPoint center = WDCenterOfRect(bounds);
    
    int numBristles = self.bristleDensity.value * 980 + 20;
    int size = self.bristleSize.value * (self.size.width * 0.05) + 5;
    
    // make some bristles
    NSUInteger maxRadius = width / 2;
    
    for (int i = 0; i < numBristles; i++) {
        NSUInteger radius = [randomizer nextInt] % size;

        float tempMax = (maxRadius - (radius + 1));
        
        float n = [randomizer nextFloat];
                        
        float r = n * tempMax;
        float a = [randomizer nextFloat] * (M_PI * 2);
        float x = center.x + cos(a) * r;
        float y = center.y + sin(a) * r;
        
        CGContextSetGrayFillColor(ctx, [randomizer nextFloat], 1.0f);
        CGRect rect = CGRectMake(x - radius, y - radius, radius * 2, radius * 2);
        CGContextFillEllipseInRect(ctx, rect);
    }
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.25f;
    brush.angle.value = 0.0f;
    brush.spacing.value = 0.02f;
    brush.rotationalScatter.value = 1.0f;
    brush.positionalScatter.value = 1.0f;
    brush.angleDynamics.value = 0.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 0.0;
}

@end
