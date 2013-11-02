//
//  UIViewAdditions.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "UIView+Additions.h"
#import "WDUtilities.h"

@implementation UIView (Additions)

- (void) setSharpCenter:(CGPoint)center
{
    CGRect frame = self.frame;
    
    frame.origin = WDSubtractPoints(center, CGPointMake(CGRectGetWidth(frame) / 2, CGRectGetHeight(frame) / 2));
    frame.origin = WDRoundPoint(frame.origin);
                              
    self.center = WDCenterOfRect(frame);
}

- (CGPoint) sharpCenter
{
    return self.center;
}

- (UIImage *) imageForViewWithScale:(float)scale
{
    //WDBeginTiming();
    
    UIGraphicsBeginImageContextWithOptions(self.frame.size, YES, scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, -self.bounds.origin.x, -self.bounds.origin.y);
    [self.layer renderInContext:ctx];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //WDEndTiming(@"imageForView");
    
    return result;
}

- (void) setFramePreservingHeight:(CGRect)frame
{
    float height = CGRectGetHeight(self.frame);
    frame.size.height = height;
    self.frame = frame;
}

@end
