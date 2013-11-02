//
//  WDUnlockSlider.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "UIView+Additions.h"
#import "WDUnlockSlider.h"
#import "WDUtilities.h"

#define kCornerRadius 15

@interface WDUnlockSlider ()
@property (nonatomic) UIImageView *thumb;
@property (nonatomic) UILabel *label;
@end

@implementation WDUnlockSlider

@synthesize label;
@synthesize thumb;

+ (WDUnlockSlider *) unlockSlider
{
    WDUnlockSlider *slider = [[WDUnlockSlider alloc] initWithFrame:CGRectMake(0, 0, 256, 56)];
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
    
    UIImage *thumbImage = [UIImage imageNamed:@"unlock_thumb.png"];
    
    CGRect labelFrame = self.bounds;
    labelFrame.origin.x += thumbImage.size.width;
    labelFrame.size.width -= thumbImage.size.width + 10;
    labelFrame.size.height -= 2;
    
    label = [[UILabel alloc] initWithFrame:labelFrame];
    label.opaque = NO;
    label.backgroundColor = nil;
    label.text = NSLocalizedString(@"slide to edit", @"slide to edit");
    label.font = [UIFont systemFontOfSize:24.0];
    label.textAlignment = UITextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    
    label.layer.shadowColor = [UIColor blackColor].CGColor;
    label.layer.shadowOffset = CGSizeZero;
    label.layer.shadowOpacity = 0.5f;
    label.layer.shadowRadius = 2;

    [self addSubview:label];
    
    thumb = [[UIImageView alloc] initWithImage:thumbImage];
    [self addSubview:thumb];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return CGRectContainsPoint(thumb.bounds, [touch locationInView:thumb]);
}

- (void) handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint center = self.thumb.center;
    float   buffer = thumb.image.size.width / 2;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // nothing special
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        // translate the thumb appropriately
        center.x += [gestureRecognizer translationInView:self].x;        
        center.x = WDClamp(buffer, CGRectGetWidth(self.bounds) - buffer, center.x);
        thumb.sharpCenter = center;
        
        // computer proper fade for label
        float percentage = (center.x - buffer) / ((CGRectGetWidth(self.bounds) - buffer) / 5.0f);
        label.alpha = 1.0f - percentage;
        
        [gestureRecognizer setTranslation:CGPointZero inView:self];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (thumb.center.x == CGRectGetWidth(self.bounds) - buffer) {
            // successful slide to the right, so send action
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        } else {
            // didn't make it, so reset the world
            [UIView animateWithDuration:0.1f animations:^{
                thumb.sharpCenter = CGPointMake(buffer, center.y);
                label.alpha = 1.0f;
            }];
        }
    }
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(ctx);
    
    // clip
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 1, 1)
                                                    cornerRadius:kCornerRadius];
    [path addClip];
    
    [[UIColor colorWithWhite:0.0f alpha:0.05f] set];
    CGContextFillRect(ctx, self.bounds);
    
    // draw donut to create inner shadow
    [[UIColor blackColor] set];
    CGContextAddRect(ctx, CGRectInset(self.bounds, -20, -20));
    path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:kCornerRadius];
    CGContextSetShadow(ctx, CGSizeZero, 8);
    path.usesEvenOddFillRule = YES;
    [path fill];
    
    CGContextRestoreGState(ctx);
    
    path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.5f, 0.5f) cornerRadius:kCornerRadius];
    [[UIColor colorWithWhite:1.0f alpha:0.5f] set];
    [path stroke];
}

@end
