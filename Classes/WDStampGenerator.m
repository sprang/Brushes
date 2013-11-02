//
//  WDStampGenerator.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Accelerate/Accelerate.h>
#import "WDStampGenerator.h"
#import "UIImage+Additions.h"
#import "WD3DPoint.h"
#import "WDBezierNode.h"
#import "WDBrush.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDPath.h"
#import "WDRandom.h"
#import "WDUtilities.h"

#define kSmallStampSize 64
#define kBrushDimension 512

static NSString *WDSeedKey = @"seed";
static NSString *WDSizeKey = @"size";
static NSString *WDBlurRadiusKey = @"blurRadius";
static NSString *WDBlendModeKey = @"blendMode";
static NSString *WDUUIDKey = @"uuid";

@implementation WDStampGenerator

@synthesize seed;
@synthesize size;
@synthesize stamp;
@synthesize preview;
@synthesize smallStamp;
@synthesize properties;
@synthesize rawProperties;
@synthesize delegate;
@synthesize blurRadius;

+ (WDStampGenerator *) generator
{
    WDStampGenerator *generator = [[[self class] alloc] init];
    
    return generator;
}

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.seed = random();
    
    self.size = CGSizeMake(kBrushDimension, kBrushDimension);
    
    rawProperties = [NSMutableDictionary dictionary];
    [self buildProperties];
    
    return self;
}

- (BOOL) canRandomize
{
    return YES;
}

- (void) buildProperties
{
    
}

- (void) resetSeed
{
    self.seed = random();
    self.stamp = nil;
    self.smallStamp = nil;
    [delegate generatorChanged:self];
}

- (void) randomize
{
    // set random values for properties... this does not rely on our internal seed
    [self.properties makeObjectsPerformSelector:@selector(randomize)];
}

- (float) baseDimension
{
    return 512;
}

- (CGRect) baseBounds
{
    return CGRectMake(0, 0, self.baseDimension, self.baseDimension);
}

- (float) scale
{
    return self.size.width / self.baseDimension;
}

- (void) renderStamp:(CGContextRef)ctx randomizer:(WDRandom *)randomizer
{
    [NSException raise:@"Unimplemented method" format:@"renderStamp:randomizer: in %@", [self class]];
}

- (UIImage *) generateStamp
{
    size_t  width = self.size.width;
	size_t  height = self.size.height;
    size_t  rowByteSize = width;
    CGRect  bounds = CGRectMake(0, 0, width, height);
	void    *data = calloc(sizeof(UInt8), width * height);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
	CGContextRef context = CGBitmapContextCreate(data, width, height, 8, rowByteSize, colorspace, kCGImageAlphaNone);
    CGColorSpaceRelease(colorspace);
    
    // make our bitmap context the current context
    UIGraphicsPushContext(context);
    
    // fill black
    CGContextSetGrayFillColor(context, 0.0f, 1.0f);
    CGContextFillRect(context, bounds);
    
    WDRandom *random = [[WDRandom alloc] initWithSeed:self.seed];
    
    if (self.scale != 1.0) {
        CGContextSaveGState(context);
        CGContextScaleCTM(context, self.scale, self.scale);
        [self renderStamp:context randomizer:random];
        CGContextRestoreGState(context);
    } else {
        [self renderStamp:context randomizer:random];
    }
    
    if (self.blurRadius != 0) {
        uint32_t kernelDimension = self.blurRadius * 2 + 1; // must be odd
        void    *outData = calloc(sizeof(UInt8), width * height);
        size_t  rowBytes = width;
        
        vImage_Buffer src = { data, height, width, rowBytes };
        vImage_Buffer dest = { outData, height, width, rowBytes };
        vImage_Error err;
    
        err = vImageTentConvolve_Planar8(&src, &dest, NULL, 0, 0, kernelDimension, kernelDimension, 0, kvImageBackgroundColorFill);
        
        if (err != kvImageNoError) {
            // NSLog something
        }
        
        // put the data back
        memcpy(data, outData, width * height);
        free(outData);
    }
    
    // get image
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *result = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    UIGraphicsPopContext();
	CGContextRelease(context);
    free(data);
    
    return result;
}

