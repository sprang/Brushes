//
//  WDFreehandTool.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import "WD3DPoint.h"
#import "WDActiveState.h"
#import "WDAddPath.h"
#import "WDBezierNode.h"
#import "WDBristleGenerator.h"
#import "WDBrush.h"
#import "WDCanvas.h"
#import "WDColor.h"
#import "WDFreehandTool.h"
#import "WDLayer.h"
#import "WDPath.h"
#import "WDPanGestureRecognizer.h"
#import "WDRandom.h"
#import "WDUtilities.h"
#import "WDStylusManager.h"

#define kMaxError                   10.0f
#define kSpeedFactor                3
#define kBezierInterpolationSteps   5

@implementation WDFreehandTool {
    WDRandom *randomizer_;
}

@synthesize  eraseMode;
@synthesize realPressure;

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    accumulatedStrokePoints_ = [[NSMutableArray alloc] init];
    
    return self;
}

- (NSString *) iconName
{
    return @"brush.png";
}

- (id) landscapeIconName
{
    return @"brush_landscape.png";
}

- (CGPoint) documentLocationFromRecognizer:(UIGestureRecognizer *)recognizer
{
    WDCanvas *canvas = (WDCanvas *)recognizer.view;
    return [canvas convertPointToDocument:[recognizer locationInView:recognizer.view]];
}

- (void) averagePointsFrom:(NSUInteger)startIx to:(NSUInteger)endIx
{
    for (NSUInteger i = startIx; i < endIx; i++) {
        WD3DPoint *current = [pointsToFit_[i].anchorPoint multiplyByScalar:0.5];
        WD3DPoint *prev = [pointsToFit_[i-1].anchorPoint multiplyByScalar:0.25];
        WD3DPoint *next = [pointsToFit_[i+1].anchorPoint multiplyByScalar:0.25];
        
        pointsToFit_[i].anchorPoint = [current add:[prev add:next]];
    }
}

- (void) paintFittedPoints:(WDCanvas *)canvas
{
    BOOL    touchEnding = (pointsIndex_ != 5) ? YES : NO;
    int     loopBound = touchEnding ? pointsIndex_ - 1 : 4;
    int     drawBound = touchEnding ? pointsIndex_ - 1 : 2;
    
    [self averagePointsFrom:2 to:loopBound];
    
    for (int i = 1; i < loopBound; i++) {
        WD3DPoint *current = pointsToFit_[i].anchorPoint;
        WD3DPoint *prev = pointsToFit_[i-1].anchorPoint;
        WD3DPoint *next = pointsToFit_[i+1].anchorPoint;
        
        WD3DPoint *delta = [next subtract:prev];
        delta = [delta normalize];
        
        float inMagnitude = [prev distanceTo:current] / 3.0f;
        float outMagnitude = [next distanceTo:current] / 3.0f;

        WD3DPoint *in = [current subtract:[delta multiplyByScalar:inMagnitude]];
        WD3DPoint *out = [current add:[delta multiplyByScalar:outMagnitude]];
        
        pointsToFit_[i].inPoint = in;
        pointsToFit_[i].outPoint = out;
    }
    
    NSMutableArray *nodes = [NSMutableArray array];
    for (int i = 0; i <= drawBound; i++) {
        [nodes addObject:pointsToFit_[i]];
        
        if (i == 0 && accumulatedStrokePoints_.count) {
            [accumulatedStrokePoints_ removeLastObject];
        }
        [accumulatedStrokePoints_ addObject:pointsToFit_[i]];
    }
    WDPath *path = [[WDPath alloc] init];
    path.nodes = nodes;
    
    [self paintPath:path inCanvas:canvas];
    
    if (!touchEnding) {
        for (int i = 0; i < 3; i++) {
            pointsToFit_[i] = pointsToFit_[i+2];
        }
        pointsIndex_ = 3;
    }
}

- (void) gestureBegan:(WDPanGestureRecognizer *)recognizer
{    
    [super gestureBegan:recognizer];
    
    firstEver_ = YES;
    
    strokeBounds_ = CGRectZero;
    [accumulatedStrokePoints_ removeAllObjects];
    
    CGPoint location = [self documentLocationFromRecognizer:recognizer];
    
    // capture first point
    lastLocation_ = location;
    float pressure = 1.0f;
    
    // see if we've got real pressure
    self.realPressure = NO;
    if ([recognizer isKindOfClass:[WDPanGestureRecognizer class]]) {
        UITouch *touch = [recognizer.touches anyObject];
        pressure = [[WDStylusManager sharedStylusManager] pressureForTouch:touch realPressue:&realPressure];
    }
    
    WDBezierNode *node = [WDBezierNode bezierNodeWithAnchorPoint:[WD3DPoint pointWithX:location.x y:location.y z:pressure]];
    pointsToFit_[0] = node;
    pointsIndex_ = 1;
    
    clearBuffer_ = YES;
}

