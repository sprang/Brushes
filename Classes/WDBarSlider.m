//
//  WDBarSlider.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDActiveState.h"
#import "WDBrush.h"
#import "WDBarSlider.h"
#import "WDBrushSizeOverlay.h"
#import "WDUtilities.h"
#import "UIView+Additions.h"

#define kWDOverlayDimension     200
#define kWDOverlayPointerHeight 25

@interface WDBarSlider ()
@property (nonatomic) UILabel *label;
@property (nonatomic) float offset;
@property (nonatomic) BOOL moved;
@end

@implementation WDBarSlider

@synthesize minimumValue;
@synthesize maximumValue;
@synthesize value;
@synthesize thumbSize;
@synthesize offset;
@synthesize parentViewForOverlay;

// @private
@synthesize label;
@synthesize moved;
@synthesize overlay;

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = nil;
    self.contentMode = UIViewContentModeRedraw;
    
    self.thumbSize = 38;
    self.minimumValue = 1;
    self.maximumValue = 512;
    
    label = [[UILabel alloc] initWithFrame:self.bounds];
    label.opaque = NO;
    label.backgroundColor = nil;
    label.font = [UIFont boldSystemFontOfSize:13];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    
    CALayer *layer = self.layer;
    layer.shadowRadius = 1;
    layer.shadowOpacity = 0.9f;
    layer.shadowOffset = CGSizeZero;
    
    [self addSubview:label];
    
    return self;
}

- (float) percentage
{
    float delta = (maximumValue - minimumValue);
    float v = (value - minimumValue) * (8.0f / delta) + 1.0f;
    v = log(v);
    v /= 2.1972245773362196;
    
    return v;
}

- (void) computeValue:(CGPoint)pt
{
    CGRect  trackRect = CGRectInset(self.bounds, 1, 12);
    float   percentage;
    
    trackRect = CGRectInset(trackRect, self.thumbSize / 2, 0);
    percentage = (pt.x - CGRectGetMinX(trackRect)) / CGRectGetWidth(trackRect);
    percentage = WDClamp(0.0f, 1.0f, percentage);
    
    float delta = (maximumValue - minimumValue);
    self.value = delta * (exp(2.1972245773362196 * percentage) - 1.0f) / 8.0f + minimumValue;
    
    [self setNeedsDisplay];
}

- (CGRect) thumbRect
{
    CGRect  trackRect = CGRectInset(self.bounds, 1, 12);
    float   trackLength = CGRectGetWidth(trackRect) - self.thumbSize;
    float   centerX = (self.thumbSize / 2) + (trackLength * [self percentage]);
    CGRect  thumbRect = CGRectMake(centerX - (thumbSize / 2) + 1, CGRectGetMinY(trackRect), self.thumbSize, CGRectGetHeight(trackRect));
    
    return thumbRect;
}

