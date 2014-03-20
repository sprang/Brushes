//
//  WDLayer.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "NSData+Additions.h"

#import "WDActiveState.h"
#import "WDCoder.h"
#import "WDColor.h"
#import "WDColorBalance.h"
#import "WDDecoder.h"
#import "WDGLUtilities.h"
#import "WDHueSaturation.h"
#import "WDLayer.h"
#import "WDPaintingFragment.h"
#import "WDShader.h"
#import "WDTexture.h"
#import "WDTypedData.h"
#import "WDUtilities.h"
#import "UIImage+Additions.h"

#import "gl_matrix.h"

#define kPreviewInset               1
#define kDrawPreviewBorder          YES

NSString *WDColorBalanceChanged = @"WDColorBalanceChanged";
NSString *WDHueSaturationChanged = @"WDHueSaturationChanged";
NSString *WDLayerVisibilityChanged = @"WDLayerVisibilityChanged";
NSString *WDLayerLockedStatusChanged = @"WDLayerLockedStatusChanged";
NSString *WDLayerAlphaLockedStatusChanged = @"WDLayerAlphaLockedStatusChanged";
NSString *WDLayerOpacityChanged = @"WDLayerOpacityChanged";
NSString *WDLayerBlendModeChanged = @"WDLayerBlendModeChanged";
NSString *WDLayerContentsChangedNotification = @"WDLayerContentsChangedNotification";
NSString *WDLayerThumbnailChangedNotification = @"WDLayerThumbnailChangedNotification";
NSString *WDLayerTransformChangedNotification = @"WDLayerTransformChangedNotification";

static NSString *WDAlphaLockedKey = @"alphaLocked";
static NSString *WDBlendModeKey = @"blendMode";
static NSString *WDImageDataKey = @"layerImage";
static NSString *WDLockedKey = @"locked";
static NSString *WDOpacityKey = @"opacity";
static NSString *WDPaintingKey = @"painting";
static NSString *WDUUIDKey = @"uuid";
static NSString *WDVisibleKey = @"visible";

@interface WDLayer ()
@property (nonatomic, readonly) NSInteger maxThumbnailDimension;
@end

@implementation WDLayer {
    NSData *loadedImageData_;
    WDPaintingFragment *fragment_;
}

@synthesize painting = painting_;
@synthesize visible = visible_;
@synthesize locked = locked_;
@synthesize alphaLocked = alphaLocked_;
@synthesize opacity = opacity_;
@synthesize thumbnail = thumbnail_;
@synthesize hueChromaLuma = hueChromaLuma_;
@synthesize textureName = textureName_;
@synthesize blendMode = blendMode_;
@synthesize hueSaturation = hueSaturation_;
@synthesize colorBalance = colorBalance_;
@synthesize uuid = uuid_;
@synthesize isSaved;
@synthesize transform;
@synthesize clipWhenTransformed;

+ (WDLayer *) layer
{
    WDLayer *layer = [[WDLayer alloc] init];
    return layer;
}

- (id) init
{
    return [self initWithUUID:generateUUID()];
}

- (id) initWithUUID:(NSString *)uuid
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.visible = YES;
    opacity_ = 1.0;
    blendMode_ = WDBlendModeNormal;
    loadedImageData_ = NULL;
    uuid_ = uuid;
    self.isSaved = kWDSaveStatusUnsaved;
    self.transform = CGAffineTransformIdentity;
    
    return self;
}

- (void) enableLinearInterpolation:(BOOL)flag
{
    [EAGLContext setCurrentContext:self.painting.context];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, flag ? GL_LINEAR : GL_NEAREST);
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
    if (self.painting) {
        [EAGLContext setCurrentContext:self.painting.context];
        [self freeGLResources];
    }
}

- (BOOL) isSuppressingNotifications
{
    if (!painting_ || painting_.isSuppressingNotifications) {
        return YES;
    }

    return NO;
}

- (void) setTransform:(CGAffineTransform)inTransform
{
    transform = inTransform;
    [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerTransformChangedNotification object:self.painting];
}

- (void) setBlendMode:(WDBlendMode)blendMode
{
    if (blendMode == blendMode_) {
        return;
    }

    [[[self.painting undoManager] prepareWithInvocationTarget:self] setBlendMode:blendMode_];

    blendMode_ = blendMode;

    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": self,
                                  @"rect": [NSValue valueWithCGRect:self.painting.bounds]};

        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerBlendModeChanged
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
}

- (void) setOpacity:(float)opacity
{
    if (opacity == opacity_) {
        return;
    }

    [[[self.painting undoManager] prepareWithInvocationTarget:self] setOpacity:opacity_];

    opacity_ = WDClamp(0.0f, 1.0f, opacity);

    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": self,
                                  @"rect": [NSValue valueWithCGRect:self.painting.bounds]};

        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerOpacityChanged
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
}

- (void) setColorBalance:(WDColorBalance *)colorBalance
{
    if ([colorBalance isEqual:colorBalance_]) {
        return;
    }
    
    colorBalance_ = colorBalance;
    
    if (!self.isSuppressingNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WDColorBalanceChanged
                                                            object:self.painting
                                                          userInfo:nil];
    }
}

