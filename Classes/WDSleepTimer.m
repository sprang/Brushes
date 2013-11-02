//
//  WDSleepTimer.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDSleepTimer.h"
#import "WDUtilities.h"

static WDSleepTimer *instance;

@implementation WDSleepTimer {
    int sleepCount_;
    NSMutableSet *actives_;
}

// assuming this may get called by background tasks, thus the synchronization

+ (WDSleepTimer *) sharedInstance {
    @synchronized ([WDSleepTimer class]) {
        if (!instance) {
            instance = [[WDSleepTimer alloc] init];
        }
    }
    return instance;
}

- (id) init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    sleepCount_ = 0;
    actives_ = [NSMutableSet set];
    
    return self;
}

- (void) enableTimer:(id)active {
    @synchronized(self) {
        if (sleepCount_ > 0 && [actives_ containsObject:active]) {
            [actives_ removeObject:active];
            --sleepCount_;
            if (sleepCount_ == 0) {
                [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            }
            WDLog(@"Sleep timer level is now: %d", sleepCount_);
        }
    }
}

- (void) disableTimer:(id)active {
    @synchronized(self) {
        if (![actives_ containsObject:active]) {
            [actives_ addObject:active];
            ++sleepCount_;
            if (sleepCount_ == 1) {
                [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            }
            WDLog(@"Sleep timer level is now: %d", sleepCount_);
        }
   }
}

@end
