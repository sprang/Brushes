//
//  WDTool.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class WDCanvas;

@interface WDTool : NSObject {
    BOOL        moved_;
}

@property (unsafe_unretained, nonatomic, readonly) id icon;
@property (unsafe_unretained, nonatomic, readonly) id landscapeIcon;
@property (weak, nonatomic, readonly) NSString *iconName;
@property (weak, nonatomic, readonly) NSString *landscapeIconName;
@property (nonatomic, readonly) BOOL moved;

+ (WDTool *) tool;
- (void) activated;
- (void) deactivated;

- (void) buttonDoubleTapped;

- (void) gestureBegan:(UIGestureRecognizer *)recognizer;
- (void) gestureMoved:(UIGestureRecognizer *)recognizer;
- (void) gestureEnded:(UIGestureRecognizer *)recognizer;
- (void) gestureCanceled:(UIGestureRecognizer *)recognizer;

@end
