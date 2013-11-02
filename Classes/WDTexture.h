//
//  WDTexture.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

@interface WDTexture : NSObject {
    GLubyte     *data_;
	
	GLsizei     size_;
	GLuint      width_;
	GLuint      height_;
	GLenum      format_;
	GLenum      type_;
	GLuint      rowByteSize_;
	GLuint      unpackAlignment_;
}

@property (nonatomic, readonly) GLuint textureName;

+ (WDTexture *) textureWithCGImage:(CGImageRef)imageRef;
+ (WDTexture *) textureWithImage:(UIImage *)image;

+ (WDTexture *) alphaTextureWithCGImage:(CGImageRef)imageRef;
+ (WDTexture *) alphaTextureWithImage:(UIImage *)image;

- (id) initWithCGImage:(CGImageRef)imageRef forceRGB:(BOOL)forceRGB;

- (void) freeGLResources;

@end
