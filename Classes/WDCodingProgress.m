//
//  WDCodingProgress.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDCodingProgress.h"

NSString *WDCodingProgressNotification = @"WDCodingProgressNotification";

@implementation WDCodingProgress {
    int completed_;
    float lastReported_;
    int total_;
}

@synthesize cancel;

- (void) setCompleted:(int)completed ofTotal:(int)total
{
    @synchronized(self) {
        if (completed != completed_ || total != total_) {
            completed_ = completed;
            total_ = total;
            if (self.progress > lastReported_) {
                [[NSNotificationCenter defaultCenter] postNotificationName:WDCodingProgressNotification object:self];
                lastReported_ = self.progress;
            }
        }
    }
}

- (int) completed
{
    return completed_;
}

- (void) setCompleted:(int)completed
{
    [self setCompleted:completed ofTotal:total_];
}

- (int) total
{
    return total_;
}

- (void) setTotal:(int)total
{
    [self setCompleted:completed_ ofTotal:total];
}

- (float) progress
{
    // the MAX function here prevents division by 0 and also prevents giving a really high percentage when hardly anything has been done
    return ((float) completed_) / MAX(total_, 100);
}

- (void) reset
{
    [self setCompleted:0 ofTotal:0];
    lastReported_ = 0;
}

- (void) complete
{
    [self setCompleted:MAX(total_, 100) ofTotal:total_];
}

@end
