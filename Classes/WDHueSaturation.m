//
//  WDHueSaturation.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDHueSaturation.h"

@implementation WDHueSaturation

@synthesize hueShift;
@synthesize saturationShift;
@synthesize brightnessShift;

+ (WDHueSaturation *) hueSaturationWithHue:(float)hueShift saturation:(float)saturationShift brightness:(float)brightnessShift
{
    WDHueSaturation *hueSat = [[WDHueSaturation alloc] init];
    
    hueSat.hueShift = hueShift;
    hueSat.saturationShift = saturationShift;
    hueSat.brightnessShift = brightnessShift;
    
    return hueSat;    
}

- (BOOL) isEqual:(WDHueSaturation *)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    return (self.hueShift == object.hueShift && self.saturationShift == object.saturationShift && self.brightnessShift == object.brightnessShift);
}

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep
{
    [coder encodeFloat:self.hueShift forKey:@"hue"];
    [coder encodeFloat:self.saturationShift forKey:@"saturation"];
    [coder encodeFloat:self.brightnessShift forKey:@"brightness"];
}

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    self.hueShift = [decoder decodeFloatForKey:@"hue"];
    self.saturationShift = [decoder decodeFloatForKey:@"saturation"];
    self.brightnessShift = [decoder decodeFloatForKey:@"brightness"];
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@: %f; %f; %f", [super description], hueShift, saturationShift, brightnessShift];
}

@end
