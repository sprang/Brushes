//
//  WDRectGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDBrush.h"
#import "WDRectGenerator.h"

@implementation WDRectGenerator

- (BOOL) canRandomize
{
    return NO;
}

- (void) buildProperties
{
    WDProperty *width = [WDProperty property];
    width.title = NSLocalizedString(@"Width", @"Width");
    width.minimumValue = 0.05;
    width.delegate = self;
    [self.rawProperties setValue:width forKey:@"width"]; 
    
    self.blurRadius = 5;
}

- (WDProperty *) width
{
    return (self.rawProperties)[@"width"];
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    CGRect rect = CGRectInset(self.baseBounds, self.blurRadius, self.blurRadius);
    
    float newWidth = CGRectGetWidth(rect) * self.width.value;
    float difference = CGRectGetWidth(rect) - newWidth;
    
    CGContextSetGrayFillColor(ctx, 1, 1);
    CGContextFillRect(ctx, CGRectInset(rect, difference / 2, 0));
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.15f;
    brush.angle.value = 90.0f;
    brush.spacing.value = 0.02;
    brush.rotationalScatter.value = 0.0f;
    brush.positionalScatter.value = 0.5f;
    brush.angleDynamics.value = 1.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 1.0f;
}

@end
