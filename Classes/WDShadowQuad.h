//
//  WDImageQuad.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

@class WDShader;

typedef enum {
    WDShadowSegmentTopLeft = 0,
    WDShadowSegmentTop,
    WDShadowSegmentTopRight,
    WDShadowSegmentRight,
    WDShadowSegmentBottomRight,
    WDShadowSegmentBottom,
    WDShadowSegmentBottomLeft,
    WDShadowSegmentLeft
} WDShadowSegment;

@interface WDShadowQuad : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic) NSUInteger dimension;
@property (nonatomic) CGRect shadowedRect;
@property (nonatomic) WDShadowSegment segment;

+ (WDShadowQuad *) imageQuadWithImage:(UIImage *)image dimension:(NSUInteger)dimension segment:(WDShadowSegment)segment;

+ (void) configureBlit:(GLfloat *)proj withShader:(WDShader *)shader;
- (void) blitWithScale:(float)scale;

@end
