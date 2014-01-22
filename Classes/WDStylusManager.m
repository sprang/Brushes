//
//  WDStylusManager.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDStylusManager.h"
#import "WDUtilities.h"
#import "UIDeviceHardware.h"

NSString *WDStylusPrimaryButtonPressedNotification = @"WDStylusPrimaryButtonPressedNotification";
NSString *WDStylusSecondaryButtonPressedNotification = @"WDStylusSecondaryButtonPressedNotification";

NSString *WDStylusDidConnectNotification = @"WDStylusDidConnectNotification";
NSString *WDStylusDidDisconnectNotification = @"WDStylusDidDisconnectNotification";

NSString *WDBlueToothStateChangedNotification = @"WDBlueToothStateChangedNotification";

@implementation WDStylusData
@synthesize productName;
@synthesize batteryLevel;
@synthesize connected;
@synthesize pogoPen;
@synthesize type;
@end

@interface WDStylusManager ()
@property (nonatomic) T1PogoPen *newlyDiscoveredPen;
@property (nonatomic) CBCentralManager *centralBlueToothManager;
@end

@implementation WDStylusManager

@synthesize pogoManager;
@synthesize jotManager;
@synthesize newlyDiscoveredPen;
@synthesize centralBlueToothManager;
@synthesize blueToothState;
@synthesize isBlueToothEnabled;
@synthesize mode;

+ (WDStylusManager *) sharedStylusManager
{
#if TARGET_IPHONE_SIMULATOR
    return nil;
#endif
    
    static WDStylusManager *_stylusManager = nil;
    
    if (!_stylusManager) {
        _stylusManager = [[WDStylusManager alloc] init];
    }
    
    return _stylusManager;
}

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    centralBlueToothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    self.mode = [[NSUserDefaults standardUserDefaults] integerForKey:@"WDStylusMode"];
    
    return self;
}

- (NSUInteger) numberOfStylusTypes
{
    return WDMaxStylusTypes;
}

- (NSUInteger) numberOfStylusesForType:(WDStylusType)type
{
    return 1;
}

- (void) setMode:(WDStylusType)inMode
{
    // in case the number of supported styluses changes from version to version...
    if (inMode >= WDMaxStylusTypes) {
        WDLog(@"Stylus mode out of range.");
        inMode = WDNoStylus;
    }
    
    if (WDDeviceIsPhone()) {
        // not supporting styluses on phones at the moment
        inMode = WDNoStylus;
    }
    
    if (mode == inMode) {
        return;
    }
    
    mode = inMode;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (mode != [defaults integerForKey:@"WDStylusMode"]) {
        [defaults setInteger:mode forKey:@"WDStylusMode"];
        [defaults synchronize];
    }
}

- (WDStylusData *) dataForStylusType:(WDStylusType)type atIndex:(NSUInteger)index
{
    WDStylusData *data = [[WDStylusData alloc] init];
    
    data.type = type;
    
    if (type == WDNoStylus) {
        data.productName = NSLocalizedString(@"No Stylus", @"No Stylus");
    } else if (type == WDPogoConnectStylus) {
        if (pogoManager.activePens.count == 0) {
            data.productName = [self defaultPogoConnectName];
        } else {
            T1PogoPen *pen = (pogoManager.activePens)[index];
            
            data.productName = pen.peripheral.productName;
            data.batteryLevel = @(pen.peripheral.batteryLevel / 100.0f);
            data.connected = pen.isConnected;
            data.pogoPen = pen;
        }
    } else if (type == WDJotTouchStylus) {
        data.productName = NSLocalizedString(@"Jot Touch", @"Jot Touch");
        data.connected = (jotManager.connectionStatus == JotConnectionStatusConnected);
        data.batteryLevel = @(jotManager.batteryLevel / 100.0f);
    }
    
    return data;
}

- (void) setPaintColor:(UIColor *)color
{
    [pogoManager setLEDColor:color duration:1];
}

- (float) pressureForTouch:(UITouch *)touch realPressue:(BOOL *)isRealPressure
{
    float   pressure = 1.0f;
    BOOL    isReal = NO;
    
    if ((mode == WDPogoConnectStylus) && [pogoManager oneOrMorePensAreConnected]) {
        isReal = YES;
        pressure = [pogoManager pressureForTouch:touch];
    } else if ((mode == WDJotTouchStylus) && ([jotManager connectionStatus] == JotConnectionStatusConnected)) {
        isReal = YES;
        NSLog(@"Pressure: %lu", (unsigned long)[jotManager getPressure]);
        pressure = [jotManager getPressure] / 2047.0f;
        
        
    } else if (mode != WDNoStylus) {
        isReal = YES;
        // since we're in stylus mode, but no styli are active, use 1.0 pressure
    }
    
    if (isRealPressure) {
        *isRealPressure = isReal;
    }
    
    return pressure;
}

#pragma mark -- Stylus Notifications

- (void) postNotificationOnMainQueue:(NSString *)name
{
    [self postNotificationOnMainQueue:name userInfo:nil];
}

- (void) postNotificationOnMainQueue:(NSString *)name userInfo:(NSDictionary *)userInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:self userInfo:userInfo];
    });
}