- (void) drawRect:(CGRect)rect
{
    UIBezierPath *path = nil;
    BOOL isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? YES : NO;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    float radius = CGRectGetHeight(self.bounds);
    float lineWidth = isPhone ? 2 : 1;
    
    [[UIColor whiteColor] set];
    CGRect trackRect = CGRectInset(self.bounds, 1, 12);
    trackRect = isPhone ? CGRectInset(trackRect, 1, 5) : CGRectInset(trackRect, 0.5, 4.5);

    if (!isPhone) {
        [[UIColor colorWithWhite:1.0 alpha:0.1] set];
        
        CGRect leftRect = trackRect;
        leftRect.size.width = 15;
        path = [UIBezierPath bezierPathWithRoundedRect:leftRect cornerRadius:radius];
        [path fill];
        
        CGRect rightRect = trackRect;
        rightRect.origin.x = CGRectGetMaxX(trackRect) - 15;
        rightRect.size.width = 15;
        path = [UIBezierPath bezierPathWithRoundedRect:rightRect cornerRadius:radius];
        [path fill];
        
        [[UIColor whiteColor] set];
        
        // draw a minus inside the track bounds
        path = [UIBezierPath bezierPath];
        path.lineWidth = 2;
        float y = CGRectGetMidY(trackRect);
        [path moveToPoint:CGPointMake(6,y)];
        [path addLineToPoint:CGPointMake(12,y)];
        [path stroke];
        
        // draw a plus inside the track bounds
        path = [UIBezierPath bezierPath];
        path.lineWidth = 2;
        float x = CGRectGetMaxX(self.bounds) - 6;
        [path moveToPoint:CGPointMake(x,y)];
        [path addLineToPoint:CGPointMake(x - 6,y)];
        [path moveToPoint:CGPointMake(x-3,y-3)];
        [path addLineToPoint:CGPointMake(x - 3,y+3)];
        [path stroke];
    }
    
    path = [UIBezierPath bezierPathWithRoundedRect:trackRect cornerRadius:radius];
    path.lineWidth = lineWidth;
    [path stroke];
    
    CGRect thumbRect = [self thumbRect];
    
    // knockout a hole
    path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(thumbRect, -2, -2) cornerRadius:radius];
    CGContextSetBlendMode(ctx, kCGBlendModeClear);
    [path fill];
    
    thumbRect = isPhone ? CGRectInset(thumbRect, 1, 1) : CGRectInset(thumbRect, 0.5, 0.5);
    path = [UIBezierPath bezierPathWithRoundedRect:thumbRect cornerRadius:radius];
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    path.lineWidth = lineWidth;
    [[UIColor colorWithWhite:1.0 alpha:0.1] set];
    [path fill];
    [[UIColor whiteColor] set];
    [path stroke];
    
    label.frame = [self thumbRect];
}

- (void) setValue:(float)inValue
{
    value = WDClamp(minimumValue, maximumValue, inValue);
    
    label.text = [@((int) value) stringValue];
    label.frame = [self thumbRect];
    
    [self setNeedsDisplay];
}

- (CGRect) overlayFrame
{
    float   pointerHeight = parentViewForOverlay ? 0 : kWDOverlayPointerHeight;
   
    return CGRectMake(0, 0, kWDOverlayDimension, kWDOverlayDimension + pointerHeight);
}

- (void) showOverlayAtPoint:(CGPoint)pt
{    
    if (!self.overlay) {
        WDBrushSizeOverlay *view = [[WDBrushSizeOverlay alloc] initWithFrame:[self overlayFrame]];
        
        if (parentViewForOverlay) {
            view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            
            [parentViewForOverlay addSubview:view];
            view.sharpCenter = WDCenterOfRect(parentViewForOverlay.bounds);
        } else {
            [self addSubview:view];
        }
        
        self.overlay = view;
        [overlay setPreviewImage:[WDActiveState sharedInstance].brush.generator.bigPreview];
    }
    
    if (!parentViewForOverlay) {
        overlay.sharpCenter = CGPointMake(pt.x, CGRectGetMinY(self.bounds) - (kWDOverlayDimension + kWDOverlayPointerHeight) / 2.0f + 8);
    }
    
    [overlay setValue:self.value];
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint pt = [touch locationInView:self];
    offset = pt.x - CGRectGetMidX([self thumbRect]);
    
    moved = NO;
    
    return [super beginTrackingWithTouch:touch withEvent:event];
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint pt = [touch locationInView:self];
    
    if (!moved) {
        offset = pt.x - CGRectGetMidX([self thumbRect]);
        moved = YES;
    }
    
    pt.x -= offset;
    [self computeValue:pt];
    
    [self showOverlayAtPoint:WDCenterOfRect([self thumbRect])];
    
    return [super continueTrackingWithTouch:touch withEvent:event];
}

- (void) endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!moved) {
        self.value = (offset > 0) ? (value + 1) : (value - 1);
    }
    
    [self.overlay removeFromSuperview];
    self.overlay = nil;
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void) cancelTrackingWithEvent:(UIEvent *)event
{
    [self.overlay removeFromSuperview];
    self.overlay = nil;
}

@end