- (UIImage *) stamp
{
    if (!stamp) {
        stamp = [self generateStamp];
    }
    
    return stamp;
}

- (UIImage *) smallStamp
{
    if (!smallStamp) {
        smallStamp = [self.stamp downsampleWithMaxDimension:kSmallStampSize * [UIScreen mainScreen].scale];
    }
    
    return smallStamp;
}

- (CGRect) bounds
{
    CGRect result = CGRectZero;
    result.size = self.size;
    
    return result;
}

- (UIImage *) previewWithImage:(UIImage *)imageMask brightness:(float)brightness
{
    size_t width = imageMask.size.width;
    size_t height = imageMask.size.height;
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, width*4, colorspace, kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorspace);
    CGContextClipToMask(ctx, CGRectMake(0, 0, width, height), imageMask.CGImage);
    CGContextSetGrayFillColor(ctx, brightness, 1.0f);
    CGContextFillRect(ctx, CGRectMake(0, 0, width, height));
    
    CGImageRef final = CGBitmapContextCreateImage(ctx);
    UIImage *result = [[UIImage alloc] initWithCGImage:final scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    CGImageRelease(final);
    CGContextRelease(ctx);
    
    return result;
}

- (UIImage *) preview
{
    return [self previewWithImage:self.smallStamp brightness:0.0f];
}

- (UIImage *) bigPreview
{
    return [self previewWithImage:self.stamp brightness:1.0f];
}

- (void) propertyChanged:(WDProperty *)property
{
    self.stamp = nil;
    self.smallStamp = nil;
    [delegate generatorChanged:self];
}

- (id) copyWithZone:(NSZone *)zone
{
    WDStampGenerator *copy = [[[self class] alloc] init];
    
    copy.seed = self.seed;
    
    NSEnumerator *copyProps = copy.properties.objectEnumerator;
    NSEnumerator *myProps = self.properties.objectEnumerator;
    
    WDProperty *src, *dst;
    
    while ((src = [myProps nextObject]) && (dst = [copyProps nextObject])) {
        dst.value = src.value;
    }
    
    return copy;
}

- (BOOL) isEqual:(WDStampGenerator *)object
{
    if (!object) {
        return NO;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    if (self.seed != object.seed) {
        return NO;
    }
    
    return [self.properties isEqual:object.properties];
}

- (NSArray *) properties
{
    NSMutableArray *values = [NSMutableArray array];
    NSArray *keys = [[rawProperties allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [values addObject:[rawProperties valueForKey:obj]];
    }];
    return values;
}

- (void) configureBrush:(WDBrush *)brush
{
    brush.intensity.value = 0.2f;
    brush.angle.value = 0;
    brush.spacing.value = 0.02;
    brush.rotationalScatter.value = 0.0f;
    brush.positionalScatter.value = 0.0f;
    brush.angleDynamics.value = 0.0f;
    brush.weightDynamics.value = 0.0f;
    brush.intensityDynamics.value = 0.0f;
}

#pragma mark -
#pragma mark WDCoding

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep
{
    [coder encodeInteger:self.seed forKey:WDSeedKey];
    [coder encodeSize:self.size forKey:WDSizeKey];
    [coder encodeInteger:self.blurRadius forKey:WDBlurRadiusKey];
    for (NSString *propertyName in self.rawProperties) {
        WDProperty *property = (self.rawProperties)[propertyName];
        [coder encodeFloat:property.value forKey:propertyName];
    }
}

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    self.seed = [decoder decodeIntegerForKey:WDSeedKey];
    self.size = [decoder decodeSizeForKey:WDSizeKey];
    self.blurRadius = [decoder decodeIntegerForKey:WDBlurRadiusKey];
    for (NSString *propertyName in self.rawProperties) {
        WDProperty *property = (self.rawProperties)[propertyName];
        float value = [decoder decodeFloatForKey:propertyName defaultTo:NAN];
        if (isnan(value)) {
            // for legacy files
            NSDictionary *dict = [decoder decodeDictionaryForKey:@"properties"];
            WDProperty *old = dict[propertyName];
            if (old) {
                property.value = old.value;
            }
        } else {
            property.value = value;
        }
    }
}

