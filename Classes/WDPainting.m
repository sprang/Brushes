//
//  WDPainting.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import "UIImage+Resize.h"

#import "WDAddLayer.h"
#import "WDActiveState.h"
#import "WDBrush.h"
#import "WDCoder.h"
#import "WDColor.h"
#import "WDDecoder.h"
#import "WDDuplicateLayer.h"
#import "WDGLUtilities.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDShader.h"
#import "WDTexture.h"
#import "WDUtilities.h"
#import "UIDeviceHardware.h"

#import "gl_matrix.h"

#define kMaximumLayerCount          10
#define kMaximumThumbnailDimension  512

//#define NOISE YES

static NSString *WDActiveLayerKey = @"activeLayer";
static NSString *WDBrushesKey = @"brushes";
static NSString *WDChangeCountKey = @"changeCount";
static NSString *WDColorsKey = @"colors";
static NSString *WDDimensionsKey = @"dimensions"; 
static NSString *WDImageDatasKey = @"imageDatas";
static NSString *WDLayersKey = @"layers"; 
static NSString *WDSettingsKey = @"settings";
static NSString *WDStrokeCountKey = @"strokeCount";
static NSString *WDUndoneBrushesKey = @"undoneBrushes";
static NSString *WDUUIDKey = @"uuid";

@interface WDPainting ()
@property (nonatomic) NSMutableArray *undoSelectionStack;
@property (nonatomic) NSMutableArray *redoSelectionStack;
@end

@implementation WDPainting {
    WDBrush *lastBrush_;
}

@synthesize layers = layers_;
@synthesize activeLayer = activeLayer_;
@synthesize dimensions = dimensions_;
@synthesize undoManager = undoManager_;

@synthesize context = context_;
@synthesize quadVAO = quadVAO_;
@synthesize quadVBO = quadVBO_;
@synthesize brushTexture = brushTexture_;
@synthesize activePaintTexture = activePaintTexture_;
@synthesize activePath;
@synthesize brushes;
@synthesize undoneBrushes;
@synthesize colors;
@synthesize imageData;
@synthesize strokeCount;
@synthesize uuid;
@synthesize undoSelectionStack;
@synthesize redoSelectionStack;
@synthesize shaders;
@synthesize flattenMode;
@synthesize flattenedTexture;
@synthesize flattenedIsDirty;
@synthesize reusableFramebuffer;
@synthesize changeCount;

// Notifications
NSString *WDStrokeAddedNotification = @"WDStrokeAddedNotification";
NSString *WDLayersReorderedNotification = @"WDLayersReorderedNotification";
NSString *WDLayerAddedNotification = @"WDLayerAddedNotification";
NSString *WDLayerDeletedNotification = @"WDLayerDeletedNotification";
NSString *WDActiveLayerChangedNotification = @"WDActiveLayerChangedNotification";

- (id) initWithSize:(CGSize)size
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    // we don't want to notify when we're initing
    [self beginSuppressingNotifications];
    
    self.undoManager = [[NSUndoManager alloc] init];
    self.dimensions = size;
    
    layers_ = [[NSMutableArray alloc] init];
    
    self.imageData = [NSMutableDictionary dictionary];
    self.colors = [NSCountedSet set];
    self.brushes = [NSCountedSet set];
    self.undoneBrushes = [NSMutableSet set];
    self.strokeCount = 0;
    self.uuid = generateUUID();
    
    [self endSuppressingNotifications];
    
    [self registerForUndoNotifications];
    
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [EAGLContext setCurrentContext:self.context];
    glDeleteTextures(1, &activePaintTexture_);
    
    if (flattenedTexture) {
        glDeleteTextures(1, &flattenedTexture);
    }
    
    glDeleteBuffers(1, &quadVBO_);
    glDeleteVertexArraysOES(1, &quadVAO_);
    
    if (reusableFramebuffer) {
        glDeleteFramebuffers(1, &reusableFramebuffer);
    }
    
    // give layers a chance to free GL resources since they will no longer be able to access the GL context
    [self.layers makeObjectsPerformSelector:@selector(freeGLResources)];
    
    if (self.brushTexture) {
        [self.brushTexture freeGLResources];
    }
     
    WDCheckGLError();
    [EAGLContext setCurrentContext:nil];
}

