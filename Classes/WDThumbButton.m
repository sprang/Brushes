//
//  WDThumbButton
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDThumbButton.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"

@interface WDThumbButton ()
@property (nonatomic) UIImageView *markView;
@property (nonatomic) UIView *hightlightView;
@end

@implementation WDThumbButton

@synthesize image;
@synthesize target;
@synthesize action;
@synthesize pressed;
@synthesize marked;
@synthesize markView;
@synthesize hightlightView;

+ (WDThumbButton *) thumbButtonWithFrame:(CGRect)frame
{
    WDThumbButton *thumbButton = [[WDThumbButton alloc] initWithFrame:frame];
    return thumbButton;
}

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (!self) {
        return nil;
    }
    
    self.exclusiveTouch = YES;
    self.multipleTouchEnabled = NO;
    self.opaque = YES;
    self.backgroundColor = [UIColor whiteColor];

    return self;
}

- (void) setImage:(UIImage *)anImage
{
    image = anImage;
    
    self.layer.contents = (id) anImage.CGImage;
    self.layer.contentsGravity = @"resizeAspectFill";
    self.clipsToBounds = YES;
}

- (void) setMarked:(BOOL)inMarked
{
    if (marked == inMarked) {
        return;
    }
    
    marked = inMarked;
    
    if (!marked) {
        [markView removeFromSuperview];
        markView = nil;
    } else {
        if (!markView) {
            UIImage *checkmark = [UIImage relevantImageNamed:@"checkmark.png"];
            markView = [[UIImageView alloc] initWithImage:checkmark];
            [self addSubview:markView];
        }
        
        CGPoint center = CGPointMake(CGRectGetMaxX(self.bounds) - 12, CGRectGetMaxY(self.bounds) - 12);
        markView.sharpCenter = center;
    }
}

- (void) setPressed:(BOOL)inPressed
{
    if (pressed == inPressed) {
        return;
    }
    
    pressed = inPressed;
    
    if (!pressed) {
        [hightlightView removeFromSuperview];
        hightlightView = nil;
    } else {
        if (!hightlightView) {
            hightlightView = [[UIView alloc] initWithFrame:self.bounds];
            hightlightView.opaque = NO;
            hightlightView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.333f];
            [self addSubview:hightlightView];
        }
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.pressed = YES;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.pressed = NO;
    [[UIApplication sharedApplication] sendAction:self.action to:self.target from:self forEvent:event];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.pressed = NO;
}

@end
