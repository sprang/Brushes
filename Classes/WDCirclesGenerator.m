//
//  WDCirclesGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDCirclesGenerator.h"
#import "WDRandom.h"

@implementation WDCirclesGenerator

- (void) buildProperties
{
    WDProperty *density = [WDProperty property];
    density.title = NSLocalizedString(@"Density", @"Density");
    density.minimumValue = 1;
    density.maximumValue = 20;
    density.conversionFactor = 1;
    density.delegate = self;
    (self.rawProperties)[@"density"] = density;
}

- (WDProperty *) density
{
    return (self.rawProperties)[@"density"];
}

- (void) drawCircleAtPoint:(CGPoint)center radius:(float)radius width:(float)width inContext:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{ 
    CGRect rect = CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2);
    CGContextAddEllipseInRect(ctx, rect);
    
    CGContextSetGrayStrokeColor(ctx, MAX(0.5, [randomizer nextFloat]), 1.0f);
    CGContextSetLineWidth(ctx, width);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextStrokePath(ctx);
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    float dim;
    
    dim = self.baseDimension - 20;
    
    for (int i = 0; i < self.density.value; i++) {
        CGPoint center = CGPointMake(20 + [randomizer nextFloat] * dim, 20 + [randomizer nextFloat] * dim);
        
        float radius = MIN(center.x, self.baseDimension - center.x);
        float strokeWidth = [randomizer nextFloat] * 8 + 2;
        radius = MIN(radius, MIN(center.y, self.baseDimension - center.y));
        radius -= (strokeWidth / 2) + 1;
        [self drawCircleAtPoint:center radius:radius width:strokeWidth inContext:ctx randomizer:randomizer];
    }
}

@end
