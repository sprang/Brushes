//
//  WDProgressView.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDProgressView.h"
#import "WDUtilities.h"

@interface WDPathView : UIView
@property (nonatomic) UIColor *color;
@property (nonatomic) UIBezierPath *path;
@end

@implementation WDPathView

@synthesize color;
@synthesize path;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = nil;
    
    return self;
}

- (void) setPath:(UIBezierPath *)inPath
{
    path = inPath;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [color set];
    [path fill];
}

@end

@implementation WDProgressView {
    UIImageView     *imageView;
    WDPathView      *pathView;
}

@synthesize progress;
@synthesize fancyStyle;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = nil;
    
    imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:imageView];
    pathView = [[WDPathView alloc] initWithFrame:self.bounds];
    [self addSubview:pathView];
    
    self.fancyStyle = NO;
    
    return self;
}

- (void) resetProgress
{
    self.alpha = 1.0;
    progress = 0.0f;
    [self updateShape];
}

- (void) setFancyStyle:(BOOL)inFancyStyle
{
    fancyStyle = inFancyStyle;
    pathView.color = [UIColor colorWithWhite:0.5f alpha:(fancyStyle ? 0.5f : 1.0f)];
}

- (void) setProgress:(float)inProgress
{
    float clamped = WDClamp(0, 1, inProgress);
    
    if (clamped > progress) {
        progress = clamped;
        [self updateShape];
    }
    
    if (progress == 1.0 && self.fancyStyle) {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0.0f;
        }];
    }
}

- (void) buildBackground
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGRect          bounds = CGRectInset(self.bounds, 1, 1);
    
    if (fancyStyle) {
        CGContextSaveGState(ctx);
        CGContextAddEllipseInRect(ctx, bounds);
        CGContextClip(ctx);
        
        CGContextAddEllipseInRect(ctx, bounds);
        CGContextAddEllipseInRect(ctx, CGRectInset(bounds, -20, -20));
        CGContextSetShadow(ctx, CGSizeZero, 8);
        CGContextEOFillPath(ctx);
        CGContextRestoreGState(ctx);
        
        [[UIColor whiteColor] set];
        CGContextSetLineWidth(ctx, 1.0f);
        CGContextStrokeEllipseInRect(ctx, bounds);
    } else {
        [[UIColor colorWithWhite:0.8f alpha:1.0f] set];
        CGContextFillEllipseInRect(ctx, bounds);
    }
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    imageView.image = result;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (!imageView.image) {
        [self buildBackground];
    }
}

- (void) updateShape
{
    CGRect          bounds = CGRectInset(self.bounds, 1, 1);
    CGPoint         center = WDCenterOfRect(bounds);
    UIBezierPath    *path = [UIBezierPath bezierPath];
    
    if (progress > 0) {
        [path moveToPoint:center];
        
        float startAngle = -(M_PI / 2);
        float endAngle = (M_PI * 2) * progress + startAngle;
        float inset = fancyStyle ? 5 : 3;
        float radius = CGRectGetWidth(bounds) / 2 - inset;
        
        [path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
        [path closePath];
    }
    
    pathView.path = path;
}

@end