- (void) beginSuppressingNotifications
{
    suppressNotifications_++;
}

- (void) endSuppressingNotifications
{
    suppressNotifications_--;
    
    if (suppressNotifications_ < 0) {
        NSLog(@"Unbalanced notification suppression: %d", (int) suppressNotifications_);
    }
}

- (BOOL) isSuppressingNotifications
{
    return (suppressNotifications_ > 0) ? YES : NO;
}

- (void) loadShaders
{
    NSString        *shadersJSONPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Shaders.json"];
    NSData          *JSONData = [NSData dataWithContentsOfFile:shadersJSONPath];
    NSError         *error = nil;
    NSDictionary    *shaderDict = [NSJSONSerialization JSONObjectWithData:JSONData options:0 error:&error];
    
    if (!shaderDict) {
        WDLog(@"Error loading 'Shaders.json': %@", error);
        return;
    }
    
    NSMutableDictionary *tempShaders = [NSMutableDictionary dictionary];
        
    for (NSString *key in shaderDict.keyEnumerator) {
        NSDictionary *description = shaderDict[key];
        NSString *vertex = description[@"vertex"];
        NSString *fragment = description[@"fragment"];
        NSArray *attributes = description[@"attributes"];
        NSArray *uniforms = description[@"uniforms"];
            
        WDShader *shader = [[WDShader alloc] initWithVertexShader:vertex
                                                   fragmentShader:fragment
                                                  attributesNames:attributes
                                                     uniformNames:uniforms];
        tempShaders[key] = shader;
    }
    WDCheckGLError();
    
    shaders = tempShaders;
}

- (WDShader *) getShader:(NSString *)shaderKey
{
    [EAGLContext setCurrentContext:self.context];
    return shaders[shaderKey];
}

- (EAGLContext *) context
{
    if (!context_) {
        context_ = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; 
        
        if (context_ && [EAGLContext setCurrentContext:context_]) {
            // configure some default GL state
            glEnable(GL_BLEND);
            glDisable(GL_DITHER);
            glDisable(GL_STENCIL_TEST);
            glDisable(GL_DEPTH_TEST);
        }
        
        [self loadShaders];
    }
    
    return context_;
}

- (CGRect) bounds
{
    return CGRectMake(0, 0, dimensions_.width, dimensions_.height);
}

- (CGPoint) center
{
    return CGPointMake(dimensions_.width / 2, dimensions_.height / 2);
}

- (void) setActiveLayer:(WDLayer *)layer
{
    if (!layer) {
        WDLog(@"Attempting to set nil active layer. Ignoring.");
        return;
    }
    
    if (layer == activeLayer_) {
        return;
    }
    
    NSUInteger oldIndex = self.indexOfActiveLayer;

    activeLayer_ = layer;

    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"old index": @(oldIndex)};
        [[NSNotificationCenter defaultCenter] postNotificationName:WDActiveLayerChangedNotification object:self userInfo:userInfo]; 
    }
}

- (void) activateLayerAtIndex:(NSUInteger)ix
{
    self.activeLayer = layers_[ix];
}

- (NSUInteger) indexOfActiveLayer
{
    return [layers_ indexOfObject:activeLayer_];
}

- (WDLayer *) layerWithUUID:(NSString *)layerUUID
{
    for (WDLayer *layer in layers_) {
        if ([layer.uuid isEqualToString:layerUUID]) {
            return layer;
        }
    }
    return nil;
}

- (void) removeLayer:(WDLayer *)layer
{
    [[undoManager_ prepareWithInvocationTarget:self] insertLayer:layer atIndex:[layers_ indexOfObject:layer]];    
    
    if (layer == activeLayer_ && layers_.count > 1) {
        // choose another layer to be active before we remove it
        NSInteger index = self.indexOfActiveLayer;
        if (index >= 1) {
            index--;
        } else {
            index = 1;
        }
        self.activeLayer = layers_[index];
    }
    
    // do this before decrementing index
    NSUInteger index = [layers_ indexOfObject:layer];
    NSValue *dirtyRect = [NSValue valueWithCGRect:self.bounds];

    [layers_ removeObject:layer];
    [layer freeze];
   
    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"index": @(index), @"rect": dirtyRect, @"layer": layer};
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:WDLayerDeletedNotification object:self userInfo:userInfo]];
    }
}