- (NSData *) imageDataInRect:(CGRect)rect
{
    NSData *result = nil;
    
    // make sure the painting's context is current
    [EAGLContext setCurrentContext:self.painting.context];
    WDCheckGLError();
    
    GLint minX = (GLint) CGRectGetMinX(rect);
    GLint minY = (GLint) CGRectGetMinY(rect);
    GLint width = (GLint) CGRectGetWidth(rect);
    GLint height = (GLint) CGRectGetHeight(rect);
    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    GLuint colorRenderbuffer;
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    GLint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status == GL_FRAMEBUFFER_COMPLETE) {
        glViewport(0, 0, self.painting.width, self.painting.height);
        
        WDShader *blitShader = [self.painting getShader:@"nonPremultipliedBlit"];
        glUseProgram(blitShader.program);
        
        GLfloat proj[16], effectiveProj[16],final[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, (GLuint) self.painting.width, 0, (GLuint) self.painting.height, -1.0f, 1.0f, proj);
        
        CGAffineTransform translate = CGAffineTransformMakeTranslation(-minX, -minY);
        mat4f_LoadCGAffineTransform(effectiveProj, translate);
        mat4f_MultiplyMat4f(proj, effectiveProj, final);
        
        glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, final);
        glUniform1i([blitShader locationForUniform:@"texture"], (GLuint) 0);
        glUniform1f([blitShader locationForUniform:@"opacity"], 1.0f); // fully opaque
        
        glActiveTexture(GL_TEXTURE0);
        // Bind the texture to be used
        glBindTexture(GL_TEXTURE_2D, self.textureName);
        
        // clear the buffer to get a transparent background
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        // set up premultiplied normal blend
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        glBindVertexArrayOES(painting_.quadVAO);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glBindVertexArrayOES(0);
        
        // color buffer should now have layer contents
        UInt8 *pixels = malloc(sizeof(UInt8) * width * 4 * height);
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
        
        result = [NSData dataWithBytes:pixels length:width * 4 * height];
        free(pixels);
    } else {
        NSLog(@"-[WDLayer imageDataInRect]: Incomplete Framebuffer!");
        WDCheckGLError();
    }
    
    glDeleteFramebuffers(1, &framebuffer);
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    
    WDCheckGLError();
    return result;
}

- (void) drawFragment:(WDPaintingFragment *)fragment
{
    WDPaintingFragment *inverseFragment = [fragment inverseFragment:self];
    [[self.painting.undoManager prepareWithInvocationTarget:self] drawFragment:inverseFragment];
    
    [fragment applyInLayer:self];
    
    [self invalidateThumbnail];
    
    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": self,
                                  @"rect": [NSValue valueWithCGRect:fragment.bounds]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerContentsChangedNotification
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
}

- (void) registerUndoInRect:(CGRect)rect
{
    rect = CGRectIntersection(rect, self.painting.bounds);
    
    WDPaintingFragment *fragment = [WDPaintingFragment paintingFragmentWithData:[self imageDataInRect:rect] bounds:rect];
    [[self.painting.undoManager prepareWithInvocationTarget:self] drawFragment:fragment];
}

- (void) notifyThumbnailChanged:(id)obj
{
    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": self};
        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerThumbnailChangedNotification object:self.painting userInfo:userInfo];
    }
}

- (void) invalidateThumbnail
{
    if (!thumbnail_) {
        return;
    }

    thumbnail_ = nil;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(notifyThumbnailChanged:) object:nil];
    [self performSelector:@selector(notifyThumbnailChanged:) withObject:nil afterDelay:0];
}

- (NSData *) imageData
{
    return [self imageDataInRect:self.painting.bounds];
}

- (void) setImageData:(NSData *)imageData
{
    [EAGLContext setCurrentContext:self.painting.context];
    
    CGRect bounds = self.painting.bounds;
    GLint xoffset = CGRectGetMinX(bounds);
    GLint yoffset = CGRectGetMinY(bounds);
    GLsizei width = CGRectGetWidth(bounds);
    GLsizei height = CGRectGetHeight(bounds);
    
    glBindTexture(GL_TEXTURE_2D, self.textureName);
    glTexSubImage2D(GL_TEXTURE_2D, 0, xoffset, yoffset, width, height, GL_RGBA, GL_UNSIGNED_BYTE, imageData.bytes);
    
    [self invalidateThumbnail];
    
    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": self,
                                  @"rect": [NSValue valueWithCGRect:bounds]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerContentsChangedNotification
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
}

- (NSInteger) maxThumbnailDimension
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return 200;
    } else {
        return 360;
    }
}

- (NSInteger) thumbnailImageHeight
{
    NSInteger   height = self.maxThumbnailDimension;

    if (self.painting.width > self.painting.height) {
        height = floorf(self.painting.height / self.painting.width * height);
    }

    return height;
}

