//
//  JotStylusManager.h
//  PalmRejectionExampleApp
//
//  Created on 8/20/12.
//  Copyright (c) 2012 Adonit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JotStylusConnectionDelegate.h"
#import "JotPalmRejectionDelegate.h"
#import "JotStylusStateDelegate.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>
#import "JotShortcut.h"
#import "JotSettingsViewController.h"
#import "JotConstants.h"

@class JotPreferredStylus;
@interface JotStylusManager : NSObject <JotStylusStateDelegate, JotStylusConnectionDelegate>

+ (JotStylusManager*)sharedInstance;

-(void)touchesBegan:(NSSet *)touches;
-(void)touchesMoved:(NSSet *)touches;
-(void)touchesEnded:(NSSet *)touches;
-(void)touchesCancelled:(NSSet *)touches;

/*! Adds a shortcut option that is accessibile and can be specified by the user.
 * \param shortcut A shortcut to be added to the settings interface
 */
-(void)addShortcutOption:(JotShortcut *)shortcut;

/*! Sets the default option state for the first shortcut that will used when initially loading the interface.
 * \param shortcut The default option of the second stylus button shortcut to be added to the settings interface
 */
-(void)addShortcutOptionButton1Default:(JotShortcut *)shortcut;

/*! Sets the default option state for the second shortcut that will used when initially loading the interface.
 * \param shortcut The default option of the second stylus button shortcut to be added to the settings interface
 */
-(void)addShortcutOptionButton2Default:(JotShortcut *)shortcut;

/*! Obtains pressure data of the stylus currently connected.
 * \returns If connected, returns positive integer value of connected pressure data. If not connected, returns the unconnected pressure data.
 */
-(NSUInteger)getPressure;

/*! Determines if a stylus is currently connected.
 * \returns A boolean specifying if a stylus is connected
 */
-(BOOL)isStylusConnected;

/*! Number of stylus connected to BT, including those still pairing
 * \returns A NSUInteger with the total count of stylus connected and/or pairing
 */
-(NSUInteger)totalNumberOfStylusesConnected;


/*! Removes the current connected stylus and stop receiving data from it.
 */
-(void)forgetAndTurnOffStylus;

/*! Sets a view to receive touch events from Jot styluses.
 * \param view A view that will be supplied touch events from Jot styluses
 */
-(void)registerView:(UIView*)view;

/*! Removes view from receiving touch events from Jot styluses.
 * \param view A view that will no longer receiver touch events from Jot styluses
 */
-(void)unregisterView:(UIView*)view;

/*! Links to Safari and appropriate help site for the stylus currently connected.
 */
-(void)launchHelp;

-(void)setOptionValue:(id)value forKey:(NSString *)key;

#pragma mark - properties

/*! Delays used to tune re-enabling gestures when a stylus is lifted from the screen.
 */
@property (readwrite) CGFloat palmDetectionTouchDelay;
@property (nonatomic) CGFloat palmDetectionTouchDelayNoPressure;
@property (readwrite) NSUInteger unconnectedPressure;

/*! Array of JotShortcuts utilized in the settings interface.
 */
@property (readonly) NSArray *shortcuts;

/*! The current button 1 shortcut of the preferred stylus.
 */
@property (readwrite,assign) JotShortcut *button1Shortcut;

/*! The current button 2 shortcut of the preferred stylus.
 */
@property (readwrite,assign) JotShortcut *button2Shortcut;

/*! Palm rejection delegate capturing touch events for palm rejection.
 */
@property (readwrite,assign) id<JotPalmRejectionDelegate> palmRejectorDelegate;

@property (nonatomic) BOOL enabled;

/*! A string representation of the current version of the SDK being used.
 */
@property (readonly) NSString *SDKVersion;

/*! A string representation of the current build number of the SDK being used.
 */
@property (readonly) NSString *SDKBuildVersion;

/*! A boolean specifying whether palm rejection is on.
 */
@property (readwrite) BOOL rejectMode;

/*! A positive integer specifying the amount of battery remaining.
 */
@property (readonly) NSUInteger batteryLevel;

/*! An enum specifying the current selected palm rejection orientation (left vs. right)
 * Deprecated in v2.0, moving forward please use palmRejectionOrientation
 */
@property (readwrite) JotPalmRejectionOrientation palmRejectionOrientation;

/*! An enum specifying the current writing style and prefered writing hand. Default to JotWritingStyleRightDown
 */
@property (readwrite) JotWritingStyle writingStyle;

/*! An enum specifying the current status of pairing styluses.
 */
@property (readonly) JotConnectionStatus connectionStatus;

/*! An enum specifying the type of the preferred stylus.
 * Deprecated in v2.0
 */
@property (readonly) JotPreferredStylusType preferredStylusType;

/*! An enum specifying the model of the preferred and connected stylus.
 */
@property (readonly) JotModel preferredStylusModel;

/*! An enum specifying the preferred stylus.
 */
@property (readonly) JotPreferredStylus *preferredStylus;


/*! NSString representing the firmware version for the connected pen
 */
@property (readonly) NSString *firmwareVersion;

/*! NSString representing the hardware version for the connected pen
 */
@property (readonly) NSString *hardwareVersion;


@end
