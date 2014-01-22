//
//  StylusConnectionDelegate.h
//  PalmRejectionExampleApp
//
//  Created on 9/14/12.
//  Copyright (c) 2012 Adonit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class JotStylus;
@protocol JotStylusConnection;

@protocol JotStylusConnectionDelegate <NSObject>

/*! Sent to update the status of stylus to pairing.
 */
-(void)jotStylusPairing:(JotStylus *)stylus;

/*! Sent to update the status of stylus to connected.
 */
-(void)jotStylusConnected:(JotStylus *)stylus;

/*! Sent to update the status of stylus to disconnected.
 */
-(void)jotStylusDisconnected:(JotStylus *)stylus;

/*! Sent to update the level of battery remaining.
 * \param batteryLevel Positive integer specifying the remaining battery of connected device
 */
-(void)jotStylus:(JotStylus *)stylus batteryLevelUpdate:(NSUInteger)batteryLevel;

/*! Sent when the device does not support bluetooth 4
 */
- (void)jotStylusUnsupported;
@end