- (void) insertLayer:(WDLayer *)layer atIndex:(NSUInteger)index
{
    [[undoManager_ prepareWithInvocationTarget:self] removeLayer:layer];
    
    [layers_ insertObject:layer atIndex:index];
    
    if (!self.isSuppressingNotifications) {
        NSDictionary *userInfo = @{@"layer": layer, @"rect": [NSValue valueWithCGRect:self.bounds]};
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:WDLayerAddedNotification object:self userInfo:userInfo]];
    }
}

- (void) addLayer:(WDLayer *)layer;
{
    layer.painting = self;
    [self insertLayer:layer atIndex:self.indexOfActiveLayer+1];
    self.activeLayer = layer;
}

- (BOOL) canMergeDown
{
    if (self.indexOfActiveLayer == 0 || self.indexOfActiveLayer == NSNotFound) {
        return NO;
    }
    
    WDLayer *bottomLayer = layers_[(self.indexOfActiveLayer - 1)];
    
    return bottomLayer.editable;
}

- (void) mergeDown
{
    if (self.indexOfActiveLayer < 1) {
        return;
    }
    
    WDLayer *bottom = layers_[(self.indexOfActiveLayer - 1)];
    WDLayer *top = self.activeLayer;
    
    //[self addAction:[WDAction mergeLayerDownAction:self.activeLayerIndex]];
    
    [bottom merge:top];

    [self deleteActiveLayer];
    self.activeLayer = bottom;
}

- (void) duplicateActiveLayer
{
#if WD_DEBUG
    NSDate *date = [NSDate date];
#endif
    
    WDLayer *layer = self.activeLayer;
    changeDocument(self, [WDAddLayer addLayerAtIndex:self.indexOfActiveLayer+1]);
    changeDocument(self, [WDDuplicateLayer duplicateLayer:layer toLayer:self.activeLayer]);
    
#if WD_DEBUG
    NSLog(@"Duplicate layer: %.3f seconds.", -[date timeIntervalSinceNow]);
#endif
}

- (BOOL) canAddLayer
{
    return (layers_.count < kMaximumLayerCount) ? YES : NO;
}

- (BOOL) canDeleteLayer
{
    return self.activeLayer.locked ? NO : YES;
}
            
- (void) deleteActiveLayer
{
    WDLayer *layerToDelete = self.activeLayer;
    if (layers_.count == 1) {
        // deleting last layer so add a blank one: if you do this in removeLayer, the added layer will generate yet another if it is undone
        changeDocument(self, [WDAddLayer addLayerAtIndex:1]);
    }
    [self removeLayer:layerToDelete];
}
         
- (void) moveLayer:(WDLayer *)layer toIndex:(NSUInteger)dest
{
    if ([self.layers indexOfObject:layer] == dest) {
        // older recordings sometimes trigger this
        return;
    }
    
    [self beginSuppressingNotifications];
    
    WDLayer *expectedActiveLayer = self.activeLayer;
    
    [self removeLayer:layer];
    [self insertLayer:layer atIndex:dest];
    
    [self endSuppressingNotifications];
    
    // make sure the active layer is what we expect it to be
    self.activeLayer = expectedActiveLayer;
    
    if (!self.isSuppressingNotifications) {
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:WDLayersReorderedNotification object:self]];
    }
}

- (UIImage *) imageForData:(NSData *)data size:(CGSize)size
{
    size_t width = size.width;
    size_t height = size.height;
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate((void *) data.bytes, width, height, 8, width*4,
                                             colorSpaceRef, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpaceRef);
    
    return result;
}

- (UIImage *) imageWithSize:(CGSize)size backgroundColor:(UIColor *)color
{
    NSData *data = [self imageDataWithSize:size backgroundColor:color];
    return [self imageForData:data size:size];
}

