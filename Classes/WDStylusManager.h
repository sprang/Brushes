//
//  WDStylusManager.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
// Pogo Connect (Blue Tiger)
#import "T1PogoManager.h"

typedef enum {
    WDNoStylus = 0,
    WDPogoConnectStylus,
    WDMaxStylusTypes
} WDStylusType;

typedef enum {
    WDBlueToothOff = 0,
    WDBlueToothLowEnergy
} WDBlueToothState;

@interface WDStylusData : NSObject
@property (nonatomic) NSString *productName;  // required
@property (nonatomic) NSNumber *batteryLevel; // can be nil
@property (nonatomic) BOOL connected;
@property (nonatomic) T1PogoPen *pogoPen;
@property (nonatomic) WDStylusType type;
@end

@interface WDStylusManager : NSObject <CBCentralManagerDelegate>

@property (nonatomic) T1PogoManager *pogoManager;
@property (nonatomic, readonly) NSUInteger numberOfStylusTypes;
@property (nonatomic) WDStylusType mode;
@property (nonatomic) WDBlueToothState blueToothState;
@property (nonatomic, readonly) BOOL isBlueToothEnabled;

+ (WDStylusManager *) sharedStylusManager;

- (NSUInteger) numberOfStylusesForType:(WDStylusType)type;
- (WDStylusData *) dataForStylusType:(WDStylusType)type atIndex:(NSUInteger)ix;

- (float) pressureForTouch:(UITouch *)touch realPressue:(BOOL *)isRealPressure;

- (void) setPaintColor:(UIColor *)color;

@end

extern NSString *WDStylusPrimaryButtonPressedNotification;
extern NSString *WDStylusSecondaryButtonPressedNotification;

extern NSString *WDStylusDidConnectNotification;
extern NSString *WDStylusDidDisconnectNotification;

extern NSString *WDBlueToothStateChangedNotification;


