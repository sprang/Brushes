/*	Usage Instructions:

 Drag the T1PogoManager folder into your XCode project.

 1) #import "T1PogoManager.h into your view controller header and declare <T1PogoDelegate> protocol.  Add CoreBluetooth.framework, AVFoundation.framework, and Security.framework to your build phases.

 2) When your app starts, call  'self.pogoManager = [T1PogoManager pogoManagerWithDelegate:self];'  This property should be retained for later use.
	We highly recommend calling self.pogoManager.enablePenInputOverNetworkIfIncompatiblePad = YES for compatibility with iPads 1 and 2.

 3) Register any views that receive pen events by calling [self.pogoManager registerView:view];

 4) Make sure multipleTouchEnabled = YES; for any views that will accept a pen.

 5) Create a button for managing pens somewhere in your settings.  When the button is pressed, call something like:
 UIPopoverController * popover = [self.pogoManager scanningPopover];
 [popover presentPopoverFromRect:[sender frame] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];

 This will show a UI for connecting/disconnecting and configuring pens.  Of course, it's fine to do your own UI using didDiscoverPeripheral and didUpdatePeripheral.

 6) When you handle touches, call [self.pogoManager touchIsPen:touch] or [self.pogoManager pressureForTouch:touch] as needed.  These all return extremely fast.

 7) In some cases, the type of touch can change.  If you're doing palm rejection, we recommend you implement the pogoManager:didChangeTouchType:forPen: delegate method to handle any change.  Compare pogoEvent.touchType with pogoEvent.previousTouchType.  If a touch changes from a pen type to an unknown or finger touch, stop and undo the stroke.  Another note about palm rejection - If Multitasking Gestures are enabled, palm rejection performance will be inhibited.

 8) Many apps use gestures to control pan, zoom, and undo.  However, gestures can be accidentally triggered with a resting palm.  This SDK can tell you when to disable gestures, allowing users to rest their hand on the iPad.  On Disable, cancel any gestures in progress.  Stop new gestures from happening.  Look for pogoManagerDidSuggestDisablingGesturesForRegisteredViews: and pogoManagerDidSuggestEnablingGesturesForRegisteredViews:.  If a pen is connected and in use, it may be a good idea to delay your navigation gestures a bit to allow them a chance to be disabled by our API.
 
 
 
 For more usage info and examples, delve into the T1PogoManagerDemo project.
 Support requests may be emailed to devs@tenonedesign.com
 Follow @tenonedesign for SDK update notifications.
 Have fun!

 */



#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "T1PogoEvent.h"
#import "T1PogoPen.h"
#import "T1Peripheral.h"
#import "T1PogoDelegate.h"



typedef NS_ENUM(NSInteger, T1PogoManagerDataOperationError) {
	T1PogoManagerDataOperationErrorUnknown = 0,
	T1PogoManagerDataOperationErrorNoDataAvailable,
	T1PogoManagerDataOperationErrorDataTooLong,
	T1PogoManagerDataOperationErrorPeripheralIsFull,
	T1PogoManagerDataOperationErrorPeripheralNotConnected,
	T1PogoManagerDataOperationErrorPeripheralDoesNotSupportFunction,
	T1PogoManagerDataOperationErrorNotAuthorized,
	T1PogoManagerDataOperationErrorOperatingSystemDoesNotSupportFunction,
	T1PogoManagerDataOperationErrorTimeout,
	T1PogoManagerDataOperationErrorIndexRead,
	T1PogoManagerDataOperationErrorChecksumMismatch,
	T1PogoManagerDataOperationErrorOperationInProgress,
	T1PogoManagerDataOperationErrorBluetoothError
};









@interface T1PogoManager : NSObject

/*
 If a pen starts advertising, we'll handle asking the user to connect.
 You can customize the alert view by setting viewForConnectionPrompt
 You can turn off this behavior by setting showConnectionPromptForNewPens to NO
 */
@property (nonatomic, assign) BOOL showConnectionPromptForNewPens;

/*
 We all still have iPad 1 and 2 customers out there.
 Set this to YES to allow them to use their Pogo Connect in your app.
 */
@property (nonatomic, assign) BOOL enablePenInputOverNetworkIfIncompatiblePad;

/*
 Library build number
 */
@property (assign, readonly) NSUInteger buildNumber;






/*
 Required methods
 */
+ (T1PogoManager *)pogoManagerWithDelegate:(id)theDelegate;
- (void)registerView:(UIView *)view;
- (void)deregisterView:(UIView *)view;



/*
 Adding additional delegates
 This is handy to observe pen connection events in more than one location.
 Delegates are always called on the main thread.
 */
- (void)addDelegate:(id)delegate;
- (void)removeDelegate:(id)delegate;
- (void)removeAllDelegates;



/*
 Optional singleton access.  Don't use this unless you know what you're doing.
 There is no way to destroy this object, or turn off the SDK once you ask for this.
 Use the delegate methods above to add delegates as required.
 */
+ (T1PogoManager *)sharedPogoManager;



/*
 Obtain popover controller to allow connection of pens.
 Display with presentPopoverFromRect:inView:permittedArrowDirections:animated:
 You may also obtain just the view controller for pushing onto your own nav stack.
 If you'd like to make your own pen connection interface, see the Peripheral-based API below
 */
