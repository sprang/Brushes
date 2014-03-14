//
//  WDStarGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDStarGenerator.h"
#import "WDUtilities.h"

@implementation WDStarGenerator

- (BOOL) canRandomize
{
    return NO;
}

- (void) buildProperties
{
    WDProperty *pointCount = [WDProperty property];
    pointCount.title = NSLocalizedString(@"Number of Points", @"Number of Points");
    pointCount.minimumValue = 3;
    pointCount.maximumValue = 20;
    pointCount.conversionFactor = 1;
    pointCount.delegate = self;
    (self.rawProperties)[@"pointCount"] = pointCount;
}

- (WDProperty *) pointCount
{
    return (self.rawProperties)[@"pointCount"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    int             numPoints = roundf(self.pointCount.value);
    CGPoint         center = WDCenterOfRect(self.baseBounds);
    float           outerRadius = self.baseDimension / 2 - 1;
    float           kappa = (M_PI * 2) / numPoints;
    float           optimalRatio;
    float           innerRadius;
    float           angle, x, y;
    float           theta = M_PI / numPoints; // == (360 degrees / numPoints) / 2.0f
    float           offset = (numPoints % 2 == 0) ? 0 : M_PI_2;
    
    if (numPoints < 5) {
        optimalRatio = (1.0f / 5.0f);
    } else {
        optimalRatio = cos(kappa) / cos(kappa / 2);
        
        if (numPoints > 8) {
            optimalRatio *= (2.0 / 3.0f);
        }
    } 
    
    innerRadius = outerRadius * optimalRatio;
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    for(int i = 0; i < numPoints * 2; i += 2) {
        angle = theta * i + offset;
        x = cos(angle) * outerRadius;
        y = sin(angle) * outerRadius;
        
        if (CGPathIsEmpty(pathRef)) {
            CGPathMoveToPoint(pathRef, NULL, x + center.x, y + center.y);
        } else {
            CGPathAddLineToPoint(pathRef, NULL, x + center.x, y + center.y);
        }
        
        angle = theta * (i+1) + offset;
        x = cos(angle) * innerRadius;
        y = sin(angle) * innerRadius;
        
        CGPathAddLineToPoint(pathRef, NULL, x + center.x, y + center.y);
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
