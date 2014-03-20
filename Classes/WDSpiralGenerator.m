//
//  WDSpiralGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDSpiralGenerator.h"
#import "WDUtilities.h"
#import "WDRandom.h"

@implementation WDSpiralGenerator

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

- (void) drawSpiralAtPoint:(CGPoint)center radius:(float)radius inContext:(CGContextRef)ctx randomizer:(WDRandom *)random
{ 
    int         segments = 15;
    float       decay = 80;
    float       b = 1.0f - (decay / 100.f);
    float       a = radius / pow(M_E, b * segments * M_PI_4);
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPoint lastOut = CGPointZero;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, center.x, center.y);
    transform = CGAffineTransformRotate(transform, [random nextFloat] * M_PI * 2);
    
    for (int segment = 0; segment <= segments; segment++) {
        float t = segment * M_PI_4;
        float f = a * pow(M_E, b * t);
        float x = f * cos(t);
        float y = f * sin(t);
        
        CGPoint P3 = CGPointMake(x, y);
        
        // derivative
        float t0 = t - M_PI_4;
        float deltaT = (t - t0) / 3;
        
        float xPrime = a*b*pow(M_E,b*t)*cos(t) - a*pow(M_E,b*t)*sin(t);
        float yPrime = a*pow(M_E,b*t)*cos(t) + a*b*pow(M_E,b*t)*sin(t);
        
        CGPoint P2 = WDSubtractPoints(P3, WDMultiplyPointScalar(CGPointMake(xPrime, yPrime), deltaT));
        CGPoint P1 = WDAddPoints(P3, WDMultiplyPointScalar(CGPointMake(xPrime, yPrime), deltaT));
        
        if (CGPathIsEmpty(pathRef)) {
            CGPathMoveToPoint(pathRef, &transform, P3.x, P3.y);
        } else {
            CGPathAddCurveToPoint(pathRef, &transform, lastOut.x, lastOut.y, P2.x, P2.y, P3.x, P3.y);
        }
        lastOut = P1;
    }
    
    CGContextAddPath(ctx, pathRef);
    CGContextSetGrayStrokeColor(ctx, [random nextFloat], 1.0f);
    CGContextSetLineWidth(ctx, [random nextFloat] * 9 + 1);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextStrokePath(ctx);
    CGPathRelease(pathRef);
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    float dim = self.baseDimension - 20;
    
    for (int i = 0; i < self.density.value; i++) {
        CGPoint center = CGPointMake(20 + [randomizer nextFloat] * dim, 20 + [randomizer nextFloat] * dim);
        
        float radius = MIN(center.x, self.baseDimension - center.x);
        radius = MIN(radius, MIN(center.y, self.baseDimension - center.y));
        radius -= 2;
        [self drawSpiralAtPoint:center radius:radius inContext:ctx randomizer:randomizer];
    }
}

@end
