//
//  WDDecoder.h
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

#import <Foundation/Foundation.h>

@class WDCodingProgress;
@protocol WDDataProvider;

@protocol WDDecoder <NSObject>

- (NSMutableArray *) decodeArrayForKey:(NSString *)key;
- (NSMutableArray *) decodeArrayForKey:(NSString *)key defaultTo:(NSMutableArray *)deft;

- (BOOL) decodeBooleanForKey:(NSString *)key;
- (BOOL) decodeBooleanForKey:(NSString *)key defaultTo:(BOOL)deft;

- (UIColor *) decodeColorForKey:(NSString *)key;
- (UIColor *) decodeColorForKey:(NSString *)key defaultTo:(UIColor *)deft;

- (NSData *) decodeDataForKey:(NSString *)key;
- (NSData *) decodeDataForKey:(NSString *)key defaultTo:(NSData *)deft;

- (id<WDDataProvider>) decodeDataProviderForKey:(NSString *)key;
- (id<WDDataProvider>) decodeDataProviderForKey:(NSString *)key defaultTo:(id<WDDataProvider>)deft;

- (NSMutableDictionary *) decodeDictionaryForKey:(NSString *)key;
- (NSMutableDictionary *) decodeDictionaryForKey:(NSString *)key defaultTo:(NSMutableDictionary *)deft;

- (float) decodeFloatForKey:(NSString *)key;
- (float) decodeFloatForKey:(NSString *)key defaultTo:(float)deft;

- (int) decodeIntegerForKey:(NSString *)key;
- (int) decodeIntegerForKey:(NSString *)key defaultTo:(int)deft;

- (id) decodeObjectForKey:(NSString *)key;
- (id) decodeObjectForKey:(NSString *)key defaultTo:(id)deft;

- (CGPoint) decodePointForKey:(NSString *)key;
- (CGPoint) decodePointForKey:(NSString *)key defaultTo:(CGPoint)deft;

- (CGRect) decodeRectForKey:(NSString *)key;
- (CGRect) decodeRectForKey:(NSString *)key defaultTo:(CGRect)deft;

- (CGSize) decodeSizeForKey:(NSString *)key;
- (CGSize) decodeSizeForKey:(NSString *)key defaultTo:(CGSize)deft;

- (CGAffineTransform) decodeTransformForKey:(NSString *)key;
- (CGAffineTransform) decodeTransformForKey:(NSString *)key defaultTo:(CGAffineTransform)deft;

- (NSString *) decodeStringForKey:(NSString *)key;
- (NSString *) decodeStringForKey:(NSString *)key defaultTo:(NSString *)deft;

- (WDCodingProgress *) progress;
- (void) dispatch:(dispatch_block_t)task;
- (void) waitForQueue;

@end