- (NSData *) imageDataWithSize:(CGSize)size backgroundColor:(UIColor *)color
{
    NSData *result = nil;
    
    // make sure the painting's context is current
    [EAGLContext setCurrentContext:self.context];
    
    GLuint width = (GLuint) size.width;
    GLuint height = (GLuint) size.height;
    
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
        GLsizei viewportWidth = MAX(width, self.width);
        GLsizei viewportHeight = MAX(height, self.height);
        glViewport(0, 0, viewportWidth, viewportHeight);
        
        // figure out the projection matrix
        GLfloat  effectiveProj[16], final[16];
        CGAffineTransform scale  = CGAffineTransformMakeScale((float) width / viewportWidth,
                                                              (float) height / viewportHeight);
        mat4f_LoadCGAffineTransform(effectiveProj, scale);
        mat4f_MultiplyMat4f(projection_, effectiveProj, final);
        
        CGFloat r, g, b, w, a;
        if ([color getRed:&r green:&g blue:&b alpha:&a]) {
            glClearColor(r, g, b, a);
        } else if ([color getWhite:&w alpha:&a]){
            glClearColor(w, w, w, a);
        } else {
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        }
        
        glClear(GL_COLOR_BUFFER_BIT);
        
        // blit each layer
        for (WDLayer *layer in self.layers) {
            if (layer.visible) {
                [layer basicBlit:final];
            }
        }
        
        // color buffer should now have layer contents
        size_t dataSize = sizeof(UInt8) * width * 4 * height;
        UInt8 *pixels = malloc(dataSize);
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
        
        result = [NSData dataWithBytes:pixels length:dataSize];
        free(pixels);
    } else {
        NSLog(@"-[WDPainting imageWithSize:]: Incomplete Framebuffer!");
    }
    
    glDeleteFramebuffers(1, &framebuffer);
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    
    return result;
}

- (UIImage *) imageForCurrentStateWithBackgroundColor:(UIColor *)color
{
    NSData *data = [self imageDataForCurrentStateWithBackgroundColor:color];
    return [self imageForData:data size:self.dimensions];
}

- (NSData *) imageDataForCurrentStateWithBackgroundColor:(UIColor *)color
{
    NSData *result = nil;
    
    // make sure the painting's context is current
    [EAGLContext setCurrentContext:self.context];
    
    GLuint width = (GLuint) dimensions_.width;
    GLuint height = (GLuint) dimensions_.height;
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.reusableFramebuffer);
    
    GLuint colorRenderbuffer;
    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, width, height);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    GLint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status == GL_FRAMEBUFFER_COMPLETE) {
        GLsizei viewportWidth = MAX(width, self.width);
        GLsizei viewportHeight = MAX(height, self.height);
        glViewport(0, 0, viewportWidth, viewportHeight);
        
        // figure out the projection matrix
        GLfloat  effectiveProj[16], final[16];
        CGAffineTransform scale  = CGAffineTransformMakeScale((float) width / viewportWidth,
                                                              (float) height / viewportHeight);
        mat4f_LoadCGAffineTransform(effectiveProj, scale);
        mat4f_MultiplyMat4f(projection_, effectiveProj, final);
        
        CGFloat r, g, b, w, a;
        if ([color getRed:&r green:&g blue:&b alpha:&a]) {
            glClearColor(r, g, b, a);
        } else if ([color getWhite:&w alpha:&a]){
            glClearColor(w, w, w, a);
        } else {
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        }
        
        glClear(GL_COLOR_BUFFER_BIT);
        
        // blit each layer
        for (WDLayer *layer in self.layers) {
            if (!layer.visible) {
                continue;
            }
            
            if (self.activeLayer == layer && self.activePath) {
                if (self.activePath.action == WDPathActionErase) {
                    [layer blit:final withEraseMask:self.activePaintTexture];
                } else {
                    [layer blit:final withMask:self.activePaintTexture color:self.activePath.color];
                }
            } else {
                [layer blit:final];
            }
        }
        
        // color buffer should now have layer contents
        size_t dataSize = sizeof(UInt8) * width * 4 * height;
        UInt8 *pixels = malloc(dataSize);
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, pixels);
        
        result = [NSData dataWithBytes:pixels length:dataSize];
        free(pixels);
    } else {
        NSLog(@"-[WDPainting imageWithSize:]: Incomplete Framebuffer!");
    }
    
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    
    return result;
}