- (UIImage *) thumbnail
{    
    if (!thumbnail_) {
#if WD_DEBUG
        NSDate *date = [NSDate date];
#endif
        // make sure the painting's context is current
        [EAGLContext setCurrentContext:self.painting.context];
        WDCheckGLError();

        GLuint width, height;
        float paintingWidth = self.painting.width;
        float paintingHeight = self.painting.height;
        float aspectRatio = paintingWidth / paintingHeight;
        
        // figure out the width and height of the thumbnail
        if (aspectRatio > 1.0) {
            width = (GLuint) self.maxThumbnailDimension;
            height = floorf(1.0 / aspectRatio * width);
        } else {
            height = (GLuint) self.maxThumbnailDimension;
            width = floorf(aspectRatio * height);
        }

        width *= [UIScreen mainScreen].scale;
        height *= [UIScreen mainScreen].scale;
        
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

        GLuint colorRenderbuffer;
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);

        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        GLint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);

        if (status == GL_FRAMEBUFFER_COMPLETE) {
            glViewport(0, 0, self.painting.width, self.painting.height);
            
            WDShader *blitShader = [self.painting getShader:@"blit"];

            glUseProgram(blitShader.program);

            GLsizei viewportWidth = MAX(width, paintingWidth);
            GLsizei viewportHeight = MAX(height, paintingHeight);
            glViewport(0, 0, viewportWidth, viewportHeight);
            
            // figure out the projection matrix
            GLfloat proj[16], effectiveProj[16], final[16];
            // setup projection matrix (orthographic)
            mat4f_LoadOrtho(0, paintingWidth, 0, paintingHeight, -1.0f, 1.0f, proj);

            CGAffineTransform scale = CGAffineTransformMakeScale((float) width / viewportWidth,
                                                                 (float) height / viewportHeight);
            mat4f_LoadCGAffineTransform(effectiveProj, scale);
            mat4f_MultiplyMat4f(proj, effectiveProj, final);

            glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, final);
            glUniform1i([blitShader locationForUniform:@"texture"], (GLuint) 0);
            glUniform1f([blitShader locationForUniform:@"opacity"], 1.0f); // fully opaque thumb

            glActiveTexture(GL_TEXTURE0);
            // Bind the texture to be used
            glBindTexture(GL_TEXTURE_2D, self.textureName);

            // clear the buffer to get a transparent background
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
            glClear(GL_COLOR_BUFFER_BIT);

            // set up premultiplied normal blend
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

            glBindVertexArrayOES(painting_.quadVAO);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            glBindVertexArrayOES(0);

            // color buffer should now have layer contents
            unsigned char *pixels = malloc(sizeof(unsigned char) * width * 4 * height);
            glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

            CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
            CGContextRef ctx = CGBitmapContextCreate(pixels, width, height, 8, width*4,
                                                     colorSpaceRef, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
            CGImageRef imageRef = CGBitmapContextCreateImage(ctx);

            thumbnail_ = [[UIImage alloc] initWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];

            CGImageRelease(imageRef);
            CGContextRelease(ctx);
            CGColorSpaceRelease(colorSpaceRef);
            free(pixels);
        } else {
            NSLog(@"-[WDLayer thumbnail]: Incomplete Framebuffer!");
            WDCheckGLError();
        }

        glDeleteFramebuffers(1, &framebuffer);
        glDeleteRenderbuffers(1, &colorRenderbuffer);
        WDCheckGLError();
        
#if WD_DEBUG
        NSLog(@"Thumbnail gen: %f", -[date timeIntervalSinceNow]);
#endif
    }
    
    return thumbnail_;
}

- (void) toggleLocked
{
    self.locked = !self.locked;
}

- (void) toggleVisibility
{
    self.visible = !self.visible;
}

- (void) toggleAlphaLocked
{
    self.alphaLocked = !self.alphaLocked;
}

- (BOOL) editable
{
    return (!self.locked && self.visible);
}

- (void) setVisible:(BOOL)visible
{
    [[[self.painting undoManager] prepareWithInvocationTarget:self] setVisible:visible_];

    visible_ = visible;

    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": self,
                                  @"rect": [NSValue valueWithCGRect:self.painting.bounds]};

        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerVisibilityChanged
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
}

