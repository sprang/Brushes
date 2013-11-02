//
//  WDBrushPreview.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WD3DPoint.h"
#import "WDBezierNode.h"
#import "WDBrush.h"
#import "WDBrushPreview.h"
#import "WDPath.h"
#import "WDShader.h"
#import "WDTexture.h"
#import "WDUtilities.h"

#import "gl_matrix.h"

@implementation WDBrushPreview

@synthesize backingWidth;
@synthesize backingHeight;
@synthesize defaultFramebuffer;
@synthesize colorRenderbuffer;
@synthesize context;

@synthesize brushShader;
@synthesize brushTexture;
@synthesize brush;
@synthesize path;

@synthesize cgContext;
@synthesize pixels;

+ (WDBrushPreview *) sharedInstance
{
    static WDBrushPreview *preview_ = nil;
    
    if (!preview_) {
        preview_ = [[WDBrushPreview alloc] init];
    }
    
    return preview_;
}

- (void) buildPath
{
    if (self.path) {
        return;
    }
    
    WDBezierNode *node;
    NSMutableArray *nodes = [NSMutableArray array];
    float scale = [UIScreen mainScreen].scale;
    
    // build a nice little sin curve
    {
        CGPoint start = { 30, backingHeight / (2.0f * scale)};
        float   width = (backingWidth / scale) - 2.0f * 30;
        float amplitude  = 10.0f;
        
        float kNumLineSegments = 100;
        for (int i = 0; i < kNumLineSegments; i++) {
            float fraction = (float)i / (kNumLineSegments - 1);
            CGPoint pt = CGPointMake(start.x + width * fraction, start.y + sin(fraction * 2 * M_PI) * amplitude );
            node = [WDBezierNode bezierNodeWithAnchorPoint:[WD3DPoint pointWithX:pt.x y:pt.y z:fraction]];
            [nodes addObject:node];
        }
    }
    
    self.path = [[WDPath alloc] init];
    self.path.limitBrushSize = YES;
    self.path.nodes = nodes;
}
    
- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!context || ![EAGLContext setCurrentContext:context]) {
        return nil;
    }
    
    // create system framebuffer object. The backing will be allocated in -reshapeFramebuffer
    glGenFramebuffers(1, &defaultFramebuffer);
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    // configure some default GL state
    glDisable(GL_DITHER);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_DEPTH_TEST);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(brushGeneratorChanged:)
                                                 name:WDBrushGeneratorChanged
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(brushGeneratorChanged:)
                                                 name:WDBrushGeneratorReplaced
                                               object:nil];
    
    return self;
}

- (WDShader *) brushShader
{
    if (!brushShader) {
        NSArray *attributes = @[@"inPosition", @"inTexcoord", @"alpha"];
        NSArray *uniforms = @[@"modelViewProjectionMatrix", @"texture", @"noise"];
        
        brushShader = [[WDShader alloc] initWithVertexShader:@"brush" fragmentShader:@"brush" attributesNames:attributes uniformNames:uniforms];
    }
    
    return brushShader;
}

- (WDTexture *) brushTexture
{
    if (!brushTexture) {
        WDStampGenerator *gen = brush.generator;
        brushTexture = [WDTexture alphaTextureWithImage:gen.smallStamp];
    }
    
    return brushTexture;
}

- (void) clearBrushTexture
{
    if (brushTexture) {
        [EAGLContext setCurrentContext:self.context];
        
        [self.brushTexture freeGLResources];
        self.brushTexture = nil;  
    }
}

- (void) brushGeneratorChanged:(NSNotification *)aNotification
{
    if (aNotification.object == self.brush) {
        [self clearBrushTexture];
    }
}

- (void) configureBrush:(GLfloat *)proj
{
    glUseProgram(self.brushShader.program);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.brushTexture.textureName);
    
    glUniform1i([self.brushShader locationForUniform:@"texture"], 0);
	glUniformMatrix4fv([self.brushShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
}

- (void) setup:(CGSize)size
{    
    if (backingWidth == size.width && backingHeight == size.height) {
        return;
    }
    
    backingWidth = size.width;
    backingHeight = size.height;
    
    if (pixels) {
        free(pixels);
    }
    pixels = malloc(sizeof(GLvoid) * backingWidth * 4 * backingHeight);
    
    if (cgContext) {
        CGContextRelease(cgContext);
    }
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(pixels, backingWidth, backingHeight, 8, backingWidth * 4,
                                             colorSpaceRef, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpaceRef);
    
    if (self.path) {
        self.path = nil;
    }    
    [self buildPath];
    
	// handle viewing matrices
	GLfloat proj[16], scale[16];
	// setup projection matrix (orthographic)
	mat4f_LoadOrtho(0, backingWidth, 0, backingHeight, -1.0f, 1.0f, proj);
    
    float s = [UIScreen mainScreen].scale;
    CGAffineTransform tX = CGAffineTransformMakeScale(s, s);
    mat4f_LoadCGAffineTransform(scale, tX);
    
    mat4f_MultiplyMat4f(proj, scale, projection);
    
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, size.width, size.height);
}

- (UIImage *) previewWithSize:(CGSize)size
{
    //WDBeginTiming();
    
    size = WDMultiplySizeScalar(size, [UIScreen mainScreen].scale);
    
    [EAGLContext setCurrentContext:context];
    
    [self setup:size];
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);    
    glViewport(0, 0, backingWidth, backingHeight);
    
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self configureBrush:projection];
    path.brush = self.brush;
    path.remainder = 0.0f;
    [path paint:[path newRandomizer]];
    
    //WDLogTiming(@"Preview 0");
    
    glReadPixels(0, 0, backingWidth, backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
    
    UIImage *result = nil;
    CGImageRef imageRef = CGBitmapContextCreateImage(cgContext);
    result = [[UIImage alloc] initWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    //WDEndTiming(@"Preview 1");
    return result;
}

- (void) setBrush:(WDBrush *)aBrush
{
    if (![aBrush.generator isEqual:brush.generator]) {
        [self clearBrushTexture];
    }
    
    brush = aBrush;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [EAGLContext setCurrentContext:self.context];
    
    if (cgContext) {
        CGContextRelease(cgContext);
    }
    
    self.brush = nil;
    
	// tear down GL
	if (defaultFramebuffer) {
		glDeleteFramebuffers(1, &defaultFramebuffer);
		defaultFramebuffer = 0;
	}
	
	if (colorRenderbuffer) {
		glDeleteRenderbuffers(1, &colorRenderbuffer);
		colorRenderbuffer = 0;
	}
    
    // tear down context
    [EAGLContext setCurrentContext:nil];
}

@end
