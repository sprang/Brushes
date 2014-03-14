//
//  WDCoder
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

@class WDCodingProgress;
@class WDElement;
@class WDLayer;
@class WDPainting;

@protocol WDCoding;
@protocol WDDataProvider;

@protocol WDCoder

- (void) encodeArray:(NSArray *)array forKey:(NSString *)key;
- (void) encodeBoolean:(BOOL)boolean forKey:(NSString *)key;
- (void) encodeColor:(UIColor *)color forKey:(NSString *)key;
- (void) encodeCountedSet:(NSCountedSet *)set forKey:(NSString *)key;
- (void) encodeData:(NSData *)data forKey:(NSString *)key mediaType:(NSString *)mediaType;
- (void) encodeDataProvider:(id<WDDataProvider>)data forKey:(NSString *)key;
- (void) encodeDictionary:(NSDictionary *)dict forKey:(NSString *)key;
- (void) encodeFloat:(float)number forKey:(NSString *)key;
- (void) encodeInteger:(int)number forKey:(NSString *)key;
- (void) encodeObject:(id<WDCoding>)object forKey:(NSString *)key deep:(BOOL)deep;
- (void) encodePoint:(CGPoint)point forKey:(NSString *)key;
- (void) encodeRect:(CGRect)rect forKey:(NSString *)key;
- (void) encodeSize:(CGSize)size forKey:(NSString *)key;
- (void) encodeString:(NSString *)string forKey:(NSString *)key;
- (void) encodeTransform:(CGAffineTransform)transform forKey:(NSString *)key;
- (void) encodeUnknown:(id)object forKey:(NSString *)key;

- (WDCodingProgress *) progress;
- (void) dispatch:(dispatch_block_t)task;

- (id) copy:(id<WDCoding>)source deep:(BOOL)deep;
- (void) update:(id<WDCoding>)dest with:(id<WDCoding>)source;

@end
