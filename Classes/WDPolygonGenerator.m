//
//  WDPolygonGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDPolygonGenerator.h"
#import "WDUtilities.h"

@implementation WDPolygonGenerator

- (BOOL) canRandomize
{
    return NO;
}

- (void) buildProperties
{
    WDProperty *sideCount = [WDProperty property];
    sideCount.title = NSLocalizedString(@"Number of Sides", @"Number of Sides");
    sideCount.minimumValue = 3;
    sideCount.maximumValue = 10;
    sideCount.conversionFactor = 1;
    sideCount.delegate = self;
    (self.rawProperties)[@"sideCount"] = sideCount;
}

- (WDProperty *) sideCount
{
    return (self.rawProperties)[@"sideCount"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    int             numSides = roundf(self.sideCount.value);
    CGPoint         center = WDCenterOfRect(self.baseBounds);
    float           outerRadius = self.baseDimension / 2 - 1;
    float           kappa = (M_PI * 2) / numSides;
    float           angle, x, y;
    float           offset = 0; // M_PI_2;
    
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    for(int i = 0; i < numSides; i ++) {
        angle = kappa * i + offset;
        x = cos(angle) * outerRadius;
        y = sin(angle) * outerRadius;
        
        if (CGPathIsEmpty(pathRef)) {
            CGPathMoveToPoint(pathRef, NULL, x + center.x, y + center.y);
        } else {
            CGPathAddLineToPoint(pathRef, NULL, x + center.x, y + center.y);
        }
    }
  
    CGPathCloseSubpath(pathRef);
    
    CGContextAddPath(ctx, pathRef);
    CGContextSetGrayFillColor(ctx, 1.0, 1.0f);
    CGContextFillPath(ctx);
    CGPathRelease(pathRef);
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 1.0f;
    brush.angle.value = 0.0f;
    brush.spacing.value = 1.0f;
    brush.rotationalScatter.value = 1.0f;
    brush.positionalScatter.value = 0.0f;
    brush.angleDynamics.value = 0.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 0.0f;
}

@end
