//
//  WDLayer.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "WDBlendModes.h"
#import "WDDataProvider.h"
#import "WDPainting.h"

@class WDColor;
@class WDColorBalance;
@class WDHueSaturation;
@class WDPaintingFragment;
@class WDXMLElement;

@protocol WDCoder;

@interface WDLayer : NSObject <WDCoding, NSCopying> {
    BOOL                visible_;
    BOOL                locked_;
    BOOL                alphaLocked_;
    
    float               opacity_;
    
    UIImage             *thumbnail_;
}

@property (nonatomic, weak) WDPainting *painting;
@property (nonatomic) NSData *imageData;

@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL locked;
@property (nonatomic, assign) BOOL alphaLocked;

@property (nonatomic, assign) WDBlendMode blendMode;
@property (nonatomic, assign) float opacity;

@property (nonatomic, readonly) BOOL editable;
@property (nonatomic, readonly) BOOL isSuppressingNotifications;

@property (nonatomic) WDColorBalance *colorBalance;
@property (nonatomic) WDHueSaturation *hueSaturation;

@property (nonatomic, readonly) UIImage *thumbnail;
@property (nonatomic, readonly) GLubyte *bytes;
@property (nonatomic, readonly) GLuint textureName;
@property (nonatomic, readonly) GLuint hueChromaLuma;

@property (nonatomic, readonly) NSString *uuid;
@property (nonatomic, assign) WDSaveStatus isSaved;

@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) BOOL clipWhenTransformed;

+ (WDLayer *) layer;
- (id) initWithUUID:(NSString *)uuid;

# pragma mark - Layer Operations

- (void) clear;
- (void) fill:(WDColor *)color;
- (void) merge:(WDLayer *)layer;
- (void) duplicateLayer:(WDLayer *)layer copyThumbnail:(BOOL)copyThumbnail;
- (void) commitStroke:(CGRect)bounds color:(WDColor *)color erase:(BOOL)erase undoable:(BOOL)undoable;
- (void) renderImage:(UIImage *)image transform:(CGAffineTransform)transform;
- (void) drawFragment:(WDPaintingFragment *)fragment;

- (void) toggleLocked;
- (void) toggleVisibility;
- (void) toggleAlphaLocked;

# pragma mark - Transform

- (void) flipHorizontally;
- (void) flipVertically;
- (void) transform:(CGAffineTransform)transform undoBits:(BOOL)undo;

#pragma mark - Imaging

- (NSData *) imageDataInRect:(CGRect)rect;

# pragma mark - Thumbnail

- (void) invalidateThumbnail;
- (NSInteger) thumbnailImageHeight;

#pragma mark - Blit

- (void) basicBlit:(GLfloat *)proj; // ignores transform, cached color shifts, etc.
- (void) blit:(GLfloat *)proj;
- (void) blit:(GLfloat *)proj withTransform:(CGAffineTransform)tX;
- (void) blit:(GLfloat *)proj withMask:(GLuint)maskTexture color:(WDColor *)color;
- (void) blit:(GLfloat *)proj withEraseMask:(GLuint)maskTexture;

#pragma mark - Color Adjustments

- (void) desaturate;
- (void) invert;
- (void) tossColorAdjustments;
- (void) commitColorAdjustments;

#pragma mark - Resource Management

- (void) enableLinearInterpolation:(BOOL)flag;
- (void) freeGLResources;
- (void) freeze;

@end

extern NSString *WDColorBalanceChanged;
extern NSString *WDHueSaturationChanged;
extern NSString *WDLayerVisibilityChanged;
extern NSString *WDLayerLockedStatusChanged;
extern NSString *WDLayerAlphaLockedStatusChanged;
extern NSString *WDLayerOpacityChanged;
extern NSString *WDLayerBlendModeChanged;
extern NSString *WDLayerContentsChangedNotification;
extern NSString *WDLayerThumbnailChangedNotification;
extern NSString *WDLayerTransformChangedNotification;

