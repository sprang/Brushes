//
//  WDLabel.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "WDLabel.h"

#define kLabelCornerRadius 9.0f

@implementation WDLabel

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    rect = CGRectInset(rect, 8.0f, 8.0f);
    CGContextSetShadow(ctx, CGSizeMake(0, 2), 4);
    
    [[UIColor colorWithWhite:0.0f alpha:0.5f] set];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:kLabelCornerRadius];
    [path fill];
    
    [[UIColor whiteColor] set];
    path.lineWidth = 2;
    [path stroke];
     
    [super drawRect:rect];
}

@end
