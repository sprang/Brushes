//
//  WDHueSaturation.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDCoding.h"

@interface WDHueSaturation : NSObject <WDCoding>

@property (nonatomic, assign) float hueShift;
@property (nonatomic, assign) float saturationShift;
@property (nonatomic, assign) float brightnessShift;

+ (WDHueSaturation *) hueSaturationWithHue:(float)hueShift saturation:(float)saturationShift brightness:(float)brightnessShift;

@end
