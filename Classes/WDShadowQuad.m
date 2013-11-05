//
//  WDImageQuad.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDShadowQuad.h"
#import "WDGLUtilities.h"
#import "WDTexture.h"
#import "WDShader.h"

@interface WDShadowQuad ()
@property (nonatomic) WDTexture *texture;
@end


@implementation WDShadowQuad {
    GLuint vao_;
    GLuint vbo_;
    CGRect lastRect;
}

@synthesize image;
@synthesize texture;
@synthesize dimension;
@synthesize shadowedRect;
@synthesize segment;

+ (WDShadowQuad *) imageQuadWithImage:(UIImage *)image dimension:(NSUInteger)dimension segment:(WDShadowSegment)segment
{
    WDShadowQuad *quad = [[WDShadowQuad alloc] init];
    
    quad.image = image;
    quad.dimension = dimension;
    quad.segment = segment;
    
    return quad;
}

- (void) freeBuffers
{
    if (vbo_) {
        glDeleteBuffers(1, &vbo_);
    }
    if (vao_) {
        glDeleteVertexArraysOES(1, &vao_);
    }
}

- (void) freeGLResources
{
    [texture freeGLResources];
    [self freeBuffers];
}

- (WDTexture *) texture
{
    if (!texture) {
        texture = [WDTexture textureWithImage:self.image];
        glBindTexture(GL_TEXTURE_2D, texture.textureName);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    }
    
    return texture;
}

- (CGRect) rectWithScale:(float)scale
{
    float actualDimension = self.dimension / scale;
    CGRect result = CGRectMake(0, 0, actualDimension, actualDimension);
    
    switch (segment) {
        case WDShadowSegmentTopLeft:
            result.origin = shadowedRect.origin;
            result = CGRectOffset(result, -actualDimension, -actualDimension);
            break;
        case WDShadowSegmentTop:
            result.origin = shadowedRect.origin;
            result = CGRectOffset(result, 0, -actualDimension);
            result.size.width = CGRectGetWidth(shadowedRect);
            break;
        case WDShadowSegmentTopRight:
            result.origin.x = CGRectGetWidth(shadowedRect);
            result.origin.y -= actualDimension;
            break;
        case WDShadowSegmentRight:
            result.origin.x = CGRectGetWidth(shadowedRect);
            result.size.height = CGRectGetHeight(shadowedRect);
            break;
        case WDShadowSegmentBottomRight:
            result.origin.x = CGRectGetWidth(shadowedRect);
            result.origin.y = CGRectGetHeight(shadowedRect);
            break;
        case WDShadowSegmentBottom:
            result.origin = shadowedRect.origin;
            result.origin.y = CGRectGetHeight(shadowedRect);
            result.size.width = CGRectGetWidth(shadowedRect);
            break;
        case WDShadowSegmentBottomLeft:
            result.origin = shadowedRect.origin;
            result = CGRectOffset(result, -actualDimension, CGRectGetHeight(shadowedRect));
            break;
        case WDShadowSegmentLeft:
            result.origin = shadowedRect.origin;
            result = CGRectOffset(result, -actualDimension, 0);
            result.size.height = CGRectGetHeight(shadowedRect);
            break;
    }
    
    return result;
}

+ (void) configureBlit:(GLfloat *)proj withShader:(WDShader *)blitShader
{
    glUseProgram(blitShader.program);
    
    glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, proj);
    glUniform1i([blitShader locationForUniform:@"texture"], (GLuint) 0);
    
    glActiveTexture(GL_TEXTURE0);
}

- (void) blitWithScale:(float)scale
{
    CGRect rect = [self rectWithScale:scale];
    
    if (!CGRectEqualToRect(rect, lastRect)) {
        [self freeBuffers];
        WDGLBuildQuadForRect(rect, CGAffineTransformIdentity, &vao_, &vbo_);
    }
    
    // Bind the texture to be used
    glBindTexture(GL_TEXTURE_2D, self.texture.textureName);
    glBindVertexArrayOES(vao_);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindVertexArrayOES(0);
}

@end
