//
//  WDGLRegion.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDGLRegion.h"
#import "WDUtilities.h"

@implementation WDGLRegion

@synthesize layer;
@synthesize renderbuffer;
@synthesize framebuffer;
@synthesize stencilBuffer;
@synthesize width;
@synthesize height;
@synthesize delegate;
@synthesize context;

+ (WDGLRegion *) regionWithContext:(EAGLContext *)context andLayer:(CAEAGLLayer *)layer
{
    return [[WDGLRegion alloc] initWithContext:context andLayer:layer];
}

- (id) initWithContext:(EAGLContext *)inContext andLayer:(CAEAGLLayer *)inLayer
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.context = inContext;
    [EAGLContext setCurrentContext:inContext];
    
    // set up layer
    self.layer = inLayer;
    
    layer.opaque = NO;
    layer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @(WDCanUseScissorTest()),
                                kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    // create framebuffer object... the backing will be allocated in -resize
    glGenFramebuffers(1, &framebuffer);
    glGenRenderbuffers(1, &renderbuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    
    // also need a stencil buffer
    glGenRenderbuffers(1, &stencilBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, stencilBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, stencilBuffer);
    
    WDCheckGLError();
    
    return self;
}

- (void) dealloc
{
    [self freeGLResources];
}

- (void) freeGLResources
{
    [EAGLContext setCurrentContext:context];
    
    if (framebuffer) {
        glDeleteFramebuffers(1, &framebuffer);
        framebuffer = 0;
    }
    
    if (renderbuffer) {
        glDeleteRenderbuffers(1, &renderbuffer);
        renderbuffer = 0;
    }
    
    if (stencilBuffer) {
        glDeleteBuffers(1, &stencilBuffer);
        stencilBuffer = 0;
    }
    
    WDCheckGLError();
}

- (BOOL) resize
{
    [EAGLContext setCurrentContext:self.context];
    WDCheckGLError();
    
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    
    glBindRenderbuffer(GL_RENDERBUFFER, stencilBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_STENCIL_INDEX8, width, height);
    
    WDCheckGLError();
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        WDLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
        return NO;
    }
    
    return YES;
}

- (void) present
{
    glBindFramebuffer(GL_FRAMEBUFFER, self.framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, self.renderbuffer);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
