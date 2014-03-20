//
//  NSArray+Additions.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

@interface NSArray (WDAdditions)

- (NSArray *) map:(id (^)(id obj))fn;
- (NSArray *) filter:(BOOL (^)(id obj))predicate;

- (NSArray *) arrayByRemovingDuplicateNeighbors;
+ (NSArray *) arrayByReplicating:(id<NSCopying>)obj times:(NSUInteger)times;

@end
