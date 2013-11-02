//
//  WDColorSourceView.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDAppDelegate.h"
#import "WDColorSourceView.h"
#import "WDDragChip.h"
#import "WDUtilities.h"
#import "UIView+Additions.h"

#define kChipSize				50
#define kChipVerticalOffset		1.25

@implementation WDColorSourceView

@synthesize dragChip = dragChip_;
@synthesize lastTarget = lastTarget_;
@synthesize moved = moved_;

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (!self) {
        return nil;
    }
    
    self.exclusiveTouch = YES;
    
    return self;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    initialTap_ = [[touches anyObject] locationInView:self];
    moved_ = NO;
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self color]) {
        return;
    }
    
	WDAppDelegate *appDelegate = (WDAppDelegate *)[[UIApplication sharedApplication] delegate];
    UITouch *touch = [touches anyObject];
    CGPoint pt = [touch locationInView:self.superview];
    
    if (!moved_) {
        moved_ = YES;
        
        self.dragChip = [[WDDragChip alloc] initWithFrame:CGRectMake(0, 0, kChipSize, kChipSize)];
        self.dragChip.color = [self color];
        [appDelegate.window addSubview:self.dragChip];
    }
    
    CGPoint center = WDAddPoints(pt, CGPointMake(0, -kChipVerticalOffset * kChipSize));
    self.dragChip.sharpCenter = [self.superview convertPoint:center toView:appDelegate.window];
    self.dragChip.transform = WDTransformForOrientation([UIApplication sharedApplication].statusBarOrientation);
    
    id          newTarget = nil;
    UIWindow    *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIView      *target = [keyWindow hitTest:[touch locationInView:keyWindow] withEvent:event];
    
    if ([target respondsToSelector:@selector(dragMoved:colorChip:colorSource:)]) {
        [(id<WDColorDragging>)target dragMoved:touch colorChip:self.dragChip colorSource:self];
        newTarget = target;
    }
    
    if (lastTarget_ != newTarget) {
        [(id<WDColorDragging>)lastTarget_ dragExited];
        lastTarget_ = newTarget;
    }
}

- (void) chipAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    [self.dragChip removeFromSuperview];
    self.dragChip = nil;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.dragChip removeFromSuperview];
    self.dragChip = nil;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self color]) {
        return;
    }
    
	WDAppDelegate *appDelegate = (WDAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UITouch *touch = [touches anyObject];
    BOOL    accepted = NO;
    CGPoint flyLoc;
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIView *target = [keyWindow hitTest:[touch locationInView:keyWindow] withEvent:event];
    if ([target respondsToSelector:@selector(dragEnded:colorChip:colorSource:destination:)]) {
        accepted = [(id<WDColorDragging>)target dragEnded:touch colorChip:self.dragChip colorSource:self destination:&flyLoc];
    }
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(chipAnimationDidStop:finished:context:)];
    
	self.dragChip.alpha = 0;
    if (!accepted) {
		self.dragChip.center = [self convertPoint:initialTap_ toView:appDelegate.window];
    } else {
        self.dragChip.center = flyLoc;
        self.dragChip.transform = CGAffineTransformScale(self.dragChip.transform, 0.1f, 0.1f);
    }
    
    [self dragEnded];
    
    [UIView commitAnimations];
}

- (WDColor *) color {
    return nil;
}

- (void) dragEnded {
}

@end
