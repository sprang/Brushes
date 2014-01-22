//
//  StylusStateDelegate.h
//  PalmRejectionExampleApp
//
//  Created  on 10/14/12.
//
//

#import <Foundation/Foundation.h>

@protocol JotStylusStateDelegate<NSObject>

/*! Message that the jot has been pressed.
 */
-(void)jotStylusPressed;

/*! Message that the jot has been released after press.
 */
-(void)jotStylusReleased;

/*! Message that the button 1 is pressed.
 */
-(void)jotStylusButton1Pressed;

/*! Message that the button 1 is released after press.
 */
-(void)jotStylusButton1Released;

/*! Message that the button 2 is pressed.
 */
-(void)jotStylusButton2Pressed;

/*! Message that the button 2 is released after press.
 */
-(void)jotStylusButton2Released;

/*! Messaged that the jot stylus pressure is updated.
 */
-(void)jotStylusPressureUpdate:(NSUInteger)pressure;

/*! Messaged that the jot stylus battery level is updated.
 */
-(void)jotStylus:(JotStylus*)stylus batteryLevelUpdate:(NSUInteger)battery;

@end
