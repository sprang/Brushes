//
//  WDColorComparator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "WDColorComparator.h"
#import "WDUtilities.h"
#import "WDColor.h"

@implementation WDColorComparator

@synthesize target, action, tappedColor;
@synthesize initialColor = initialColor_;
@synthesize currentColor = currentColor_;

- (void) computeCircleRects
{
    CGRect  bounds = CGRectInset([self bounds], 1, 1);
    
    leftCircle_ = bounds;
    leftCircle_.size.width /= 2;
    leftCircle_.size.height /= 2;
    
    float inset = floorf(bounds.size.width * 0.125f);
    rightCircle_ = CGRectInset(bounds, inset, inset);
    rightCircle_ = CGRectOffset(rightCircle_, inset, inset);
}

- (void) buildInsetShadowView
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0f);
    
    CGContextRef    ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);
    
    // paint the left shadowed circle
    [self insetCircleInRect:leftCircle_ context:ctx];
    
    // knock out a hole for the right shadowed circle
    [[UIColor whiteColor] set];
    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    CGContextFillEllipseInRect(ctx, CGRectInset(rightCircle_,-3,-3));
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    // paint the right shadowed circle
    [self insetCircleInRect:CGRectInset(rightCircle_,1,1) context:ctx];
    
    CGContextRestoreGState(ctx);
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:result];
    [self addSubview:imageView];
}

- (void) awakeFromNib 
{
    initialColor_ = [WDColor whiteColor];
    currentColor_ = [WDColor whiteColor];
    
    [self computeCircleRects];
    [self buildInsetShadowView];
    
    self.backgroundColor = nil;
    self.opaque = NO;
}


- (void) insetCircleInRect:(CGRect)rect context:(CGContextRef)ctx
{
    CGContextSaveGState(ctx);
    CGContextAddEllipseInRect(ctx, rect);
    CGContextClip(ctx);
    
    CGContextSetShadow(ctx, CGSizeMake(0,4), 8);
    CGContextAddRect(ctx, CGRectInset(rect, -20, -20));
    CGContextAddEllipseInRect(ctx, CGRectInset(rect, -1, -1));
    CGContextEOFillPath(ctx);
    CGContextRestoreGState(ctx);
}

- (void) paintTransparentColor:(WDColor *)color inRect:(CGRect)rect
{
    CGContextRef    ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [path addClip];
    
    //WDDrawTransparencyDiamondInRect(ctx, rect);
    WDDrawCheckersInRect(ctx, rect, 8);
    [[color UIColor] set];
    CGContextFillRect(ctx, rect);
    CGContextRestoreGState(ctx);
}

- (void) drawRect:(CGRect)clip
{
    CGContextRef    ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);
    
    if (initialColor_.alpha < 1.0) {
        [self paintTransparentColor:initialColor_ inRect:leftCircle_];
    } else {
        [[initialColor_ opaqueUIColor] set];
        CGContextFillEllipseInRect(ctx, leftCircle_);
    }
    
    if (currentColor_.alpha < 1.0) {
        [self paintTransparentColor:currentColor_ inRect:rightCircle_];
    } else {
        [[currentColor_ opaqueUIColor] set];
        CGContextFillEllipseInRect(ctx, rightCircle_);
    }
    
    [[UIColor whiteColor] set];
    CGContextSetLineWidth(ctx, 4);
    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    CGContextStrokeEllipseInRect(ctx, CGRectInset(rightCircle_,-1,-1));
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    CGContextRestoreGState(ctx);
}

- (WDColor *) color
{
    return self.tappedColor;
}

- (void) takeColorFrom:(id)sender
{
    [self setCurrentColor:(WDColor *)[sender color]];
}

- (void) setCurrentColor:(WDColor *)color
{
    currentColor_ = color;
    
    [self setNeedsDisplay];
}

- (void) setOldColor:(WDColor *)color
{
    initialColor_ = color;
    
    [self setNeedsDisplay];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    initialTap_ = [touch locationInView:self];
	
    CGRect upperLeft = [self bounds];
    upperLeft.size.width /=  2;
    upperLeft.size.height /= 2;
    
    self.tappedColor = CGRectContainsPoint(upperLeft, initialTap_) ? initialColor_ : currentColor_;
	
    [super touchesBegan:touches withEvent:event];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.moved) {
        [[UIApplication sharedApplication] sendAction:self.action to:self.target from:self forEvent:nil];
        return;
    }
    
    [super touchesEnded:touches withEvent:event];
}

@end
