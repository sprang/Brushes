//
//  WDZigZagGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDZigZagGenerator.h"

@implementation WDZigZagGenerator

- (BOOL) canRandomize
{
    return NO;
}

- (void) buildProperties
{
    WDProperty *density = [WDProperty property];
    density.title = NSLocalizedString(@"Density", @"Density");
    density.minimumValue = 2;
    density.maximumValue = 20;
    density.conversionFactor = 1;
    density.delegate = self;
    (self.rawProperties)[@"density"] = density;
}

- (WDProperty *) density
{
    return (self.rawProperties)[@"density"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    int num = self.density.value;
    float step = self.baseDimension / (num + 1);
    
    NSMutableArray *oddPoints = [NSMutableArray array];
    NSMutableArray *evenPoints = [NSMutableArray array];
    
    for (int x = 1; x <= num; x++) {
        [oddPoints addObject:[NSValue valueWithCGPoint:CGPointMake(x * step, step)]];
    }
    for (int y = 2; y <= num; y++) {
        [oddPoints addObject:[NSValue valueWithCGPoint:CGPointMake(step * num, y * step)]];
    }
    
    for (int y = 2; y <= num; y++) {
        [evenPoints addObject:[NSValue valueWithCGPoint:CGPointMake(step, y * step)]];
    }
    for (int x = 2; x <= num; x++) {
        [evenPoints addObject:[NSValue valueWithCGPoint:CGPointMake(x * step, step * num)]];
    }
    
    NSEnumerator *oddEnum = [oddPoints objectEnumerator];
    NSEnumerator *evenEnum = [evenPoints objectEnumerator];
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPoint a = [[oddEnum nextObject] CGPointValue];
    CGPathMoveToPoint(pathRef, NULL, a.x, a.y);
    
    NSValue *oddValue, *evenValue;
    while (oddValue = [oddEnum nextObject]) {
        evenValue = [evenEnum nextObject];
        
        a = [evenValue CGPointValue];
        CGPathAddLineToPoint(pathRef, NULL, a.x, a.y);
        
        a = [oddValue CGPointValue];
        CGPathAddLineToPoint(pathRef, NULL, a.x, a.y);
    }
    
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, self.baseBounds, [self radialFadeWithHardness:0.25]);
    
    CGContextAddPath(ctx, pathRef);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, step / 5);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetGrayStrokeColor(ctx, 1.0f, 1.0f);
    
    CGContextStrokePath(ctx);
    CGPathRelease(pathRef);
    CGContextRestoreGState(ctx);
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.25f;
    brush.angle.value = 0.0f;
    brush.spacing.value = 0.1f;
    brush.rotationalScatter.value = 1.0f;
    brush.positionalScatter.value = 0.0f;
    brush.angleDynamics.value = 0.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 0.0f;
}

@end