- (UIPopoverController *)scanningPopover;
- (UITableViewController *)scanningViewController;
- (UINavigationController *)scanningViewControllerForPhone;



/*
 Pen & touch information methods.  Call these in your touches down/moved/ended methods.
 
 touchIsPen: is an easy way to do palm rejection.
 If it's ever wrong, it will correct itself with didChangeType: callback.
 pressureForTouch: provides a pressure value between 0 and 1.
 */
- (BOOL)touchIsPen:(UITouch *)touch;
- (float)pressureForTouch:(UITouch *)touch;


// A pen can have many types (different brush types, colors, or it can be an eraser).
// Call this if you care, otherwise touchIsPen: should suffice.
- (T1PogoTouchType)typeForTouch:(UITouch *)touch;

// Obtain all known extended information about a touch event, including pressure, pen type, etc.
// For details, see T1PogoEvent.h
- (T1PogoEvent *)pogoEventForTouch:(UITouch *)touch;






/*
 Pressure response control
 By default, the pen pressure is linear, but can be changed to light or heavy.
 Artistic apps might consider if T1PogoPenPressureResponseLight is a good option.
 */
- (void)setPressureResponse:(T1PogoPenPressureResponse)pressureResponse forPen:(T1PogoPen *)pen;





/*
 LED control methods
 */
// Set LED color for all connected pens.  Duration for all methods is in seconds.  Max duration is 12.75s.
- (void)setLEDColor:(UIColor *)color duration:(NSTimeInterval)duration;
- (void)setLEDColor:(UIColor *)color forPen:(T1PogoPen *)pen duration:(NSTimeInterval)duration;



// Fade to LED color for all connected pens with animation time, and scheduled shut-off after duration.  Duration includes fade time.
- (void)fadeToLEDColor:(UIColor *)color overTime:(NSTimeInterval)time forDuration:(NSTimeInterval)duration;
- (void)fadeToLEDColor:(UIColor *)color forPen:(T1PogoPen *)pen overTime:(NSTimeInterval)time forDuration:(NSTimeInterval)duration;






/*
 Storing data on the peripheral
 Each app is allocated 100 bytes of data to use as you wish.
 A good use might be to store a key that can be used to retrieve user preferences from your server.
 Another good use might be to save application settings directly on the pen.
 To delete your data, write null.
 Writing or reading may take up to two seconds depending on hardware conditions.
 The completion handlers will indicate any errors with a non-null NSError object.
 Read and write sparingly - it uses up the pen's battery power.
 The relevant T1Peripheral may be obtained by calling [pen peripheral].
 */
- (void)readApplicationDataOnPeripheral:(T1Peripheral *)peripheral completionHandler:(void (^)(NSData *data, NSError *error))completionHandler;
- (void)writeApplicationData:(NSData *)data onPeripheral:(T1Peripheral *)peripheral completionHandler:(void (^)(NSError *error))completionHandler;


/*
 If you own a family of applications, for example MS Word and Excel, you can access one application's data on the pen from another application.
 This is useful to transport user's preferences throughout your app family, and from iPad to iPhone.
 Similar to accessing the keychain, this will only work if the applications accessing data have the same bundle seed id (typically your teamID)
 */
- (void)readApplicationDataForBundleIdentifier:(NSString *)bundleIdentifier onPeripheral:(T1Peripheral *)peripheral completionHandler:(void (^)(NSData *data, NSError *error))completionHandler;
- (void)writeApplicationData:(NSData *)data forBundleIdentifier:(NSString *)bundleIdentifier onPeripheral:(T1Peripheral *)peripheral completionHandler:(void (^)(NSError *error))completionHandler;


/*
 A unique number you can use as a key to store and retrieve user preference data cross-device.
 String will be nil until peripheral has connected.
 This can be a good alternative to storing custom data on the pen.
 */
- (NSString *)uniqueIdentifierForPeripheral:(T1Peripheral *)peripheral;







/*
 Peripheral-based API
 Methods for implementing your own pen scanning interface if you're up for it.
 This is what T1PogoManager uses internally, and it's the preferred way.
 Implement didDiscoverPeripheral: and didUpdatePeripheral: delegate methods to see peripheral data.
 They will be called anytime things change so you can update your table/views.
 The methods here will let you control the peripheral's connection.
 If you're implementing these, you can ignore the pen-based API shown next
 */
- (void)connectPeripheral:(T1Peripheral *)peripheral;
- (void)disconnectPeripheral:(T1Peripheral *)peripheral;
- (void)setEnableLocatorBeacon:(BOOL)enable forPeripheral:(T1Peripheral *)peripheral;
- (void)setEnableAutoconnect:(BOOL)enable forPeripheral:(T1Peripheral *)peripheral;



/*
 Pen-based API
 The didConnectPen: and didDisconnectPen: delegates help you keep track of how many pens are connected.
 You can connect and disconnect them with these methods.  In response, T1PogoManager will disconnect the parent peripheral.
 In our context, a pen represents a physical pen tip.  If we ever release a Pogo Connect with an eraser tip, it'll show up as a second tip here.
 */
- (void)connectPogoPen:(T1PogoPen *)pen;
- (void)disconnectPogoPen:(T1PogoPen *)pen;
- (BOOL)oneOrMorePensAreConnected;
- (NSArray *)activePens;

@end