#pragma mark - Helpers for subclasses

- (CGImageRef) radialFadeWithHardness:(float)hardness
{
    static CGImageRef fadeImageRef = NULL;
    static float lastHardness = 0.0f;
    
    if (!fadeImageRef || lastHardness != hardness) {
        if (fadeImageRef) {
            CGImageRelease(fadeImageRef);
        }
        
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
        CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height, 8, self.size.width, colorspace, kCGImageAlphaNone);
        
        NSArray *colors = @[(__bridge id) [UIColor whiteColor].CGColor, (__bridge id) [UIColor blackColor].CGColor];
        const CGFloat locations[] = {0.0, 1.0};
        
        CGGradientRef gradientRef = CGGradientCreateWithColors(colorspace, (__bridge CFArrayRef) colors, locations);
        CGPoint center = CGPointMake(self.size.width / 2, self.size.height / 2);
        
        float maxRadius = self.size.width / 2;
        
        float hFactor = hardness * 0.99;
        CGGradientDrawingOptions options = kCGGradientDrawsBeforeStartLocation |kCGGradientDrawsAfterEndLocation;
        CGContextDrawRadialGradient(ctx, gradientRef, center, hFactor * maxRadius, center, maxRadius, options);
        
        fadeImageRef = CGBitmapContextCreateImage(ctx);
        
        CGContextRelease(ctx);
        CGColorSpaceRelease(colorspace);
        CGGradientRelease(gradientRef);
        
        lastHardness = hardness;
    }
    
    return fadeImageRef;
}

- (WDPath *) splatInRect:(CGRect)rect maxDeviation:(float)percentage randomizer:(WDRandom *)randomizer
{
    // inset the rect so that if we deviate anchors by (1.0 + percentage) it never exceeds the input size
    float width = CGRectGetWidth(rect) / 2;
    float inset = width - (width / (1.0 + percentage));
    rect = CGRectInset(rect, inset, inset);
    
    CGPoint center = WDCenterOfRect(rect);
    WDPath *path = [WDPath pathWithOvalInRect:rect];
    
    [path addAnchors];
    [path addAnchors];
    
    NSMutableArray *newNodes = [NSMutableArray array];
    
    for (WDBezierNode *node in path.nodes) {
        float distance = WDDistance(node.anchorPoint.CGPoint, center);
        float deviation = [randomizer nextFloat] * percentage;
        
        float factor = 1.0 + [randomizer nextSign] * deviation;
        
        CGPoint original = WDSubtractPoints(node.anchorPoint.CGPoint, center);
        CGPoint updated = WDMultiplyPointScalar(WDNormalizePoint(original), distance * factor);
        
        CGPoint delta = WDSubtractPoints(original, updated);
        CGAffineTransform tX = CGAffineTransformMakeTranslation(delta.x, delta.y);
        [newNodes addObject:[node transform:tX]];
    }
    
    path.nodes = newNodes;
    return path;
}

- (CGRect) randomRect:(WDRandom *)randomizer minPercentage:(float)minP maxPercentage:(float)maxP
{
    float w = self.baseDimension;
    float h = self.baseDimension;
    
    float buffer = w * 0.1;
    
    CGPoint center;
    center.x = [randomizer nextFloatMin:0.0f max:(w - (buffer * 2))] + buffer;
    center.y = [randomizer nextFloatMin:0.0f max:(h - (buffer * 2))] + buffer;
    
    float maxDim = MIN(center.x, w - center.x);
    maxDim = MIN(maxDim, MIN(center.y, h - center.y));
    float dim = [randomizer nextFloatMin:(maxDim * minP) max:(maxDim * maxP)];
    
    return CGRectMake(center.x - dim, center.y - dim, dim * 2, dim * 2);
}

@end
