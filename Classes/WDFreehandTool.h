//
//  WDFreehandTool.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import "WDTool.h"

@class WDBrush;
@class WDPath;
@class WDBezierNode;
@class WDPanGestureRecognizer;

@interface WDFreehandTool : WDTool {
    BOOL                    firstEver_;
    CGPoint                 lastLocation_;
    float                   lastRemainder_;
    
    BOOL                    clearBuffer_;
    CGRect                  strokeBounds_;
    
    NSMutableArray          *accumulatedStrokePoints_;
    WDBezierNode            *pointsToFit_[5];
    int                     pointsIndex_;
}

@property (nonatomic) BOOL eraseMode;
@property (nonatomic) BOOL realPressure;

- (void) paintPath:(WDPath *)path inCanvas:(WDCanvas *)canvas;

- (void) gestureBegan:(WDPanGestureRecognizer *)recognizer;
- (void) gestureMoved:(WDPanGestureRecognizer *)recognizer;
- (void) gestureEnded:(WDPanGestureRecognizer *)recognizer;

@end
