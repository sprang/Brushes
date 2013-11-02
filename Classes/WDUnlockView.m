//
//  WDUnlockView.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDUnlockView.h"

@interface WDUnlockView ()
@property (nonatomic) UILabel *label;
@end

@implementation WDUnlockView

@synthesize label;

+ (WDUnlockView *) unlockView
{
    WDUnlockView *slider = [[WDUnlockView alloc] initWithFrame:CGRectMake(0, 0, 280, 52)];
    return slider;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.opaque = NO;
    self.backgroundColor = nil;
    self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    CGRect labelFrame = self.bounds;
    labelFrame.size.height -= 2;
    
    label = [[UILabel alloc] initWithFrame:labelFrame];
    label.opaque = NO;
    label.backgroundColor = nil;
    label.text = NSLocalizedString(@"swipe here to paint", @"swipe here to paint");
    label.font = [UIFont systemFontOfSize:22.0];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    label.layer.shadowColor = [UIColor blackColor].CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowOpacity = 0.5f;
    label.layer.shadowRadius = 2;
    
    [self addSubview:label];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    swipe.delegate = self;
    swipe.direction = UISwipeGestureRecognizerDirectionLeft | UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:swipe];
    
    return self;
}

- (void) handleSwipe:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        // successful slide to the right, so send action
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef    ctx = UIGraphicsGetCurrentContext();
    CGRect          bounds = CGRectInset(self.bounds, -20, 0);
    UIImage         *fade = [UIImage imageNamed:@"unlockFade.png"];
    
    CGContextSaveGState(ctx);
    
    // create a fade on the ends
    CGContextClipToMask(ctx, self.bounds, fade.CGImage);
    
    [[UIColor colorWithWhite:0.0f alpha:0.05f] set];
    CGContextFillRect(ctx, bounds);
    
    // draw donut to create inner shadow
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectInset(bounds, -20, -20)];
    [path appendPath:[UIBezierPath bezierPathWithRect:bounds]];
    CGContextSetShadow(ctx, CGSizeZero, 8);
    path.usesEvenOddFillRule = YES;
    
    [[UIColor blackColor] set];
    [path fill];
    
    path = [UIBezierPath bezierPathWithRect:CGRectInset(bounds, 0, 0.5f)];
    [[UIColor whiteColor] set];
    [path stroke];
    
    CGContextRestoreGState(ctx);
}

@end
