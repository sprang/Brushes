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
    
    if ([self isApplePencil]){
        [self setMode:WDApplePencilStylus];
    }
    
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
    }else if (type == WDApplePencilStylus){
        data.productName = @"Apple Pencil";
        data.connected = [self isApplePencil];
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
    } else if (mode == WDApplePencilStylus) {
        isReal = YES;
        pressure = touch.force * 0.8;
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

- (BOOL) isApplePencil {
    // Device information UUID
    NSArray* myArray = [NSArray arrayWithObject:[CBUUID UUIDWithString:@"180A"]];
    
    NSArray* peripherals = [centralBlueToothManager retrieveConnectedPeripheralsWithServices:myArray];
    for (CBPeripheral* peripheral in peripherals)
    {
        if ([[peripheral name] isEqualToString:@"Apple Pencil"])
        {
            return YES;
        }
    }
    
    return NO;
}

- (void) setBlueToothState:(WDBlueToothState)inBlueToothState
{
    if (inBlueToothState == blueToothState) {
        return;
    }
    
    blueToothState = inBlueToothState;
    
    if (blueToothState == WDBlueToothLowEnergy && !pogoManager) {
        pogoManager = [T1PogoManager pogoManagerWithDelegate:self];
        pogoManager.enablePenInputOverNetworkIfIncompatiblePad = YES;
    }else if ([self isApplePencil]){
        [self didConnectStylus:@"Apple Pencil"];
        [self setMode:WDApplePencilStylus];
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
