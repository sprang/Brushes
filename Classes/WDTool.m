//
//  WDTool.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import "WDTool.h"

@implementation WDTool

@synthesize moved = moved_;

+ (WDTool *) tool
{
    return [[[self class] alloc] init];
}

- (NSString *) iconName
{
    return nil;
}

- (NSString *) landscapeIconName
{
    return nil;
}

- (id) icon
{
    return [UIImage imageNamed:self.iconName];
}

- (id) landscapeIcon
{
    return [UIImage imageNamed:self.landscapeIconName];
}

- (void) activated
{
}

- (void) deactivated
{
}

- (void) buttonDoubleTapped
{
}

- (void) gestureBegan:(UIGestureRecognizer *)recognizer
{
    moved_ = NO;
}

- (void) gestureMoved:(UIGestureRecognizer *)recognizer
{
    moved_ = YES;
}

- (void) gestureEnded:(UIGestureRecognizer *)recognizer
{
    
}

- (void) gestureCanceled:(UIGestureRecognizer *)recognizer
{
    
}

@end
