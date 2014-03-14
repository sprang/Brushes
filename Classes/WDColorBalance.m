//
//  WDColorBalance.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDCoder.h"
#import "WDColorBalance.h"
#import "WDDecoder.h"

@implementation WDColorBalance

@synthesize redShift;
@synthesize greenShift;
@synthesize blueShift;

+ (WDColorBalance *) colorBalanceWithRed:(float)redShift green:(float)greenShift blue:(float)blueShift
{
    WDColorBalance *balance = [[WDColorBalance alloc] init];
    
    redShift /= 2.0;
    greenShift /= 2.0;
    blueShift /= 2.0;
    
    float average = (redShift + greenShift + blueShift) / 3.0f;
    redShift -= average;
    greenShift -= average;
    blueShift -= average;
    
    balance.redShift = redShift;
    balance.greenShift = greenShift;
    balance.blueShift = blueShift;
    
    return balance;
}

- (BOOL) isEqual:(WDColorBalance *)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return (self.redShift == object.redShift && self.blueShift == object.blueShift && self.greenShift == object.greenShift);
}

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep
{
    [coder encodeFloat:self.redShift forKey:@"red"];
    [coder encodeFloat:self.greenShift forKey:@"green"];
    [coder encodeFloat:self.blueShift forKey:@"blue"];
}

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    self.redShift = [decoder decodeFloatForKey:@"red"];
    self.greenShift = [decoder decodeFloatForKey:@"green"];
    self.blueShift = [decoder decodeFloatForKey:@"blue"];
}


- (NSString *) description
{
    return [NSString stringWithFormat:@"%@: %f; %f; %f", [super description], redShift, blueShift, greenShift];
}

@end
