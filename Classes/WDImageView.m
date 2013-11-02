//
//  WDImageView.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDImageView.h"

#define kCornerRadius 5

@implementation WDImageView

@synthesize image = image_;
@synthesize opacity = opacity_;
@synthesize scalingFactor = scalingFactor_;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }

    self.opaque = NO;
    self.backgroundColor = nil;
    self.opacity = 1.0f;
    self.scalingFactor = 1.0f;
    
    return self;
}


- (float) cornerRadius
{
    CGSize  size = self.frame.size;
    BOOL    shouldRoundCorners = (size.height > kCornerRadius * 2) && (size.width > kCornerRadius * 2);
    
    return (shouldRoundCorners ? kCornerRadius : 0);
}

- (void) setImage:(UIImage *)image
{
    image_ = image;
    
    CGRect frame = CGRectZero;
    frame.size = CGSizeMake(image.size.width * self.scalingFactor, image.size.height * self.scalingFactor);
    
    CGPoint center = self.center;
    self.frame = frame;
    self.center = center;
    
    CALayer *layer = self.layer;
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:self.cornerRadius];
    layer.shadowPath = bezierPath.CGPath;
    layer.shadowOpacity = 0.4;
    layer.shadowOffset = CGSizeZero;
    layer.shadowRadius = 3;
    
    [self setNeedsDisplay];
}

- (void) setOpacity:(float)opacity
{
    opacity_ = opacity;

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.cornerRadius];
    [bezierPath addClip];
    
    [[UIColor colorWithPatternImage:[UIImage imageNamed:@"brighter_small_checkers.png"]] set];
    CGContextFillRect(ctx, self.bounds);
    
    [self.image drawInRect:self.bounds blendMode:kCGBlendModeNormal alpha:self.opacity];
    
    CGContextRestoreGState(ctx);
}


@end
