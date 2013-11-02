#import <CoreBluetooth/CoreBluetooth.h>
@class T1PogoManager;
@class T1PogoEvent;
@class T1PogoPen;
@class T1Peripheral;



@protocol T1PogoDelegate <NSObject>

@optional

/*
 Recommended implementation of protocol
 */

// Bluetooth power status
// If state == CBCentralManagerStatePoweredOff, it may be polite to let your user know on first app launch, then perhaps later if it seems likely they will use a Pogo Connect soon.
- (void)pogoManager:(T1PogoManager *)manager didUpdateBluetoothState:(CBCentralManagerState)state;


// button events
- (void)pogoManager:(T1PogoManager *)manager didDetectButtonDown:(T1PogoEvent *)event forPen:(T1PogoPen *)pen;
- (void)pogoManager:(T1PogoManager *)manager didDetectButtonUp:(T1PogoEvent *)event forPen:(T1PogoPen *)pen;

// ocassionally the manager will identify a touch as a pen or vice-versa after it has already started
- (void)pogoManager:(T1PogoManager *)manager didChangeTouchType:(T1PogoEvent *)event forPen:(T1PogoPen *)pen;

// use didDiscoverNewPen: to prompt your user to connect.  if yes, call connectPogoPen: to seal the deal
// this is called once per app launch when a pen is first discovered.
// users can always connect manually in the scanningPopover view.
- (void)pogoManager:(T1PogoManager *)manager didDiscoverNewPen:(T1PogoPen *)pen withName:(NSString *)name;

// Many apps use gestures to control pan, zoom, and undo.  However, gestures are accidentally triggered with a resting palm.
// On Disable, cancel any gestures in progress.  Stop new gestures from happening.  This might mean removing them from the view.
// On Enable, enable gestures.
- (void)pogoManagerDidSuggestDisablingGesturesForRegisteredViews:(T1PogoManager *)manager;
- (void)pogoManagerDidSuggestEnablingGesturesForRegisteredViews:(T1PogoManager *)manager;



/*
 Advanced implementation of protocol
 */

- (void)pogoManager:(T1PogoManager *)manager willConnectPen:(T1PogoPen *)pen;   // pen discovered and is connecting
- (void)pogoManager:(T1PogoManager *)manager didConnectPen:(T1PogoPen *)pen;    // pen connected and ready to use
- (void)pogoManager:(T1PogoManager *)manager didDisconnectPen:(T1PogoPen *)pen; // pen disconnected
- (void)pogoManager:(T1PogoManager *)manager didUpdatePen:(T1PogoPen *)pen;     // pen properties updated

// both methods below notify of pen pressure changes.
// the first method is used when the pen is stationary and only the pressure changes in a registered view.
// this allows a new pressure to be drawn when the pen is stationary, for effects like ink blotting.
// the second method is called whenever pressure has changed, regardless of the view, and even if the pen is also causing touchesMoved events.
- (void)pogoManager:(T1PogoManager *)manager didChangePressureWithoutMoving:(T1PogoEvent * )event forPen:(T1PogoPen *)pen;
- (void)pogoManager:(T1PogoManager *)manager didChangePressure:(T1PogoEvent *)event forPen:(T1PogoPen *)pen;
- (void)pogoManager:(T1PogoManager *)manager didDetectLowBatteryForPen:(T1PogoPen *)pen;        // pen battery below 5%
- (void)pogoManager:(T1PogoManager *)manager didDetectHardwareErrorForPen:(T1PogoPen *)pen;     // hardware failure can be reported
- (void)pogoManager:(T1PogoManager *)manager didChangeDebugString:(NSString *)string;   // watch debug messages
- (void)pogoManager:(T1PogoManager *)manager didDetectTipDown:(T1PogoEvent *)event forPen:( T1PogoPen * )pen;     // not so useful
- (void)pogoManager:(T1PogoManager *)manager didDetectTipUp:(T1PogoEvent *)event forPen:( T1PogoPen * )pen;       // not so useful


// methods for implementing a custom scanning pen list
// This is a nice way to unify the look of your app.  If you'd like to see sample code for a basic scanning UITableView, email devs@tenonedesign.com, and we'll hook you up.
- (void)pogoManager:(T1PogoManager *)manager didDiscoverPeripheral:(T1Peripheral *)peripheral;  // peripheral was discovered
- (void)pogoManager:(T1PogoManager *)manager didUpdatePeripheral:(T1Peripheral *)peripheral;    // peripheral properties updated

@end