- (void) setLocked:(BOOL)locked
{
    [[[self.painting undoManager] prepareWithInvocationTarget:self] setLocked:locked_];

    locked_ = locked;

    if (!self.isSuppressingNotifications) {

        NSDictionary *userInfo = @{@"layer": self};

        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerLockedStatusChanged
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
}

- (void) setAlphaLocked:(BOOL)alphaLocked
{
    [[[self.painting undoManager] prepareWithInvocationTarget:self] setAlphaLocked:alphaLocked_];
    
    alphaLocked_ = alphaLocked;
    
    if (!self.isSuppressingNotifications) {
        
        NSDictionary *userInfo = @{@"layer": self};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerAlphaLockedStatusChanged
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
}

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep
{
    [coder encodeBoolean:visible_ forKey:WDVisibleKey];
    [coder encodeBoolean:locked_ forKey:WDLockedKey];
    [coder encodeBoolean:alphaLocked_ forKey:WDAlphaLockedKey];
    [coder encodeInteger:blendMode_ forKey:WDBlendModeKey];
    [coder encodeString:uuid_ forKey:WDUUIDKey];

    if (opacity_ != 1.f) {
        [coder encodeFloat:opacity_ forKey:WDOpacityKey];
    }

    if (deep) {
        WDSaveStatus wasSaved = self.isSaved;
        self.isSaved = kWDSaveStatusTentative;
        id data = (wasSaved == kWDSaveStatusSaved) ? [NSNull null] : self.imageData; // don't bother retrieving imageData if we're not saving it
        WDTypedData *image = [WDTypedData data:data mediaType:@"image/x-brushes-layer" compress:YES uuid:self.uuid isSaved:wasSaved];
        [coder encodeDataProvider:image forKey:WDImageDataKey];
    }
}

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    // avoid setting these if they haven't changed, to prevent unnecessary notifications
    BOOL visible = [decoder decodeBooleanForKey:WDVisibleKey];
    if (visible != self.visible) {
        self.visible = visible;
    }
    BOOL locked = [decoder decodeBooleanForKey:WDLockedKey];
    if (locked != self.locked) {
        self.locked = locked;
    }
    BOOL alphaLocked = [decoder decodeBooleanForKey:WDAlphaLockedKey];
    if (alphaLocked != self.alphaLocked) {
        self.alphaLocked = alphaLocked;
    }
    
    WDBlendMode blendMode = (WDBlendMode) [decoder decodeIntegerForKey:WDBlendModeKey];
    blendMode = WDValidateBlendMode(blendMode);
    if (blendMode != self.blendMode) {
        self.blendMode = blendMode;
    }


    uuid_ = [decoder decodeStringForKey:WDUUIDKey];

    id opacity = [decoder decodeObjectForKey:WDOpacityKey];
    self.opacity = opacity ? [opacity floatValue] : 1.f;

    if (deep) {
        [decoder dispatch:^{
            loadedImageData_ = [[decoder decodeDataForKey:WDImageDataKey] decompress];
            self.isSaved = kWDSaveStatusSaved;
        }];
    }
}

- (id) copyWithZone:(NSZone *)zone
{
    WDLayer *layer = [[WDLayer alloc] init];
    
    layer->opacity_ = self->opacity_;
    layer->locked_ = self->locked_;
    layer->alphaLocked_ = self->alphaLocked_;
    layer->visible_ = self->visible_;
    
    return layer;
}

- (void) configureBlendMode
{
    switch (blendMode_) {
        case WDBlendModeMultiply:
            glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
            break;
        case WDBlendModeScreen:
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_COLOR);
            break;
        case WDBlendModeExclusion:
            glBlendFuncSeparate(GL_ONE_MINUS_DST_COLOR, GL_ONE_MINUS_SRC_COLOR, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            break;
        default: // WDBlendModeNormal
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); // premultiplied blend
            break;
    }
}

- (void) setHueSaturation:(WDHueSaturation *)inHueSaturation
{
    if (!hueSaturation_ && inHueSaturation) {
        [EAGLContext setCurrentContext:self.painting.context];
        
        // create texture
        hueChromaLuma_ = [self.painting generateTexture:nil];
        
        glBindFramebuffer(GL_FRAMEBUFFER, self.painting.reusableFramebuffer);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, hueChromaLuma_, 0);
        
        GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if (status == GL_FRAMEBUFFER_COMPLETE) {
            glViewport(0, 0, self.painting.width, self.painting.height);
            
            WDShader *blitShader = [self.painting getShader:@"toHueChromaLuma"];
            glUseProgram(blitShader.program);
            
            GLuint width = self.painting.width;
            GLuint height = self.painting.height;
            
            // figure out the projection matrix
            GLfloat proj[16];
            // setup projection matrix (orthographic)
            mat4f_LoadOrtho(0, width, 0, height, -1.0f, 1.0f, proj);
            
            glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
            glUniform1i([blitShader locationForUniform:@"texture"], 0);
            
            glActiveTexture(GL_TEXTURE0);
            // Bind the texture to be used
            glBindTexture(GL_TEXTURE_2D, self.textureName);
            
            // set up premultiplied normal blend
            glBlendFunc(GL_ONE, GL_ZERO);
            
            glBindVertexArrayOES(painting_.quadVAO);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            // unbind VAO
            glBindVertexArrayOES(0);
        }

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    } else if (hueSaturation_ && !inHueSaturation) {
        glDeleteTextures(1, &hueChromaLuma_);
        hueChromaLuma_ = 0;
    }
    
    hueSaturation_ = inHueSaturation;
    
    if (!self.isSuppressingNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:WDHueSaturationChanged
                                                            object:self.painting
                                                          userInfo:nil];
    }
}

- (void) basicBlit:(GLfloat *)proj
{
    WDShader *blitShader = [self.painting getShader:@"blit"];
	glUseProgram(blitShader.program);
    
	glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
	glUniform1i([blitShader locationForUniform:@"texture"], 0);
	glUniform1f([blitShader locationForUniform:@"opacity"], opacity_);
    
    // Bind the texture to be used
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureName);
    [self configureBlendMode];
    
    glBindVertexArrayOES(self.painting.quadVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // unbind VAO
    glBindVertexArrayOES(0);
}

