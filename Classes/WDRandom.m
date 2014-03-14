//
//  WDRandom.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDRandom.h"

//
// From http://en.wikipedia.org/wiki/Mersenne_Twister
//

@implementation WDRandom {
    UInt32 MT_[624];
    int ix_;
}

- (id) initWithSeed:(UInt32)seed
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    MT_[0] = seed;
    for (int i = 1; i < 624; i++) {
        MT_[i] = (1812433253 * (MT_[i-1] ^ (MT_[i-1] >> 30)) + i);
    }
    
    ix_ = 0;
    
    return self;
}

- (void) generateNumbers
{
    for (int i = 0; i < 624; i++) { 
        UInt32 y = (MT_[i] & 0x80000000) + (MT_[(i+1) % 624] & (0x7FFFFFFF));
        MT_[i] = MT_[(i + 397) % 624] ^ (y >> 1);
        
        if (y % 2 == 1) {
            MT_[i] = MT_[i] ^ 2567483615;
        }
    }
}

- (UInt32) nextInt
{
    if (ix_ == 0) {
        [self generateNumbers];
    }
    
    UInt32 y = MT_[ix_];
    
    y = y ^ (y >> 11);
    y = y ^ ((y << 7) & 2636928640);
    y = y ^ ((y << 15) & 4022730752);
    y = y ^ (y >> 18);
    
    ix_ = (ix_ + 1) % 624;
    return y;
}

- (float) nextFloat
{
    float r = [self nextInt] % 100000;
    return (r / 99999.0f);
}

- (float) nextFloatMin:(float)min max:(float)max
{
    return min + [self nextFloat] * (max - min);
}

- (float) nextSign
{
    return 1.0 - ([self nextInt] % 2) * 2;
}

@end