- (void) primaryButtonPressed
{
    [self postNotificationOnMainQueue:WDStylusPrimaryButtonPressedNotification];
}

- (void) secondaryButtonPressed
{
    [self postNotificationOnMainQueue:WDStylusSecondaryButtonPressedNotification];
}

- (void) didConnectStylus:(NSString *)stylus
{
    NSDictionary *userInfo = @{@"name": stylus};
    [self postNotificationOnMainQueue:WDStylusDidConnectNotification userInfo:userInfo];
}

- (void) didDisconnectStylus:(NSString *)stylus
{
    NSDictionary *userInfo = @{@"name": stylus};
    [self postNotificationOnMainQueue:WDStylusDidDisconnectNotification userInfo:userInfo];
}

#pragma mark -- Jot Touch
- (void)jotConnectionChange:(NSNotification *) note
{
    switch([[JotStylusManager sharedInstance] connectionStatus])
    {
        case JotConnectionStatusOff:
            break;
        case JotConnectionStatusScanning:
            break;
        case JotConnectionStatusPairing:
            break;
        case JotConnectionStatusConnected:
            [self didConnectStylus:NSLocalizedString(@"Jot Touch", @"Jot Touch")];
            break;
        case JotConnectionStatusDisconnected:
            [self didDisconnectStylus:NSLocalizedString(@"Jot Touch", @"Jot Touch")];
            break;
        default:
            break;
    }
}

-(void)jotStylusTouchBegan:(NSSet*)jotTouches{
    // a Jot stylus has begun to draw on the screen
}
-(void)jotStylusTouchMoved:(NSSet*)jotTouches{
    // a Jot stylus is moving on the screen
}
-(void)jotStylusTouchEnded:(NSSet*)jotTouches{
    // a Jot stylus has ended normally on the screen
}
-(void)jotStylusTouchCancelled:(NSSet*)jotTouches{
    // a stylus event has been cancelled on the screen
}
-(void)jotSuggestsToDisableGestures{
    // the Jot Touch SDK has determined that the user’s palm is likely
    // resting on the screen or the user is actively drawing with the
    // Jot stylus, and we recommend to disable any other gestures
    // that might be attached to that UIView, such as a pinch-to-zoom
    // gesture
}
-(void)jotSuggestsToEnableGestures{
    // The user’s palm has lifted and drawing has stopped, so it is
    // safe to re-enable any other gestures on the UIView
}

#pragma mark -- Pogo Connect

- (NSString *) defaultPogoConnectName
{
    return NSLocalizedString(@"Pogo Connect", @"Pogo Connect");
}

- (void)pogoManager:(T1PogoManager *)manager didConnectPen:(T1PogoPen *)pen
{
    [self didConnectStylus:pen.peripheral.productName];
    
    // use the recommended "artistic" pressure response
    [manager setPressureResponse:T1PogoPenPressureResponseLight forPen:pen];
}

- (void)pogoManager:(T1PogoManager *)manager didDisconnectPen:(T1PogoPen *)pen
{
    [self didDisconnectStylus:pen.peripheral.productName];
}

- (void)pogoManager:(T1PogoManager *)manager didDetectButtonDown:(T1PogoEvent *)event forPen:(T1PogoPen *)pen
{
    if (mode == WDPogoConnectStylus) {
        [self primaryButtonPressed];
    }
}

- (void)pogoManager:(T1PogoManager *)manager didDiscoverNewPen:(T1PogoPen *)pen withName:(NSString *)name
{
    newlyDiscoveredPen = pen;
    NSString *format = NSLocalizedString(@"Would you like to start using %@?", @"Would you like to start using %@?");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New Pen Found", @"New Pen Found")
                                                        message:[NSString stringWithFormat:format, name]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                              otherButtonTitles:NSLocalizedString(@"OK", @"OK"), nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1) {
		[pogoManager connectPogoPen:newlyDiscoveredPen];
	}
}

#pragma mark -- General BlueTooth state

- (BOOL) isBlueToothEnabled
{
    return self.blueToothState != WDBlueToothOff;
}

- (void) setBlueToothState:(WDBlueToothState)inBlueToothState
{
    if (inBlueToothState == blueToothState) {
        return;
    }
    
    blueToothState = inBlueToothState;
    
    if (blueToothState == WDBlueToothLowEnergy) {
        if (!pogoManager) {
            pogoManager = [T1PogoManager pogoManagerWithDelegate:self];
            pogoManager.enablePenInputOverNetworkIfIncompatiblePad = YES;
        }
        
        if (!jotManager) {
            jotManager = [JotStylusManager sharedInstance];
            
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector:@selector(jotConnectionChange:)
                                                         name: JotStylusManagerDidChangeConnectionStatus
                                                       object:nil];
            jotManager.rejectMode = NO;
            jotManager.enabled = YES;

            
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDBlueToothStateChangedNotification object:self];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        // only support this on iPads
        self.blueToothState = WDDeviceIsPhone() ? WDBlueToothOff : WDBlueToothLowEnergy;
    } else {
        self.blueToothState = WDBlueToothOff;
    }
}

@end