- (void) blit:(GLfloat *)proj
{
    if (!CGAffineTransformIsIdentity(self.transform)) {
        [self blit:proj withTransform:self.transform];
        return;
    }
    
    WDShader *blitShader = nil;
    
    if (self.colorBalance) {
        blitShader = [self.painting getShader:@"colorBalanceBlit"];
    } else if (self.hueSaturation) {
        blitShader = [self.painting getShader:@"blitFromHueChromaLuma"];
    } else {
        blitShader = [self.painting getShader:@"blit"];
    }
    
	glUseProgram(blitShader.program);
    
	glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
	glUniform1i([blitShader locationForUniform:@"texture"], 0);
	glUniform1f([blitShader locationForUniform:@"opacity"], opacity_);
    
    if (self.colorBalance) {
        glUniform1f([blitShader locationForUniform:@"redShift"], colorBalance_.redShift);
        glUniform1f([blitShader locationForUniform:@"greenShift"], colorBalance_.greenShift);
        glUniform1f([blitShader locationForUniform:@"blueShift"], colorBalance_.blueShift);
        glUniform1i([blitShader locationForUniform:@"premultiply"], 1);
    } else if (self.hueSaturation) {
        glUniform1f([blitShader locationForUniform:@"hueShift"], hueSaturation_.hueShift);
        glUniform1f([blitShader locationForUniform:@"saturationShift"], hueSaturation_.saturationShift);
        glUniform1f([blitShader locationForUniform:@"brightnessShift"], hueSaturation_.brightnessShift);
        glUniform1i([blitShader locationForUniform:@"premultiply"], 1);
    }
    
    // Bind the texture to be used
    glActiveTexture(GL_TEXTURE0);
    if (self.hueSaturation) {
        glBindTexture(GL_TEXTURE_2D, self.hueChromaLuma);
    } else {
        glBindTexture(GL_TEXTURE_2D, self.textureName);
    }
        
    [self configureBlendMode];
    
    glBindVertexArrayOES(self.painting.quadVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    // unbind VAO
    glBindVertexArrayOES(0);
}

- (void) blit:(GLfloat *)proj withTransform:(CGAffineTransform)tX
{
	// use shader program
    WDShader *blitShader = [self.painting getShader:@"blit"];
	glUseProgram(blitShader.program);
    
	glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
	glUniform1i([blitShader locationForUniform:@"texture"], 0);
	glUniform1f([blitShader locationForUniform:@"opacity"], opacity_);
    
    // Bind the texture to be used
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureName);
    
    [self configureBlendMode];
    CGRect rect = CGRectMake(0, 0, self.painting.dimensions.width, self.painting.dimensions.height);
    
    if (self.clipWhenTransformed) {
        glEnable(GL_STENCIL_TEST);
        glClearStencil(0);
        glClear(GL_STENCIL_BUFFER_BIT);
        
        // All drawing commands fail the stencil test, and are not drawn, but increment the value in the stencil buffer.
        glStencilFunc(GL_NEVER, 0, 0);
        glStencilOp(GL_INCR, GL_INCR, GL_INCR);
        
        WDGLRenderInRect(rect, CGAffineTransformIdentity);
        
        // now, allow drawing, except where the stencil pattern is 0x1 and do not make any further changes to the stencil buffer
        glStencilFunc(GL_EQUAL, 1, 1);
        glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
    }
    
    WDGLRenderInRect(rect, tX);
    
    if (self.clipWhenTransformed) {
        glDisable(GL_STENCIL_TEST);
    }
    WDCheckGLError();

}

- (void) blit:(GLfloat *)proj withMask:(GLuint)maskTexture color:(WDColor *)color
{
	// use shader program
    WDShader *blitShader = [self.painting getShader:@"blitWithMask"];
	glUseProgram(blitShader.program);
    
	glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
	glUniform1i([blitShader locationForUniform:@"texture"], 0);
	glUniform1f([blitShader locationForUniform:@"opacity"], opacity_);
	glUniform4f([blitShader locationForUniform:@"color"], color.red, color.green, color.blue, color.alpha);
    glUniform1i([blitShader locationForUniform:@"mask"], 1);
    glUniform1i([blitShader locationForUniform:@"lockAlpha"], self.alphaLocked);
    
    // Bind the texture to be used
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureName);
                                  
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, maskTexture);
    
    [self configureBlendMode];
    
    glBindVertexArrayOES(self.painting.quadVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // unbind VAO
    glBindVertexArrayOES(0);
}

- (void) blit:(GLfloat *)proj withEraseMask:(GLuint)maskTexture
{
	// use shader program
    WDShader *blitShader = [self.painting getShader:@"blitWithEraseMask"];
	glUseProgram(blitShader.program);
    
	glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
	glUniform1i([blitShader locationForUniform:@"texture"], 0);
	glUniform1f([blitShader locationForUniform:@"opacity"], opacity_);
    glUniform1i([blitShader locationForUniform:@"mask"], 1);
    
    // Bind the texture to be used
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureName);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, maskTexture);
    
    [self configureBlendMode];
    
    glBindVertexArrayOES(self.painting.quadVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // unbind VAO
    glBindVertexArrayOES(0);
}

