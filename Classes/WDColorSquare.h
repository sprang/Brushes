//
//  WDColorSquare.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@class WDColor;
@class WDColorIndicator;
@class WDShader;

@interface WDColorSquare : UIControl {
    // the pixel dimensions of the backbuffer
    GLint               backingWidth;
    GLint               backingHeight;
    
    GLuint              colorRenderbuffer;
    GLuint              defaultFramebuffer;
    
    WDColorIndicator    *indicator_;
}

@property (nonatomic) EAGLContext *context;
@property (nonatomic, strong) WDColor *color;
@property (nonatomic, readonly) float saturation;
@property (nonatomic, readonly) float brightness;
@property (nonatomic, assign) GLuint quadVAO;
@property (nonatomic, assign) GLuint quadVBO;
@property (nonatomic) WDShader *colorShader;

@end
