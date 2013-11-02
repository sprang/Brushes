//
//  WDDictionaryDecoder.m
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

#import <AVFoundation/AVFoundation.h>
#import "WDCodingProgress.h"
#import "WDDataProvider.h"
#import "WDDictionaryDecoder.h"
#import "WDHueShifter.h"

@implementation WDDictionaryDecoder {
    NSDictionary *dict_;
    WDCodingProgress *progress_;
    dispatch_group_t dispatchGroup_;
    dispatch_queue_t dispatchQueue_;
}

- (id) initWithDictionary:(NSDictionary *)dict progress:(WDCodingProgress *)progress
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    dict_ = dict;
    progress_ = progress;
    
    return self;
}

- (void) dealloc
{
    if (dispatchQueue_) {
        dispatch_release(dispatchQueue_);
    }
    
    if (dispatchGroup_) {
        dispatch_release(dispatchGroup_);
    }
}

- (WDCodingProgress *) progress
{
    return progress_;
}

- (void) dispatch:(dispatch_block_t)task
{
    if (!dispatchQueue_) {
        dispatchQueue_ = dispatch_queue_create("com.taptrix.queue.WDDictionaryDecoder", NULL);
        dispatchGroup_ = dispatch_group_create();
    }
    dispatch_group_async(dispatchGroup_, dispatchQueue_, task);
}

- (void) waitForQueue
{
    if (dispatchGroup_) {
        dispatch_group_wait(dispatchGroup_, DISPATCH_TIME_FOREVER);
    }
}

- (id) objectForKey:(NSString *)key
{
    id o = dict_[key];
    return o == [NSNull null] ? nil : o;
}

- (NSMutableArray *) decodeArrayForKey:(NSString *)key
{
    return [self decodeArrayForKey:key defaultTo:nil];
}

- (NSMutableArray *) decodeArrayForKey:(NSString *)key defaultTo:(NSMutableArray *)deft
{
    id value = [self objectForKey:key];
    return value && [value isKindOfClass:[NSMutableArray class]] ? value : deft;
}

- (BOOL) decodeBooleanForKey:(NSString *)key
{
    return [self decodeBooleanForKey:key defaultTo:NO];
}

- (BOOL) decodeBooleanForKey:(NSString *)key defaultTo:(BOOL)deft
{
    id value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : deft;
}

- (UIColor *) decodeColorForKey:(NSString *)key
{
    return [self decodeColorForKey:key defaultTo:nil];
}

- (UIColor *) decodeColorForKey:(NSString *)key defaultTo:(UIColor *)deft
{
    id value = [self objectForKey:key];
    return value && [value isKindOfClass:[UIColor class]] ? value : deft;
}

- (NSData *) decodeDataForKey:(NSString *)key 
{
    return [self decodeDataForKey:key defaultTo:nil];
}

- (NSData *) decodeDataForKey:(NSString *)key defaultTo:(NSData *)deft
{
    id value = [self objectForKey:key];
    if ([value conformsToProtocol:@protocol(WDDataProvider)]) {
        return [value data];
    } else if (value) {
        return value;
    } else {
        return deft;
    }
}

- (id<WDDataProvider>) decodeDataProviderForKey:(NSString *)key 
{
    return [self decodeDataProviderForKey:key defaultTo:nil];
}

- (id<WDDataProvider>) decodeDataProviderForKey:(NSString *)key defaultTo:(NSData *)deft
{
    return [self decodeObjectForKey:key defaultTo:deft];
}

- (NSMutableDictionary *) decodeDictionaryForKey:(NSString *)key
{
    return [self decodeDictionaryForKey:key defaultTo:nil];
}

- (NSMutableDictionary *) decodeDictionaryForKey:(NSString *)key defaultTo:(NSMutableDictionary *)deft
{
    id value = [self objectForKey:key];
    return value && [value isKindOfClass:[NSMutableDictionary class]] ? value : deft;
}

- (float) decodeFloatForKey:(NSString *)key
{
    return [self decodeFloatForKey:key defaultTo:0.f];
}

- (float) decodeFloatForKey:(NSString *)key defaultTo:(float)deft
{
    id value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(floatValue)] ? [value floatValue] : deft;
}

- (int) decodeIntegerForKey:(NSString *)key
{
    return [self decodeIntegerForKey:key defaultTo:0];
}

- (int) decodeIntegerForKey:(NSString *)key defaultTo:(int)deft
{
    id value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(intValue)] ? [value intValue] : deft;
}

- (id) decodeObjectForKey:(NSString *)key
{
    return [self decodeObjectForKey:key defaultTo:nil];
}

- (id) decodeObjectForKey:(NSString *)key defaultTo:(id)deft
{
    id value = [self objectForKey:key];
    return value ?: deft;
}

- (CGPoint) decodePointForKey:(NSString *)key
{
    return [self decodePointForKey:key defaultTo:CGPointZero];
}

- (CGPoint) decodePointForKey:(NSString *)key defaultTo:(CGPoint)deft
{
    NSValue *value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(CGPointValue)] ? [value CGPointValue] : deft;
}

- (CGRect) decodeRectForKey:(NSString *)key
{
    return [self decodeRectForKey:key defaultTo:CGRectZero];
}

- (CGRect) decodeRectForKey:(NSString *)key defaultTo:(CGRect)deft
{
    NSValue *value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(CGRectValue)] ? [value CGRectValue] : deft;
}

- (CGSize) decodeSizeForKey:(NSString *)key
{
    return [self decodeSizeForKey:key defaultTo:CGSizeZero];
}

- (CGSize) decodeSizeForKey:(NSString *)key defaultTo:(CGSize)deft
{
    NSValue *value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(CGSizeValue)]? [value CGSizeValue] : deft;
}

- (NSString *) decodeStringForKey:(NSString *)key
{
    return [self decodeStringForKey:key defaultTo:nil];
}

- (NSString *) decodeStringForKey:(NSString *)key defaultTo:(NSString *)deft
{
    id value = [self objectForKey:key];
    return value && [value isKindOfClass:[NSString class]] ? value : deft;
}

- (CGAffineTransform) decodeTransformForKey:(NSString *)key
{
    return [self decodeTransformForKey:key defaultTo:CGAffineTransformIdentity];
}

- (CGAffineTransform) decodeTransformForKey:(NSString *)key defaultTo:(CGAffineTransform)deft
{
    NSValue *value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(CGAffineTransformValue)] ? [value CGAffineTransformValue] : deft;
}

@end
