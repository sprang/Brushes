//
//  WDPaintingIterator.h
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


#import <Foundation/Foundation.h>

@class WDDocument;


@interface WDPaintingIterator : NSObject

@property (nonatomic, strong) NSArray *paintings;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, copy) void (^block)(WDDocument *);
@property (nonatomic, copy) void (^completed)(NSArray *paintings);

- (void) processNext;

@end
