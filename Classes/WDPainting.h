//
//  WDPainting.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "WDCoding.h"

@class WDBrush;
@class WDColor;
@class WDLayer;
@class WDPath;
@class WDRandom;
@class WDShader;
@class WDTexture;

@interface WDPainting : NSObject <WDCoding, NSCopying> {
    CGSize                  dimensions_;
    NSMutableArray          *layers_;
    
    NSUndoManager           *undoManager_;
    NSInteger               suppressNotifications_;
    
    GLfloat                 projection_[16];
    NSInteger               undoNesting_;
}

@property (nonatomic) CGSize dimensions;
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;
@property (nonatomic, readonly) CGRect bounds;
@property (nonatomic, readonly) CGPoint center;
@property (nonatomic, readonly) float aspectRatio;

@property (nonatomic, readonly) NSMutableArray *layers;
@property (weak, nonatomic, readonly) WDLayer *activeLayer;
@property (nonatomic, readonly) NSUInteger indexOfActiveLayer;

@property (nonatomic, strong) NSUndoManager *undoManager;

@property (nonatomic, readonly) BOOL isSuppressingNotifications;

@property (nonatomic, readonly) EAGLContext *context;
@property (nonatomic, readonly) GLuint quadVAO;
@property (nonatomic, readonly) GLuint quadVBO;
@property (nonatomic, readonly) GLuint reusableFramebuffer;
@property (nonatomic, readonly) NSDictionary *shaders;
@property (nonatomic, readonly) GLuint activePaintTexture;
@property (nonatomic) WDTexture *brushTexture;
@property (nonatomic) WDPath *activePath;
@property (nonatomic) NSCountedSet *brushes;
@property (nonatomic) NSMutableSet *undoneBrushes;
@property (nonatomic) NSCountedSet *colors;
@property (nonatomic, assign) NSUInteger strokeCount;
@property (nonatomic, strong) NSMutableDictionary *imageData;
@property (nonatomic) NSString *uuid;
@property (nonatomic) int changeCount;

@property (nonatomic) BOOL flattenMode;
@property (nonatomic, readonly) GLuint flattenedTexture;
@property (nonatomic) BOOL flattenedIsDirty;

+ (BOOL) supportsDeepColor;

- (id) initWithSize:(CGSize)size;

- (void) beginSuppressingNotifications;
- (void) endSuppressingNotifications;

- (void) activateLayerAtIndex:(NSUInteger)ix;
- (void) addLayer:(WDLayer *)layer;
- (void) removeLayer:(WDLayer *)layer;
- (void) deleteActiveLayer;
- (void) insertLayer:(WDLayer *)layer atIndex:(NSUInteger)index;
- (void) moveLayer:(WDLayer *)layer toIndex:(NSUInteger)dest;
- (void) mergeDown;
- (void) duplicateActiveLayer;
- (WDLayer *) layerWithUUID:(NSString *)uuid;

// these will draw the painting over a white background
- (UIImage *) image;
- (UIImage *) imageForCurrentState;
- (UIImage *) thumbnailImage;
- (CGSize) thumbnailSize;
- (NSData *) PNGRepresentation;
- (NSData *) JPEGRepresentation;

// returns data for the painting that includes uncommitted changes (like partially rendered strokes)
- (NSData *) PNGRepresentationForCurrentState;
- (NSData *) JPEGRepresentationForCurrentState;

- (UIImage *) imageWithSize:(CGSize)size backgroundColor:(UIColor *)color;
- (NSData *) imageDataWithSize:(CGSize)size backgroundColor:(UIColor *)color;

- (BOOL) canAddLayer;
- (BOOL) canDeleteLayer;
- (BOOL) canMergeDown;

- (void) reloadBrush;
- (void) preloadPaintTexture;

- (GLuint) generateTexture:(GLubyte *)pixels;
- (void) blit:(GLfloat *)proj;

- (CGRect) paintStroke:(WDPath *)path randomizer:(WDRandom *)randomizer clear:(BOOL)clearBuffer;
- (void) recordStroke:(WDPath *)path;

- (void) configureBrush:(WDBrush *)brush;

- (WDShader *) getShader:(NSString *)shaderKey;

// selection state management
- (void) clearSelectionStack;

@end

// Notifications
extern NSString *WDLayersReorderedNotification;
extern NSString *WDLayerAddedNotification;
extern NSString *WDLayerDeletedNotification;
extern NSString *WDActiveLayerChangedNotification;
extern NSString *WDStrokeAddedNotification;