- (CGSize) thumbnailSize
{
    GLuint width, height;
    // figure out the width and height of the thumbnail
    if (self.width <= 0 || self.height <= 0) {
        // we're in really bad shape to hit this block, but do what we can
        width = height = kMaximumThumbnailDimension;
    } else if (self.width > self.height) {
        width = kMaximumThumbnailDimension;
        height = (GLuint) floor(self.height / self.width * (float) width);
    } else {
        height = kMaximumThumbnailDimension;
        width = (GLuint) floor(self.width / self.height * (float) height);
    }
    return CGSizeMake(width, height);
}

- (UIImage *) thumbnailImage
{
    CGSize size = [self thumbnailSize];
    GLuint width = size.width, height = size.height;
    
    UIImage *thumbnail = nil;
    if (self.context) {
        // draw it at 2x
        thumbnail = [self imageWithSize:CGSizeMake(width*2, height*2) backgroundColor:[UIColor whiteColor]];
        // and downsample back to 1x to avoid ugly aliasing
        thumbnail = [thumbnail resizedImage:CGSizeMake(width, height)
                       interpolationQuality:kCGInterpolationHigh];
    }
    
    if (!thumbnail) {
        // OpenGL isn't working, generate a blank image as a placeholder
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
        CGContextSetRGBFillColor(context, (CGFloat)0.0, (CGFloat)0.0, (CGFloat)0.0, (CGFloat)1.0 );
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        thumbnail = [UIImage imageWithCGImage:cgImage];
        CGImageRelease(cgImage);
    }
    return thumbnail;
}

- (UIImage *) image
{
    return [self imageWithSize:self.dimensions backgroundColor:[UIColor whiteColor]];
}

- (UIImage *) imageForCurrentState
{
    return [self imageForCurrentStateWithBackgroundColor:[UIColor whiteColor]];
}

- (NSData *) PNGRepresentation
{
    UIImage *image = [self imageWithSize:self.dimensions backgroundColor:[UIColor clearColor]];
    return UIImagePNGRepresentation(image);
}

- (NSData *) JPEGRepresentation
{
    UIImage *image = [self imageWithSize:self.dimensions backgroundColor:[UIColor whiteColor]];
    return UIImageJPEGRepresentation(image, 0.95f);
}

- (NSData *) PNGRepresentationForCurrentState
{
    UIImage *image = [self imageForCurrentStateWithBackgroundColor:[UIColor clearColor]];
    return UIImagePNGRepresentation(image);
}

- (NSData *) JPEGRepresentationForCurrentState
{
    UIImage *image = [self imageForCurrentStateWithBackgroundColor:[UIColor whiteColor]];
    return UIImageJPEGRepresentation(image, 0.95f);
}

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep
{
    [coder encodeInteger:(int)[layers_ indexOfObject:activeLayer_] forKey:WDActiveLayerKey];
    [coder encodeSize:dimensions_ forKey:WDDimensionsKey];
    [coder encodeInteger:(int)self.strokeCount forKey:WDStrokeCountKey];
    [coder encodeString:self.uuid forKey:WDUUIDKey];
    [coder encodeInteger:self.changeCount forKey:WDChangeCountKey];
    if (deep) {
        [coder encodeArray:layers_ forKey:WDLayersKey];
        [coder encodeDictionary:self.imageData forKey:WDImageDatasKey];
        [coder encodeCountedSet:self.brushes forKey:WDBrushesKey];
        [coder encodeCountedSet:self.colors forKey:WDColorsKey];
        [coder encodeArray:self.undoneBrushes.allObjects forKey:WDUndoneBrushesKey];
    }
}

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    if (!self.undoManager) {
        self.undoManager = [[NSUndoManager alloc] init];
        [self registerForUndoNotifications];
    }
    
    if (deep) {
        layers_ = [decoder decodeArrayForKey:WDLayersKey];
        for (WDLayer *layer in layers_) {
            layer.painting = self;
        }
        self.imageData = [decoder decodeDictionaryForKey:WDImageDatasKey];
        self.brushes = [decoder decodeObjectForKey:WDBrushesKey];
        self.undoneBrushes = [NSMutableSet setWithArray:[decoder decodeObjectForKey:WDUndoneBrushesKey]];
        self.colors = [decoder decodeObjectForKey:WDColorsKey];
    }
    NSUInteger activeLayerIndex = [decoder decodeIntegerForKey:WDActiveLayerKey];
    
    if (activeLayerIndex < layers_.count) {
        activeLayer_ = layers_[activeLayerIndex];
    } else {
        activeLayer_ = [layers_ lastObject];
    }
  
    self.dimensions = [decoder decodeSizeForKey:WDDimensionsKey];
    self.strokeCount = [decoder decodeIntegerForKey:WDStrokeCountKey];
    self.uuid = [decoder decodeStringForKey:WDUUIDKey];
    self.changeCount = [decoder decodeIntegerForKey:WDChangeCountKey];
}