- (void) modifyWithBlock:(void (^)())modifyBlock newTexture:(BOOL)useNewTexture undoBits:(BOOL)undo
{
    [self modifyWithBlock:modifyBlock newTexture:useNewTexture undoBits:undo bounds:self.painting.bounds];
}

- (void) modifyWithBlock:(void (^)())modifyBlock newTexture:(BOOL)useNewTexture undoBits:(BOOL)undo bounds:(CGRect)bounds
{
    self.isSaved = kWDSaveStatusUnsaved;

    if (undo) {
        [self registerUndoInRect:self.painting.bounds];
    } // otherwise assume caller is naturally invertible (flip, etc.) and handles its own undo
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.painting.reusableFramebuffer);
    
    GLuint tex = useNewTexture ? [self.painting generateTexture:(GLubyte *) loadedImageData_.bytes] : self.textureName;

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    
    GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status == GL_FRAMEBUFFER_COMPLETE) {
        glViewport(0, 0, self.painting.width, self.painting.height);
        
        WDCheckGLError();
        modifyBlock();
        WDCheckGLError();
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    [self invalidateThumbnail];
    
    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": self,
                                  @"rect": [NSValue valueWithCGRect:bounds]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerContentsChangedNotification
                                                            object:self.painting
                                                          userInfo:userInfo];
    }
    
    if (useNewTexture) {
        if (textureName_) {
            glDeleteTextures(1, &textureName_);
        }
        textureName_ = tex;
    }
}

- (void) duplicateLayer:(WDLayer *)layer copyThumbnail:(BOOL)copyThumbnail
{   
    [self modifyWithBlock:^{
        // use shader program
        WDShader *blitShader = [self.painting getShader:@"nonPremultipliedBlit"];
        glUseProgram(blitShader.program);
        
        GLuint width = self.painting.width;
        GLuint height = self.painting.height;
        
        glViewport(0, 0, width, height);
        
        // figure out the projection matrix
        GLfloat proj[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, width, 0, height, -1.0f, 1.0f, proj);
        
        glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
        glUniform1i([blitShader locationForUniform:@"texture"], 0);
        glUniform1f([blitShader locationForUniform:@"opacity"], 1.0f);
        
        // Bind the texture to be used
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, layer.textureName);
        
        glBlendFunc(GL_ONE, GL_ZERO);
        
        glBindVertexArrayOES(self.painting.quadVAO);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // unbind VAO
        glBindVertexArrayOES(0);
    } newTexture:NO undoBits:NO];
    
    self.opacity = layer.opacity;
    self.blendMode = layer.blendMode;
    self.visible = layer.visible;
    self.locked = layer.locked;
    self.alphaLocked = layer.alphaLocked;
    
    if (copyThumbnail) {
        thumbnail_ = [layer.thumbnail copy];
    }
}

- (void) merge:(WDLayer *)layer
{
    [self modifyWithBlock:^{
        WDShader *blitShader = [self.painting getShader:@"merge"];
        glUseProgram(blitShader.program);
        
        GLuint width = self.painting.width;
        GLuint height = self.painting.height;
        
        // figure out the projection matrix
        GLfloat proj[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, width, 0, height, -1.0f, 1.0f, proj);
        
        glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
        glUniform1i([blitShader locationForUniform:@"bottom"], (GLuint) 0);
        glUniform1f([blitShader locationForUniform:@"bottomOpacity"], self.opacity);
        glUniform1i([blitShader locationForUniform:@"top"], (GLuint) 1);
        glUniform1f([blitShader locationForUniform:@"topOpacity"], layer.opacity);
        glUniform1i([blitShader locationForUniform:@"blendMode"], layer.blendMode);
        
        glActiveTexture(GL_TEXTURE0);
        // Bind the texture to be used
        glBindTexture(GL_TEXTURE_2D, self.textureName);
        
        glActiveTexture(GL_TEXTURE1);
        // Bind the texture to be used
        glBindTexture(GL_TEXTURE_2D, layer.textureName);
        
        // set up premultiplied normal blend
        glBlendFunc(GL_ONE, GL_ZERO);
        
        glBindVertexArrayOES(painting_.quadVAO);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // unbind VAO
        glBindVertexArrayOES(0);
    } newTexture:YES undoBits:YES];
     
    // we're now at 100% opacity
    [self setOpacity:1.0f];
}

