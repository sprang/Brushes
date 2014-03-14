//
//  WDColorBalance.h
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

@interface WDColorBalance : NSObject <WDCoding>

@property (nonatomic, assign) float redShift;
@property (nonatomic, assign) float greenShift;
@property (nonatomic, assign) float blueShift;

+ (WDColorBalance *) colorBalanceWithRed:(float)redShift green:(float)greenShift blue:(float)blueShift;

@end
