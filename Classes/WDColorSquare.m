//
//  WDColorSquare.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDColor.h"
#import "WDColorIndicator.h"
#import "WDColorSquare.h"
#import "WDInsetView.h"
#import "WDShader.h"
#import "WDUtilities.h"
#import "UIView+Additions.h"
#import "gl_matrix.h"

@implementation WDColorSquare

@synthesize color = color_;
@synthesize brightness = brightness_;
@synthesize saturation = saturation_;
@synthesize context = context_;
@synthesize quadVAO = quadVAO_;
@synthesize quadVBO = quadVBO_;
@synthesize colorShader = colorShader_;

+ (Class) layerClass
{
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{    
    self = [super initWithCoder:aDecoder];
    
    if (!self) {
        return nil;
    }
    
    // Get the layer
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = NO;
    eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @NO,
                                    kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    context_ = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];        
    if (!context_ || ![EAGLContext setCurrentContext:context_]) {
        return nil;
    }
    
    // Create system framebuffer object. The backing will be allocated in -reshapeFramebuffer
    glGenFramebuffersOES(1, &defaultFramebuffer);
    glGenRenderbuffersOES(1, &colorRenderbuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    
    self.multipleTouchEnabled = YES;
    self.contentMode = UIViewContentModeCenter;
    self.exclusiveTouch = YES;
    
    WDInsetView *insetView = [[WDInsetView alloc] initWithFrame:self.bounds];
    [self addSubview:insetView];
    
    indicator_ = [[WDColorIndicator alloc] initWithFrame:CGRectMake(0,0,24,24)];
    indicator_.sharpCenter = WDCenterOfRect(self.bounds);
    indicator_.opaque = NO;
    [self addSubview:indicator_];
    
    return self;
}

- (GLuint) quadVAO
{
    if (!quadVAO_) {
        float width = CGRectGetWidth(self.bounds);
        float height = CGRectGetHeight(self.bounds);
        
        CGPoint corners[4];
        corners[0] = CGPointMake(0, 0);
        corners[1] = CGPointMake(width, 0);
        corners[2] = CGPointMake(width, height);
        corners[3] = CGPointMake(0, height);
        
        const GLfloat quadVertices[] = {
            corners[0].x, corners[0].y, 0.0, 0.0,
            corners[1].x, corners[1].y, 1.0, 0.0,
            corners[3].x, corners[3].y, 0.0, 1.0,
            corners[2].x, corners[2].y, 1.0, 1.0,
        };
        
        // create and bind VAO
        glGenVertexArraysOES(1, &quadVAO_);
        glBindVertexArrayOES(quadVAO_);
        
        // create, bind, and populate VBO
        glGenBuffers(1, &quadVBO_);
        glBindBuffer(GL_ARRAY_BUFFER, quadVBO_);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 16, quadVertices, GL_STATIC_DRAW);
        
        // set up attrib pointers
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)0);
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, (void*)8);
        glEnableVertexAttribArray(1);
        
        // unbind buffers
        glBindBuffer(GL_ARRAY_BUFFER,0);
        glBindVertexArrayOES(0);
    }
    
    return quadVAO_;
}

- (WDShader *) colorShader
{
    if (!colorShader_) {
        NSArray *attributes = @[@"inPosition", @"inTexcoord"];
        NSArray *uniforms = @[@"modelViewProjectionMatrix", @"hue"];
        
        colorShader_ = [[WDShader alloc] initWithVertexShader:@"blit" fragmentShader:@"colorPicker"
                                                     attributesNames:attributes uniformNames:uniforms];
    }
    
    return colorShader_;
}

- (void) drawView
{
    [EAGLContext setCurrentContext:self.context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	
	// handle viewing matrices
	GLfloat proj[16];
	// setup projection matrix (orthographic)
	mat4f_LoadOrtho(0, backingWidth, 0, backingHeight, -1.0f, 1.0f, proj);
    
    // use shader program
    WDShader *colorShader = self.colorShader;
	glUseProgram(colorShader.program);
	glUniformMatrix4fv([colorShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
    glUniform1f([colorShader locationForUniform:@"hue"], self.color.hue);
    
    glBindVertexArrayOES(self.quadVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // unbind VAO
    glBindVertexArrayOES(0);
    
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)reshapeFramebuffer
{
	// Allocate color buffer backing based on the current layer size
    [context_ renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
    
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    [EAGLContext setCurrentContext:context_];
}

- (void)layoutSubviews
{
    [self reshapeFramebuffer];
    [self drawView];
}

- (void)dealloc
{        
    // make sure our context is active before we delete stuff
    [EAGLContext setCurrentContext:context_];

    // free buffers
    glDeleteVertexArraysOES(1, &quadVAO_);
    glDeleteBuffers(1, &quadVBO_);

    // free shaders

    [EAGLContext setCurrentContext:nil];
}

- (CGRect) trackRect
{
    return CGRectInset(self.bounds, 5, 5);
}

- (CGPoint) indicatorPosition
{
    CGPoint result;
    
    result.x = saturation_ * CGRectGetWidth(self.trackRect);
    result.y = CGRectGetHeight(self.trackRect) - (brightness_ * CGRectGetHeight(self.trackRect));
    
    result = WDAddPoints(result, self.trackRect.origin);
    
    return result;
}

- (void) setColor:(WDColor *)color
{
    BOOL hueChanged = (color_.hue == color.hue) ? NO : YES;
    
    color_ = color;
    saturation_ = color.saturation;
    brightness_ = color.brightness;
    indicator_.color = color;
    
    indicator_.sharpCenter = [self indicatorPosition];
    
    if (hueChanged) {
        // redraw once at the end of the run loop
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(drawView) withObject:nil afterDelay:0];
    }
}

- (void) computeValueForTouch:(UITouch *)touch
{
    CGPoint pt = [touch locationInView:self];
    
    pt.x = WDClamp(CGRectGetMinX(self.trackRect), CGRectGetMaxX(self.trackRect), pt.x);
    pt.y = WDClamp(CGRectGetMinY(self.trackRect), CGRectGetMaxY(self.trackRect), pt.y);
    
    saturation_ = (pt.x - CGRectGetMinX(self.trackRect)) / CGRectGetWidth(self.trackRect);
    brightness_ = (pt.y - CGRectGetMinY(self.trackRect)) / CGRectGetHeight(self.trackRect);
    brightness_ = 1.0f - brightness_; // flip brightness
}

- (BOOL) beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self computeValueForTouch:touch];
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.1];
    indicator_.sharpCenter = [self indicatorPosition];
	[UIView commitAnimations];
    
    return YES;
}

- (BOOL) continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self computeValueForTouch:touch];
    indicator_.sharpCenter = [self indicatorPosition];
    
    return [super continueTrackingWithTouch:touch withEvent:event];
}

@end
