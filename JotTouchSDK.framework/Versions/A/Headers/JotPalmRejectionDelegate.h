//
//  PalmRejectionDelegate.h
//  PalmRejectionExampleApp
//
//  Created on 9/14/12.
//  Copyright (c) 2012 Adonit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JotTouch.h"

@class JotPalmGestureRecognizer;

@protocol JotPalmRejectionDelegate <NSObject>

/*! Sets the initial touches of a jot stylus.
 * \param touches Sets of initial touches where stylus begins touching
 */
-(void)jotStylusTouchBegan:(NSSet *) touches;

/*! Sets the movement of touches of a jot stylus.
 * \param touches Sets of touches where stylus is moving
 */
-(void)jotStylusTouchMoved:(NSSet *) touches;

/*! Sets the end touches of a jot stylus.
 * \param touches Sets of touches where stylus ends
 */
-(void)jotStylusTouchEnded:(NSSet *) touches;

/*! Sets cancelled touches of a jot stylus.
 * \param touches Sets of touches where stylus cancels
 */
-(void)jotStylusTouchCancelled:(NSSet *) touches;

/*! Suggest to disable gestures when the pen is down to prevent conflict.
 */
-(void)jotSuggestsToDisableGestures;

/*! Suggest to enable gestures when the pen is not down as there are no potential conflicts.
 */
-(void)jotSuggestsToEnableGestures;

@end

