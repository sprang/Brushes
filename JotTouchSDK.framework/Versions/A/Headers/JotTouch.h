//
//  JotTouch.h
//  JotSDKLibrary
//
//  Created  on 11/30/12.
//  Copyright (c) 2012 Adonit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@interface JotTouch : NSObject

+(JotTouch *)jotTouchFor:(UITouch *)touch;
+(void)cleanJotTouchFor:(UITouch *)touch;
+(void)cleanJotTouches:(NSSet *)jotTouches;
/*! Returns a offset correct point location in input view
 * \param touch A UITouch object that is used to init JotTouch object.
 */
-(id)initWithTouch:(UITouch *)touch;

/*! Returns point location in input view.
 * \param view The view from which the touch occurs
 * \return The point of the touch within the input view
 */
-(CGPoint)locationInView:(UIView *)view;

/*! Returns previous point location in input view.
 * \param view The view from which the touch occurs
 * \return The point of the previous touch within the input view
 */
-(CGPoint)previousLocationInView:(UIView *)view;

/*! Syncs pressure value to specific JotTouch object.
 * \param pressure The current pressure value while the touch is being captured
 */
-(void)syncToTouchWithPressure:(NSUInteger)pressure;

/*! The touch associated with this object.
 */
@property (readonly) UITouch* touch;

/*! The pressure associated with the touch.
 */
@property (readwrite) NSUInteger pressure;

/*! The point of the touch within the window.
 */
@property (readwrite) CGPoint windowPosition;

/*! The previous point of the touch within the window.
 */
@property (readwrite) CGPoint previousWindowPosition;

/*! The time at which the touch occurred.
 */
@property (readwrite) NSTimeInterval timestamp;


#pragma mark - Debug
@property (readwrite) BOOL fromQueue;
@property (readwrite) BOOL fromQuickPickup;

@end
