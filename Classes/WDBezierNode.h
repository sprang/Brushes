//
//  WDBezierNode.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDCoding.h"

@class WD3DPoint;

@interface WDBezierNode : NSObject <WDCoding, NSCopying>

@property (nonatomic) WD3DPoint *inPoint;
@property (nonatomic) WD3DPoint *anchorPoint;
@property (nonatomic) WD3DPoint *outPoint;

@property (nonatomic) float inPressure;
@property (nonatomic) float anchorPressure;
@property (nonatomic) float outPressure;

@property (nonatomic, readonly) BOOL hasInPoint;
@property (nonatomic, readonly) BOOL hasOutPoint;
@property (nonatomic, readonly) BOOL isCorner;

+ (WDBezierNode *) bezierNodeWithAnchorPoint:(WD3DPoint *)pt;
+ (WDBezierNode *) bezierNodeWithInPoint:(WD3DPoint *)inPoint
                             anchorPoint:(WD3DPoint *)pt
                                outPoint:(WD3DPoint *)outPoint;

- (id) initWithAnchorPoint:(WD3DPoint *)pt;
- (id) initWithInPoint:(WD3DPoint *)inPoint
           anchorPoint:(WD3DPoint *)pt
              outPoint:(WD3DPoint *)outPoint;

- (WDBezierNode *) transform:(CGAffineTransform)transform;
- (WDBezierNode *) flippedNode;

@end