- (void) setDimensions:(CGSize)dimensions
{
    dimensions_ = dimensions;    
    mat4f_LoadOrtho(0, dimensions_.width, 0, dimensions_.height, -1.0f, 1.0f, projection_);
}

- (float) width
{
    return dimensions_.width;
}

- (float) height
{
    return dimensions_.height;
}

- (float) aspectRatio
{
    return dimensions_.width / dimensions_.height;
}

- (id) copyWithZone:(NSZone *)zone
{
    WDPainting *painting = [[WDPainting alloc] init];
    
    painting->dimensions_ = dimensions_;
    painting.imageData = self.imageData.copy;

    // copy layers
    painting->layers_ = [[NSMutableArray alloc] initWithArray:layers_ copyItems:YES];
    [painting->layers_ makeObjectsPerformSelector:@selector(setPainting:) withObject:painting];

    // active layer
    painting->activeLayer_ = painting->layers_[[layers_ indexOfObject:activeLayer_]];
    
    return painting;
}

- (GLuint) generateTexture:(GLubyte *)pixels 
{
    return [self generateTexture:pixels deepColor:NO];
}

- (GLuint) generateTexture:(GLubyte *)pixels deepColor:(BOOL)deepColor
{
    [EAGLContext setCurrentContext:self.context];
    WDCheckGLError();
    
    GLuint      textureName;
    
    glGenTextures(1, &textureName);
    glBindTexture(GL_TEXTURE_2D, textureName);
    
    // Set up filter and wrap modes for this texture object
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    GLuint      width = (GLuint) self.dimensions.width;
    GLuint      height = (GLuint) self.dimensions.height;
    GLenum      format = GL_RGBA;
    GLenum      type = deepColor ? GL_HALF_FLOAT_OES : GL_UNSIGNED_BYTE;
    NSUInteger  bytesPerPixel = deepColor ? 8 : 4;
    
    if (!pixels) {
        pixels = calloc((size_t) (self.width * bytesPerPixel * self.height), sizeof(GLubyte));
        glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, type, pixels);
        free(pixels);
    } else {
        glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, type, pixels);
    }
    
    WDCheckGLError();
    return textureName;
}

- (GLuint) quadVAO
{
    if (!quadVAO_) {
        [EAGLContext setCurrentContext:self.context];
        CGRect bounds = CGRectMake(0, 0, self.width, self.height);
        WDGLBuildQuadForRect(bounds, CGAffineTransformIdentity, &quadVAO_, &quadVBO_);
    }
    
    return quadVAO_;
}

+ (BOOL) supportsDeepColor
{
    return WDCanUseHDTextures();
}

- (void) preloadPaintTexture
{
    [self activePaintTexture];
}

- (GLuint) activePaintTexture
{
    if (!activePaintTexture_) {
        activePaintTexture_ = [self generateTexture:nil deepColor:[WDPainting supportsDeepColor]];
    }
    
    return activePaintTexture_;
}

- (void) reloadBrush
{
    [EAGLContext setCurrentContext:self.context];
    
    [brushTexture_ freeGLResources];
    brushTexture_ = nil;
}

