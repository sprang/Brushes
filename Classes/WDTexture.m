//
//  WDTexture.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDTexture.h"
#import "WDUtilities.h"

@interface WDTexture (Private)
- (void) loadTextureFromImage:(CGImageRef)image forceRGB:(BOOL)forceRGB;
@end

@implementation WDTexture

@synthesize textureName = textureName_;

+ (WDTexture *) textureWithCGImage:(CGImageRef)imageRef
{
    WDTexture *texture = [[WDTexture alloc] initWithCGImage:imageRef forceRGB:YES];
    return texture;
}

+ (WDTexture *) textureWithImage:(UIImage *)image
{
    return [self textureWithCGImage:image.CGImage];
}

+ (WDTexture *) alphaTextureWithCGImage:(CGImageRef)imageRef
{
    WDTexture *texture = [[WDTexture alloc] initWithCGImage:imageRef forceRGB:NO];
    return texture;
}

+ (WDTexture *) alphaTextureWithImage:(UIImage *)image
{
    return [self alphaTextureWithCGImage:image.CGImage];
}

- (id) initWithCGImage:(CGImageRef)imageRef forceRGB:(BOOL)forceRGB
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    [self loadTextureFromImage:imageRef forceRGB:forceRGB];
    
    return self;
}

- (void) freeGLResources
{
    // Assumes context is set appropriately!
    if (textureName_) {
        glDeleteTextures(1, &textureName_);
        textureName_ = 0;
    }
}

- (void) dealloc
{
    // free all allocated data
    if (data_) {
        free(data_);
    }
    
    if (textureName_) {
        WDLog(@"WARNING: WDTexture leaking GL texture.");
    }
    
    WDCheckGLError();
}

static BOOL powerOf2(int x) 
{
    return (x & (x - 1)) == 0;
}

- (GLuint) textureName
{
    if (!textureName_) {
        WDCheckGLError();
        glGenTextures(1, &textureName_);
        glBindTexture(GL_TEXTURE_2D, textureName_);
        
        BOOL canMipMap = (powerOf2(width_) && powerOf2(height_)) ? YES : NO;
        
        // Set up filter and wrap modes for this texture object
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, canMipMap ? GL_LINEAR_MIPMAP_LINEAR : GL_LINEAR);
        
        // indicate that pixel rows are tightly packed (defaults to stride of 4 which is only good for RGBA or FLOAT data types)
        glPixelStorei(GL_UNPACK_ALIGNMENT, unpackAlignment_);
        
        // Allocate and load image data into texture
        glTexImage2D(GL_TEXTURE_2D, 0, format_, width_, height_, 0, format_, type_, data_);
        WDCheckGLError();

        if (canMipMap) {
            glGenerateMipmap(GL_TEXTURE_2D);
            WDCheckGLError();
        }
    }

    return textureName_;
}

@end


@implementation WDTexture (Private)

/* 
 * Allocate and populate image data for OpenGL
 */
- (void) loadTextureFromImage:(CGImageRef)image forceRGB:(BOOL)forceRGB
{
    BOOL isAlpha = forceRGB ? NO : CGImageGetBitsPerPixel(image) == 8;
    
	width_ = (GLuint) CGImageGetWidth(image);
	height_ = (GLuint) CGImageGetHeight(image);
	rowByteSize_ = width_ * (isAlpha ? 1 : 4);
	data_ = malloc(height_ * rowByteSize_);
	format_ = isAlpha ? GL_ALPHA : GL_RGBA;
	type_ = GL_UNSIGNED_BYTE;
    unpackAlignment_ = isAlpha ? 1 : 4;
    
    CGColorSpaceRef colorSpaceRef = isAlpha ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(data_, width_, height_, 8, rowByteSize_,
                                                 colorSpaceRef,
                                                 (isAlpha ? kCGImageAlphaNone : kCGImageAlphaPremultipliedLast));
	CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, CGRectMake(0.0, 0.0, width_, height_), image);
	CGContextRelease(context);
    
    CGColorSpaceRelease(colorSpaceRef);
}

@end
