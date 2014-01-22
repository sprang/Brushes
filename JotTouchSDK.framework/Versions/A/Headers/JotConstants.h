//
//  JotConstants.h
//  JotTouchSDK
//
//  Created on 6/27/13.
//  Copyright (c) 2013 Adonit. All rights reserved.
//

#import <Foundation/Foundation.h>

#define JOT_MIN_PRESSURE 0
#define JOT_MAX_PRESSURE 2047

#define DistanceOfTransmitterFromTipInInches  0.2893168033

#define JotStylusManagerDidChangeConnectionStatus @"jotStylusManagerDidChangeConnectionStatus"
#define JotStylusManagerDidPairWithStylus @"jotStylusManagerDidPairWithStylus"
#define JotStylusManagerDidChangeBatteryLevel @"jotStylusManagerDidChangeBatteryLevel"

#define JotStylusButton1Down @"jotStylusButton1Down"
#define JotStylusButton1Up @"jotStylusButton1Up"
#define JotStylusButton2Down @"jotStylusButton2Down"
#define JotStylusButton2Up @"jotStylusButton2Up"

#define JOT_STYLUS_RIGHTHANDED_REJECTION_ANGLE 45
#define JOT_STYLUS_LEFTHANDED_REJECTION_ANGLE 135

#define JOT_STYLUS_RIGHTHANDED_REJECTION_ANGLE_JotWritingStyleRightUp 45
#define JOT_STYLUS_RIGHTHANDED_REJECTION_ANGLE_JotWritingStyleRightMiddle 0
#define JOT_STYLUS_RIGHTHANDED_REJECTION_ANGLE_JotWritingStyleRightDown -45
#define JOT_STYLUS_RIGHTHANDED_REJECTION_ANGLE_JotWritingStyleLeftUp 225
#define JOT_STYLUS_RIGHTHANDED_REJECTION_ANGLE_JotWritingStyleLeftMiddle 180
#define JOT_STYLUS_RIGHTHANDED_REJECTION_ANGLE_JotWritingStyleLeftDown 135


typedef NS_ENUM(NSUInteger, JotModel) {
    JotModelUndefined = 0,
    JotModelJT2 = 1,
    JotModelJT4 = 2,
    JotModelJS = 3,
    JotModelJTPP = 4,
    JotModelMighty = 5,
};

typedef NS_ENUM(NSUInteger, JotStylusTipStatus) {
    JotStylusTipStatusOffScreen = 0,
    JotStylusTipStatusOnScreen = 1
    
};

typedef NS_ENUM(NSUInteger, JotPalmRejectionOrientation) {
    JotPalmRejectionLeftHanded,
    JotPalmRejectionRightHanded
};

typedef NS_ENUM(NSUInteger, JotWritingStyle) {
    JotWritingStyleRightUp,
    JotWritingStyleRightMiddle,
    JotWritingStyleRightDown,
    JotWritingStyleLeftUp,
    JotWritingStyleLeftMiddle,
    JotWritingStyleLeftDown,
};

typedef NS_ENUM(NSUInteger, JotConnectionStatus) {
    JotConnectionStatusOff,
    JotConnectionStatusScanning,
    JotConnectionStatusPairing,
    JotConnectionStatusConnected,
    JotConnectionStatusDisconnected
};

typedef NS_ENUM(NSUInteger, JotPreferredStylusType) {
    JotPreferredStylusBT21,
    JotPreferredStylusBT40,
    JotNoPreferredStylus,
};

extern NSString * const Connection_BT21;
extern NSString * const Connection_BT40;
extern NSString * const Model_JT2;
extern NSString * const Model_JT4;
extern NSString * const Model_JS;
extern NSString * const Model_JTPP;
extern NSString * const Model_Mighty;