- (WDTexture *) brushTexture:(WDBrush *)brush
{
    [EAGLContext setCurrentContext:self.context];
    
    if (!brushTexture_ || (brush != lastBrush_)) {
        WDStampGenerator *gen = brush.generator;
        
        if (brushTexture_) {
            [brushTexture_ freeGLResources];
        }
        
        brushTexture_ = [WDTexture alphaTextureWithImage:gen.stamp];
        lastBrush_ = brush;
    }
    
    return brushTexture_;
}

- (void) configureBrush:(WDBrush *)brush
{
    WDShader *brushShader = [self getShader:@"brush"];
    glUseProgram(brushShader.program);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, [self brushTexture:brush].textureName);
    
    glUniform1i([brushShader locationForUniform:@"texture"], 0);
    glUniformMatrix4fv([brushShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, projection_);
    WDCheckGLError();
}

- (GLuint) reusableFramebuffer
{
    if (!reusableFramebuffer) {
        glGenFramebuffers(1, &reusableFramebuffer);
    }
    
    return reusableFramebuffer;
}

- (CGRect) paintStroke:(WDPath *)path randomizer:(WDRandom *)randomizer clear:(BOOL)clearBuffer
{
    self.activePath = path;
    
    CGRect pathBounds = CGRectZero;
    
    [EAGLContext setCurrentContext:self.context];
    glBindFramebuffer(GL_FRAMEBUFFER, self.reusableFramebuffer);
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.activePaintTexture, 0);
    
    GLuint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status == GL_FRAMEBUFFER_COMPLETE) {
        glViewport(0, 0, self.width, self.height);
        
        if (clearBuffer) {
            glClearColor(0, 0, 0, 0);
            glClear(GL_COLOR_BUFFER_BIT);
        }

        [self configureBrush:path.brush];
        pathBounds = [path paint:randomizer];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    WDCheckGLError();

    NSDictionary *userInfo = @{@"rect": [NSValue valueWithCGRect:pathBounds]};
    [[NSNotificationCenter defaultCenter] postNotificationName:WDStrokeAddedNotification object:self userInfo:userInfo];

    return pathBounds;
}

- (void) forgetStroke:(WDPath *)path
{
    [[undoManager_ prepareWithInvocationTarget:self] recordStroke:path];    
    
    [self.brushes removeObject:path.brush];
    if (![self.brushes containsObject:path.brush]) {
        [self.undoneBrushes addObject:path.brush];
    }
    [self.colors removeObject:path.color];
    --self.strokeCount;
}

- (void) recordStroke:(WDPath *)path
{    
    [[undoManager_ prepareWithInvocationTarget:self] forgetStroke:path];    

    [self.brushes addObject:path.brush];
    [self.undoneBrushes removeObject:path.brush];
    [self.colors addObject:path.color];
    ++self.strokeCount;
}

- (void) setFlattenMode:(BOOL)inFlattenMode
{
    if (inFlattenMode && self.layers.count == 1) {
        // this is counter-productive if we only have one layer
        flattenedIsDirty = NO;
        
        if (flattenedTexture) {
            glDeleteTextures(1, &flattenedTexture);
            flattenedTexture = 0;
        }
        
        flattenMode = NO;
        return;
    }
    
    flattenMode = inFlattenMode;
    
    if (flattenMode && (flattenedIsDirty || !flattenedTexture)) {
        if (!flattenedTexture) {
            flattenedTexture = [self generateTexture:NULL deepColor:NO];
        }
        
        // make sure the painting's context is current
        [EAGLContext setCurrentContext:self.context];
        
        GLuint framebuffer;
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, flattenedTexture, 0);
        GLint status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if (status == GL_FRAMEBUFFER_COMPLETE) {
            glViewport(0, 0, self.width, self.height);
            
            glClearColor(1, 1, 1, 1);
            glClear(GL_COLOR_BUFFER_BIT);
            
            // blit each layer
            for (WDLayer *layer in self.layers) {
                if (layer.visible) {
                    [layer basicBlit:projection_];
                }
            }
        } else {
            NSLog(@"-[WDPainting setFlattenMode:]: Incomplete Framebuffer!");
        }

        flattenedIsDirty = NO;
        glDeleteFramebuffers(1, &framebuffer);
    }
}

