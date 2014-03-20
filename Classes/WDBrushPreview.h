//
//  WDBrushPreview.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreVideo/CoreVideo.h>

@class WDBrush;
@class WDPath;
@class WDShader;
@class WDTexture;

@interface WDBrushPreview : NSObject {
    GLfloat projection[16];
}

@property (nonatomic, assign) GLint backingWidth;
@property (nonatomic, assign) GLint backingHeight;
@property (nonatomic, assign) GLuint colorRenderbuffer;
@property (nonatomic, assign) GLuint defaultFramebuffer;

@property (nonatomic) WDTexture *brushTexture;

@property (nonatomic) WDShader *brushShader;
@property (nonatomic) WDBrush *brush;
@property (nonatomic, strong) WDPath *path;

@property (nonatomic, strong) EAGLContext *context;

@property (nonatomic, assign) CGContextRef cgContext;
@property (nonatomic, assign) GLvoid *pixels;

+ (WDBrushPreview *) sharedInstance;
- (UIImage *) previewWithSize:(CGSize)size;

@end
