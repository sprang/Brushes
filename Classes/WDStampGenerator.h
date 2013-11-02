//
//  WDStampGenerator.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDCoding.h"
#import "WDProperty.h"

@class WDBrush;
@class WDPath;
@class WDRandom;

@protocol WDGeneratorDelegate;

@interface WDStampGenerator : NSObject<WDPropertyDelegate, NSCopying, WDCoding>

@property (nonatomic) unsigned int seed;
@property (nonatomic) CGSize size;
@property (nonatomic, readonly) float baseDimension;
@property (nonatomic, readonly) CGRect baseBounds;
@property (nonatomic, readonly) float scale;
@property (nonatomic) UIImage *stamp;
@property (nonatomic) UIImage *smallStamp;
@property (weak, nonatomic, readonly) UIImage *preview;
@property (weak, nonatomic, readonly) UIImage *bigPreview;
@property (weak, nonatomic, readonly) NSArray *properties;
@property (nonatomic, readonly) NSMutableDictionary *rawProperties;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic) UInt8 blurRadius;
@property (nonatomic, readonly) BOOL canRandomize;

@property (nonatomic, weak) id<WDGeneratorDelegate> delegate;

+ (WDStampGenerator *) generator;

- (void) resetSeed;
- (void) randomize;
- (void) buildProperties;

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer;
- (void) configureBrush:(WDBrush *)brush;

- (CGImageRef) radialFadeWithHardness:(float)hardness;
- (WDPath *) splatInRect:(CGRect)rect maxDeviation:(float)percentage randomizer:(WDRandom *)randomizer;
- (CGRect) randomRect:(WDRandom *)randomizer minPercentage:(float)minP maxPercentage:(float)maxP;

@end

@protocol WDGeneratorDelegate <NSObject>
- (void) generatorChanged:(WDStampGenerator *)generator;
@end
