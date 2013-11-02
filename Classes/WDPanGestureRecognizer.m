//
//  WDPanGestureRecognizer.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDPanGestureRecognizer.h"

@interface UIPanGestureRecognizer (WDSubclass)
- (void)touchesBegan:(NSSet *)inTouches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)inTouches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)inTouches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)inTouches withEvent:(UIEvent *)event;
@end

@implementation WDPanGestureRecognizer

@synthesize touches;

- (void)touchesBegan:(NSSet *)inTouches withEvent:(UIEvent *)event
{
    touches = [inTouches copy];
    [super touchesBegan:inTouches withEvent:event];
}
     
- (void)touchesMoved:(NSSet *)inTouches withEvent:(UIEvent *)event
{
    touches = [inTouches copy];
    [super touchesMoved:inTouches withEvent:event];
}

- (void)touchesEnded:(NSSet *)inTouches withEvent:(UIEvent *)event
{
    touches = [inTouches copy];
    [super touchesEnded:inTouches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)inTouches withEvent:(UIEvent *)event
{
    touches = [inTouches copy];
    [super touchesCancelled:inTouches withEvent:event];
}
     
@end