- (void) gestureMoved:(WDPanGestureRecognizer *)recognizer
{
    [super gestureMoved:recognizer];
    
    WDCanvas    *canvas = (WDCanvas *)recognizer.view;
    CGPoint     location = [self documentLocationFromRecognizer:recognizer];
    float       distanceMoved = WDDistance(location, lastLocation_);
    
    if (distanceMoved < 3.0 / canvas.scale) {
        // haven't moved far enough
        return;
    }
    
    float pressure = 1.0f;
    
    if (!self.realPressure) {
        if ([recognizer respondsToSelector:@selector(velocityInView:)]) {
            CGPoint velocity = [(UIPanGestureRecognizer *) recognizer velocityInView:recognizer.view];
            float   speed = WDMagnitude(velocity) / 1000.0f; // pixels/millisecond

            // account for view scale
            //speed /= canvas.scale;
            
            // convert speed into "pressure"
            pressure = WDSineCurve(1.0f - MIN(kSpeedFactor, speed) / kSpeedFactor);
            pressure = 1.0f - pressure;
        }
    } else {
        UITouch *touch = [recognizer.touches anyObject];
        pressure = [[WDStylusManager sharedStylusManager] pressureForTouch:touch realPressue:nil];
    }
        
    if (firstEver_) {
        pointsToFit_[0].inPressure = pressure;
        pointsToFit_[0].anchorPressure = pressure;
        pointsToFit_[0].outPressure = pressure;
        firstEver_ = NO;
    } else if (pointsIndex_ != 0) {
        // average out the pressures
        pressure = (pressure + pointsToFit_[pointsIndex_ - 1].anchorPressure) / 2;
    }
    
    pointsToFit_[pointsIndex_++] = [WDBezierNode bezierNodeWithAnchorPoint:[WD3DPoint pointWithX:location.x y:location.y z:pressure]];
    
    // special case: otherwise the 2nd overall point never gets averaged
    if (pointsIndex_ == 3) { // since we just incrementred pointsIndex (it was really just 2)
        [self averagePointsFrom:1 to:2];                 
    }
    
    if (pointsIndex_ == 5) {
        [self paintFittedPoints:canvas];
    }

    // save data for the next iteration
    lastLocation_ = location;
}

- (void) gestureEnded:(WDPanGestureRecognizer *)recognizer
{
    WDColor     *color = [WDActiveState sharedInstance].paintColor;
    WDBrush     *brush = [WDActiveState sharedInstance].brush;
    WDCanvas    *canvas = (WDCanvas *) recognizer.view;
    WDPainting  *painting = canvas.painting;
    
    CGPoint     location = [recognizer locationInView:recognizer.view];
    location = [canvas convertPointToDocument:location];
    
    if (!self.moved) { // draw a single stamp
        WDBezierNode *node = [WDBezierNode bezierNodeWithAnchorPoint:[WD3DPoint pointWithX:location.x y:location.y z:1.0]];
        WDPath *path = [[WDPath alloc] init];
        [path addNode:node];
        
        [accumulatedStrokePoints_ addObject:node];
        
        [self paintPath:path inCanvas:canvas];
    } else {
        [self paintFittedPoints:canvas];
    }
    
    if (CGRectIntersectsRect(strokeBounds_, painting.bounds)) {
        if (accumulatedStrokePoints_.count > 0) {
            WDPath *accumulatedPath = [[WDPath alloc] init];
            accumulatedPath.nodes = accumulatedStrokePoints_;
            accumulatedPath.color = color;
            accumulatedPath.brush = [brush copy];
            changeDocument(painting, [WDAddPath addPath:accumulatedPath erase:eraseMode layer:painting.activeLayer sourcePainting:painting]);
        }
    }
    
    if (CGRectIntersectsRect(strokeBounds_, painting.bounds)) {
        [painting.activeLayer commitStroke:strokeBounds_ color:color erase:eraseMode undoable:YES];
    }
    
    painting.activePath = nil;
    
    [super gestureEnded:recognizer];
}

- (void) gestureCanceled:(UIGestureRecognizer *)recognizer
{
    WDCanvas    *canvas = (WDCanvas *) recognizer.view;
    WDPainting  *painting = canvas.painting;
    
    painting.activePath = nil;
    [canvas drawView];
    
    [super gestureCanceled:recognizer];
}

- (void) paintPath:(WDPath *)path inCanvas:(WDCanvas *)canvas
{
    path.brush = [WDActiveState sharedInstance].brush;
    path.color = [WDActiveState sharedInstance].paintColor;
    path.action = eraseMode ? WDPathActionErase : WDPathActionPaint;
    
    if (clearBuffer_) {
        // depends on the path's brush
        randomizer_ = [path newRandomizer];
        lastRemainder_ = 0.f;
    }
    
    path.remainder = lastRemainder_;
    
    CGRect pathBounds = [canvas.painting paintStroke:path randomizer:randomizer_ clear:clearBuffer_];
    strokeBounds_ = WDUnionRect(strokeBounds_, pathBounds);
    lastRemainder_ = path.remainder;
    
    //[canvas drawViewInRect:pathBounds];
    
    clearBuffer_ = NO;
}

@end
