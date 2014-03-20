//
//  WDBezierSegment.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

extern const float kDefaultFlatness;

@class WDBezierNode;
@class WD3DPoint;

@interface WDBezierSegment : NSObject

@property (nonatomic) WD3DPoint *start;
@property (nonatomic) WD3DPoint *outHandle;
@property (nonatomic) WD3DPoint *inHandle;
@property (nonatomic) WD3DPoint *end;

+ (WDBezierSegment *) segmentWithStart:(WDBezierNode *)start end:(WDBezierNode *)end;

- (BOOL) isDegenerate;
- (BOOL) isFlatWithTolerance:(float)tolerance;
- (WD3DPoint *) splitAtT:(float)t left:(WDBezierSegment **)L right:(WDBezierSegment **)R;
- (void) flattenIntoArray:(NSMutableArray *)points;

@end