- (void) blitFlattenedTexture:(GLfloat *)projection
{
    // use shader program
    WDShader *blitShader = [self getShader:@"straightBlit"];
	glUseProgram(blitShader.program);
    
	glUniformMatrix4fv([blitShader locationForUniform:@"modelViewProjectionMatrix"], 1, GL_FALSE, projection);
	glUniform1i([blitShader locationForUniform:@"texture"], 0);
    
    // Bind the texture to be used
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, flattenedTexture);
    
    glBindVertexArrayOES(self.quadVAO);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // unbind VAO
    glBindVertexArrayOES(0);
}
    
- (void) blit:(GLfloat *)projection
{
    if (self.flattenMode) {
        [self blitFlattenedTexture:projection];
        return;
    }
    
    for (WDLayer *layer in self.layers) {
        if (!layer.visible) {
            continue;
        }
        
        if (self.activeLayer == layer && self.activePath) {
            if (self.activePath.action == WDPathActionErase) {
                [layer blit:projection withEraseMask:self.activePaintTexture];
            } else {
                [layer blit:projection withMask:self.activePaintTexture color:self.activePath.color];
            }
        } else {
            [layer blit:projection];
        }
    }
}

#pragma mark -- Selection State Management

const NSString *WDSelectionStateActiveLayer = @"WDSelectionStateActiveLayer";

- (void) registerForUndoNotifications
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter]; 

    [nc addObserver:self selector:@selector(undoGroupOpened:)
               name:NSUndoManagerDidOpenUndoGroupNotification
             object:undoManager_];
    
    [nc addObserver:self selector:@selector(undoGroupClosed:)
               name:NSUndoManagerDidCloseUndoGroupNotification
             object:undoManager_];
    
    [nc addObserver:self selector:@selector(didUndo:)
               name:NSUndoManagerDidUndoChangeNotification
             object:undoManager_];
    
    [nc addObserver:self selector:@selector(didRedo:)
               name:NSUndoManagerDidRedoChangeNotification
             object:undoManager_];
    
    self.undoSelectionStack = [NSMutableArray array];
    self.redoSelectionStack = [NSMutableArray array];
}

- (void) clearSelectionStack
{
    [self.undoSelectionStack removeAllObjects];
    [self.redoSelectionStack removeAllObjects];
    undoNesting_ = 0;
}

- (NSDictionary *) selectionState
{
    return @{WDSelectionStateActiveLayer: self.activeLayer.uuid};
}

- (void) undoGroupOpened:(NSNotification *)aNotification
{
    if ((undoNesting_ == 0) && !undoManager_.isUndoing && !undoManager_.isRedoing && self.activeLayer) {
        [redoSelectionStack removeAllObjects];
        
        NSMutableDictionary *restoreState = [NSMutableDictionary dictionaryWithObject:[self selectionState]
                                                                               forKey:@"undo"];
        [undoSelectionStack addObject:restoreState];
    }
    
    undoNesting_++;
}

- (void) undoGroupClosed:(NSNotification *)aNotification
{
    undoNesting_--;
    
    if ((undoNesting_ == 0) && !undoManager_.isUndoing && !undoManager_.isRedoing && self.activeLayer) {
        [undoSelectionStack lastObject][@"redo"] = [self selectionState];
    }
    
    flattenedIsDirty = YES;
}

- (void) didUndo:(NSNotification *)aNotification
{
    NSDictionary *restoreState = [undoSelectionStack lastObject][@"undo"];
    
    self.activeLayer = [self layerWithUUID:restoreState[WDSelectionStateActiveLayer]];
        
    if (undoSelectionStack.count) {
        [redoSelectionStack addObject:[undoSelectionStack lastObject]];
        [undoSelectionStack removeLastObject];
    }
    
    flattenedIsDirty = YES;
}

- (void) didRedo:(NSNotification *)aNotification
{
    NSDictionary *restoreState = [redoSelectionStack lastObject][@"redo"];
    
    self.activeLayer = [self layerWithUUID:restoreState[WDSelectionStateActiveLayer]];
    
    if (redoSelectionStack.count) {
        [undoSelectionStack addObject:[redoSelectionStack lastObject]];
        [redoSelectionStack removeLastObject];
    }
    
    flattenedIsDirty = YES;
}

@end

