//
//  WDRandom.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

@interface WDRandom : NSObject

- (id) initWithSeed:(UInt32)seed;
- (UInt32) nextInt;
- (float) nextFloat;
- (float) nextFloatMin:(float)min max:(float)max;
- (float) nextSign; // return -1 or 1;

@end
