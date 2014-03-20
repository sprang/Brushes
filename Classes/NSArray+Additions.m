//
//  NSArray+Additions.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "NSArray+Additions.h"

@implementation NSArray (WDAdditions)

- (NSArray *) map:(id (^)(id obj))fn
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:self.count];
    
    for (id element in self) {
        [result addObject:fn(element)];
    }
    
    return result;
}

- (NSArray *) filter:(BOOL (^)(id obj))predicate
{
    NSMutableArray *result = [NSMutableArray array];
    
    for (id element in self) {
        if (predicate(element)) {
            [result addObject:element];
        }
    }
    
    return result;
}

- (NSArray *) arrayByRemovingDuplicateNeighbors
{
    NSMutableArray  *uniques = [NSMutableArray array];
    id              prev = nil;
    
    for (id obj in self) {
        if (!prev || ![obj isEqual:prev]) {
            [uniques addObject:obj];
        }
        
        prev = obj;
    }
    
    return uniques;
}

+ (NSArray *) arrayByReplicating:(id<NSCopying>)obj times:(NSUInteger)times
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (int i = 0; i < times; i++) {
        [array addObject:[obj copyWithZone:nil]];
    }
    
    return array;
}

@end
