//
//  WD3DPoint.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

@interface WD3DPoint : NSObject

@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;
@property (nonatomic) CGPoint CGPoint;

+ (WD3DPoint *) pointWithX:(float)x y:(float)y z:(float)z;
- (float) distanceTo:(WD3DPoint *)pt;
- (WD3DPoint *) add:(WD3DPoint *)pt;
- (WD3DPoint *) subtract:(WD3DPoint *)pt;
- (float) dot:(WD3DPoint *)pt;
- (WD3DPoint *) unitVector;
- (BOOL) isZero;
- (float) magnitude;
- (WD3DPoint *) normalize;
- (WD3DPoint *) abs;
- (WD3DPoint *) multiplyByScalar:(float)scalar;
- (WD3DPoint *) transform:(CGAffineTransform)tX;
- (BOOL) isDegenerate;

@end