- (void) commitStroke:(CGRect)bounds color:(WDColor *)color erase:(BOOL)erase undoable:(BOOL)undoable
{
    if (undoable) {
        [self registerUndoInRect:bounds];
    }
    
    [self.painting beginSuppressingNotifications];
    
    [self modifyWithBlock:^{
        // handle viewing matrices
        GLfloat proj[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, self.painting.width, 0, self.painting.height, -1.0f, 1.0f, proj);
        
        WDShader *shader = erase ? [self.painting getShader:@"compositeWithEraseMask"] : [self.painting getShader:@"compositeWithMask"];
        glUseProgram(shader.program);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.textureName);
        // temporarily turn off linear interpolation to work around "emboss" bug
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, self.painting.activePaintTexture);
        
        glUniform1i([shader locationForUniform:@"texture"], 0);
        glUniform1i([shader locationForUniform:@"mask"], 1);
        glUniformMatrix4fv([shader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
        glUniform1i([shader locationForUniform:@"lockAlpha"], self.alphaLocked);
        
        if (!erase) {
            glUniform4f([shader locationForUniform:@"color"], color.red, color.green, color.blue, color.alpha);
        }
        
        glBlendFunc(GL_ONE, GL_ZERO);
        
        glBindVertexArrayOES(self.painting.quadVAO);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // unbind VAO
        glBindVertexArrayOES(0);
        
        // turn linear interpolation back on
        glBindTexture(GL_TEXTURE_2D, self.textureName);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    } newTexture:NO undoBits:NO bounds:bounds];
    
    [self.painting endSuppressingNotifications];
}

- (void) clear
{
    [self modifyWithBlock:^{
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        glClear(GL_COLOR_BUFFER_BIT);
    } newTexture:NO undoBits:YES];
}

