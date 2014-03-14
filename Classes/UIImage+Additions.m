//
//  UIImage+Additions.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "UIImage+Additions.h"
#import "WDUtilities.h"
#import "UIImage+Resize.h"

@implementation UIImage (WDAdditions)

- (void) drawToFillRect:(CGRect)bounds
{
    float   wScale = CGRectGetWidth(bounds) / self.size.width;
    float   hScale = CGRectGetHeight(bounds) / self.size.height;
    float   scale = MAX(wScale, hScale);
    float   hOffset = 0.0f, vOffset = 0.0f;
    
    CGRect  rect = CGRectMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds), self.size.width * scale, self.size.height * scale);
    
    if (CGRectGetWidth(rect) > CGRectGetWidth(bounds)) {
        hOffset = CGRectGetWidth(rect) - CGRectGetWidth(bounds);
        hOffset /= -2;
    } 
    
    if (CGRectGetHeight(rect) > CGRectGetHeight(bounds)) {
        vOffset = CGRectGetHeight(rect) - CGRectGetHeight(bounds);
        vOffset /= -2;
    }
    
    rect = CGRectOffset(rect, hOffset, vOffset);
    
    [self drawInRect:rect];
}

- (UIImage *) rotatedImage:(int)rotation
{
    CGSize size = self.size;
    CGSize rotatedSize = (rotation % 2 == 1) ? CGSizeMake(size.height, size.width) : size;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    if (rotation == 1) {
        CGContextTranslateCTM(ctx, size.height, 0.0f);
    } else if (rotation == 2) {
        CGContextTranslateCTM(ctx, size.width, size.height);
    } else if (rotation == 3) {
        CGContextTranslateCTM(ctx, 0.0f, size.width);
    }
    
    CGContextRotateCTM(ctx, (M_PI / 2.0f) * rotation);
    
    [self drawAtPoint:CGPointZero];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (UIImage *) downsampleWithMaxDimension:(float)constraint
{
    CGSize newSize, size = self.size;
    
    if (size.width <= constraint && size.height <= constraint && self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    
    if (size.width > size.height) {
        newSize.height = size.height / size.width * constraint;
        newSize.width = constraint;
    } else {
        newSize.width = size.width / size.height * constraint;
        newSize.height = constraint;
    }
    
    newSize = WDRoundSize(newSize);

    return [self resizedImage:newSize interpolationQuality:kCGInterpolationHigh];
}

- (UIImage *) JPEGify:(float)compressionFactor
{
    NSData * jpegData = UIImageJPEGRepresentation(self, compressionFactor);
    return [UIImage imageWithData:jpegData];
}

- (BOOL) hasAlpha
{
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(self.CGImage);
    
    return (alphaInfo == kCGImageAlphaNone ||
            alphaInfo == kCGImageAlphaNoneSkipLast ||
            alphaInfo == kCGImageAlphaNoneSkipFirst) ? NO : YES;
}

- (BOOL) reallyHasAlpha
{
    if (![self hasAlpha]) {
        // if it says it doesn't have alpha, we'll trust it
        return NO;
    }
    
    // otherwise, let's check the bits
    CGImageRef image = self.CGImage;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t rowByteSize = CGImageGetBytesPerRow(image);
    UInt8 *data = malloc(height * rowByteSize);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, width, height, 8, rowByteSize, colorSpaceRef, kCGImageAlphaPremultipliedLast);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    
    BOOL reallyHasAlpha = NO;
    NSUInteger r, c, rowOffset = 0;
    
    for (r = 0; (r < height) && !reallyHasAlpha; r++) {
        for (c = 3; c < rowByteSize; c += 4) {
            if (data[rowOffset + c] < 255) {
                reallyHasAlpha = YES;
                break;
            }
        }
        rowOffset += rowByteSize;
    }
    
    // clean up
    free(data);
    
    return reallyHasAlpha;
}

+ (UIImage *) relevantImageNamed:(NSString *)imageName
{
    if (WDUseModernAppearance()) {
        NSString *rawName = [imageName stringByDeletingPathExtension];
        NSString *modernName = [[rawName stringByAppendingString:@"-modern"] stringByAppendingPathExtension:[imageName pathExtension]];
        UIImage *modern = [UIImage imageNamed:modernName];
        return modern ?: [UIImage imageNamed:imageName];
    } else {
        return [UIImage imageNamed:imageName];
    }
}

@end
