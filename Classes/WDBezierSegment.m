//
//  WDBezierSegment.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WD3DPoint.h"
#import "WDBezierSegment.h"
#import "WDBezierNode.h"

const float kDefaultFlatness = 1;

@implementation WDBezierSegment

@synthesize start;
@synthesize outHandle;
@synthesize inHandle;
@synthesize end;

+ (WDBezierSegment *) segmentWithStart:(WDBezierNode *)start end:(WDBezierNode *)end
{
    WDBezierSegment *segment = [[WDBezierSegment alloc] init];
    
    segment.start = start.anchorPoint;
    segment.outHandle = start.outPoint;
    segment.inHandle = end.inPoint;
    segment.end = end.anchorPoint;
    
    return segment;
}

- (BOOL) isDegenerate
{
    return ([start isDegenerate] || [outHandle isDegenerate] || [inHandle isDegenerate] || [end isDegenerate]) ? YES : NO;
}

- (BOOL) isFlatWithTolerance:(float)tolerance
{
    if ([start isEqual:outHandle] && [inHandle isEqual:end]) {
        return YES;
    }
    
    WD3DPoint *delta = [end subtract:start];
    
    float dx = delta.x;
    float dy = delta.y;
    
    float d2 = fabs((outHandle.x - end.x) * dy - (outHandle.y - end.y) * dx);
    float d3 = fabs((inHandle.x - end.x) * dy - (inHandle.y - end.y) * dx);
    
    if ((d2 + d3) * (d2 + d3) <= tolerance * (dx * dx + dy * dy)) {
        return YES;
    }
    
    return NO;
}

- (WD3DPoint *) splitAtT:(float)t left:(WDBezierSegment **)L right:(WDBezierSegment **)R
{
    WD3DPoint *A, *B, *C, *D, *E, *F;
    
    A = [start add:[[outHandle subtract:start] multiplyByScalar:t]];
    B = [outHandle add:[[inHandle subtract:outHandle] multiplyByScalar:t]];
    C = [inHandle add:[[end subtract:inHandle] multiplyByScalar:t]];
    
    D = [A add:[[B subtract:A] multiplyByScalar:t]];
    E = [B add:[[C subtract:B] multiplyByScalar:t]];
    F = [D add:[[E subtract:D] multiplyByScalar:t]];
    
    if (L) {
        (*L).start = start;
        (*L).outHandle = A;
        (*L).inHandle = D;
        (*L).end = F;
    }
    
    if (R) {
        (*R).start = F;
        (*R).outHandle = E;
        (*R).inHandle = C;
        (*R).end = end;
    }
    
    if ((L || R) && [start isEqual:outHandle] && [inHandle isEqual:end]) {
        // no curves
        if (L) {
            (*L).inHandle = (*L).end;
        }
        if (R) {
            (*R).outHandle = (*R).start;
        }
    }
    
    return F;
}

- (void) flattenIntoArray:(NSMutableArray *)points
{
    if ([self isFlatWithTolerance:kDefaultFlatness]) {
        if (points.count == 0) {
            [points addObject:self.start];
        }
        [points addObject:self.end];
    } else {
        // recursive case
        WDBezierSegment *L = [[WDBezierSegment alloc] init];
        WDBezierSegment *R = [[WDBezierSegment alloc] init];
        
        [self splitAtT:0.5f left:&L right:&R];
        
        [L flattenIntoArray:points];
        [R flattenIntoArray:points];
    }
}

@end