- (void) fill:(WDColor *)color
{
    if (color.alpha < 1.0 || self.alphaLocked) {
        [self modifyWithBlock:^{
            // handle viewing matrices
            GLfloat proj[16];
            // setup projection matrix (orthographic)
            mat4f_LoadOrtho(0, self.painting.width, 0, self.painting.height, -1.0f, 1.0f, proj);
            
            WDShader *shader = [self.painting getShader:@"fill"];
            glUseProgram(shader.program);
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, self.textureName);
            
            glUniform1i([shader locationForUniform:@"texture"], 0);
            glUniformMatrix4fv([shader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
            glUniform1i([shader locationForUniform:@"lockAlpha"], self.alphaLocked);
            glUniform4f([shader locationForUniform:@"color"], color.red, color.green, color.blue, color.alpha);
            
            glBlendFunc(GL_ONE, GL_ZERO);
            
            glBindVertexArrayOES(self.painting.quadVAO);
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            // unbind VAO
            glBindVertexArrayOES(0);
        } newTexture:NO undoBits:YES];
    } else {
        [self modifyWithBlock:^{
            glClearColor(color.red, color.green, color.blue, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT);
        } newTexture:NO undoBits:YES];
    }
}

- (void) applyShader:(WDShader *)shader undoBits:(BOOL)undo
{
    [self modifyWithBlock:^{
        glClear(GL_COLOR_BUFFER_BIT);
        
        // handle viewing matrices
        GLfloat proj[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, self.painting.width, 0, self.painting.height, -1.0f, 1.0f, proj);
        
        glUseProgram(shader.program);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, self.textureName);
        
        glUniform1i([shader locationForUniform:@"texture"], 0);
        glUniformMatrix4fv([shader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
        
        glBlendFunc(GL_ONE, GL_ZERO);
        
        glBindVertexArrayOES(self.painting.quadVAO);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // unbind VAO
        glBindVertexArrayOES(0);
    } newTexture:YES undoBits:undo];
}

- (void) renderImage:(UIImage *)image transform:(CGAffineTransform)inTransform
{
    [EAGLContext setCurrentContext:self.painting.context];
    
    BOOL hasAlpha = [image hasAlpha];
    WDTexture *imageTexture = [WDTexture textureWithImage:image];
    
    [self modifyWithBlock:^{
        WDShader *blitShader = hasAlpha ? [self.painting getShader:@"unPremultipliedBlit"] : [self.painting getShader:@"nonPremultipliedBlit"];
        glUseProgram(blitShader.program);
        
        GLuint width = self.painting.width;
        GLuint height = self.painting.height;
        
        // figure out the projection matrix
        GLfloat proj[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, width, 0, height, -1.0f, 1.0f, proj);
        
        glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
        glUniform1i([blitShader locationForUniform:@"texture"], (GLuint) 0);
        glUniform1f([blitShader locationForUniform:@"opacity"], 1.0f);
        
        glActiveTexture(GL_TEXTURE0);
        // Bind the texture to be used
        glBindTexture(GL_TEXTURE_2D, imageTexture.textureName);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        
        CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
        WDGLRenderInRect(rect, inTransform);
        
        [imageTexture freeGLResources];
    } newTexture:NO undoBits:YES];
}

- (void) desaturate
{
    [self applyShader:[self.painting getShader:@"desaturate"] undoBits:YES];
}

- (void) tossColorAdjustments
{
    self.colorBalance = nil;
    self.hueSaturation = nil;
}

- (void) commitColorAdjustments
{
    WDShader *shader = nil;
    
    if (self.colorBalance) {
        shader = [self.painting getShader:@"colorBalanceBlit"];
    } else if (self.hueSaturation) {
        shader = [self.painting getShader:@"blitFromHueChromaLuma"];
    } else {
        return;
    }
        
    [self modifyWithBlock:^{
        // handle viewing matrices
        GLfloat proj[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, self.painting.width, 0, self.painting.height, -1.0f, 1.0f, proj);
        
        glUseProgram(shader.program);
        
        glActiveTexture(GL_TEXTURE0);
        if (self.hueSaturation) {
            glBindTexture(GL_TEXTURE_2D, self.hueChromaLuma);
        } else {
            glBindTexture(GL_TEXTURE_2D, self.textureName);
        }
        
        glUniform1i([shader locationForUniform:@"texture"], 0);
        glUniformMatrix4fv([shader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
        
        if (self.colorBalance) {
            glUniform1f([shader locationForUniform:@"redShift"], colorBalance_.redShift);
            glUniform1f([shader locationForUniform:@"greenShift"], colorBalance_.greenShift);
            glUniform1f([shader locationForUniform:@"blueShift"], colorBalance_.blueShift);
            glUniform1i([shader locationForUniform:@"premultiply"], 0);
        } else {
            glUniform1f([shader locationForUniform:@"hueShift"], hueSaturation_.hueShift);
            glUniform1f([shader locationForUniform:@"saturationShift"], hueSaturation_.saturationShift);
            glUniform1f([shader locationForUniform:@"brightnessShift"], hueSaturation_.brightnessShift);
            glUniform1i([shader locationForUniform:@"premultiply"], 0);
        }
        
        glBlendFunc(GL_ONE, GL_ZERO);
        
        glBindVertexArrayOES(self.painting.quadVAO);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        // unbind VAO
        glBindVertexArrayOES(0);
    } newTexture:NO undoBits:YES];
    
    self.colorBalance = nil;
    self.hueSaturation = nil;
}

- (void) invert
{
    [[[self.painting undoManager] prepareWithInvocationTarget:self] invert];
    [self applyShader:[self.painting getShader:@"invert"] undoBits:NO];
}

- (void) flipHorizontally
{
    [[[self.painting undoManager] prepareWithInvocationTarget:self] flipHorizontally];
    
    GLuint width = self.painting.width;
    
    CGAffineTransform flip = CGAffineTransformMakeTranslation(width, 0.0);
    flip = CGAffineTransformScale(flip, -1.0, 1.0);
    
    [self transform:flip undoBits:NO];
}

- (void) flipVertically
{
    [[[self.painting undoManager] prepareWithInvocationTarget:self] flipVertically];
    
    GLuint height = self.painting.height;
    
    CGAffineTransform flip = CGAffineTransformMakeTranslation(0.0, height);
    flip = CGAffineTransformScale(flip, 1.0, -1.0);
    
    [self transform:flip undoBits:NO];
}

- (void) transform:(CGAffineTransform)inTransform undoBits:(BOOL)undo
{
    [self modifyWithBlock:^{
        WDShader *blitShader = [self.painting getShader:@"nonPremultipliedBlit"];
        glUseProgram(blitShader.program);
        
        GLuint width = self.painting.width;
        GLuint height = self.painting.height;
        
        // figure out the projection matrix
        GLfloat proj[16], effectiveProj[16], final[16];
        // setup projection matrix (orthographic)
        mat4f_LoadOrtho(0, width, 0, height, -1.0f, 1.0f, proj);
        
        mat4f_LoadCGAffineTransform(effectiveProj, inTransform);
        mat4f_MultiplyMat4f(proj, effectiveProj, final);
        
        glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, final);
        glUniform1i([blitShader locationForUniform:@"texture"], (GLuint) 0);
        glUniform1f([blitShader locationForUniform:@"opacity"], 1.0f);
        
        glActiveTexture(GL_TEXTURE0);
        // Bind the texture to be used
        glBindTexture(GL_TEXTURE_2D, self.textureName);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        // set up premultiplied normal blend
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        glBindVertexArrayOES(painting_.quadVAO);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        glBindVertexArrayOES(0);
    } newTexture:YES undoBits:undo];
}

- (GLubyte *) bytes
{
    if (loadedImageData_) {
        return (GLubyte *) loadedImageData_.bytes;
    } else {
        return (GLubyte *) [self imageData].bytes;
    }
}

- (GLuint) textureName
{
    if (!textureName_) {
        textureName_ = [self.painting generateTexture:(GLubyte *) loadedImageData_.bytes];
        loadedImageData_ = nil;
        if (fragment_) {
            [fragment_ applyInLayer:self];
            
            [self invalidateThumbnail];
            
            if (!self.isSuppressingNotifications) {
                NSDictionary *userInfo = @{@"layer": self,
                                          @"rect": [NSValue valueWithCGRect:fragment_.bounds]};
                
                [[NSNotificationCenter defaultCenter] postNotificationName:WDLayerContentsChangedNotification
                                                                    object:self.painting
                                                                  userInfo:userInfo];
            }
            
            fragment_ = nil;
        }
    }
    
    return textureName_;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"%@ %@", [super description], self.uuid];
}

- (void) freeze
{
    fragment_ = [WDPaintingFragment paintingFragmentWithData:self.imageData bounds:self.painting.bounds];
    [self freeGLResources];
}

@end

