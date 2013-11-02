#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>



@interface T1Peripheral : NSObject

@property (strong, readonly) NSString *productName;
@property (strong, readonly) NSString		*modelNumber;
@property (strong, readonly) NSString		*manufacturerName;
@property (strong, readonly) NSString		*uniqueIdentifier;
@property (strong, readonly, nonatomic) NSString *firmwareVersion;
@property (strong, readonly) NSString		*hardwareVersion;
@property (strong, readonly) NSString		*softwareVersion;
@property (strong, readonly) NSNumber		*RSSI;	// signal strength
@property (assign, readonly) NSInteger		batteryLevel;
@property (assign, readonly) NSTimeInterval	firstDiscoveryTimestamp;
@property (assign, readonly) NSTimeInterval	lastDiscoveryTimestamp;
@property (assign, readonly) NSTimeInterval	connectionTimestamp;
@property (assign, readonly) NSTimeInterval	lastLocatorBeaconTimestamp;
@property (assign, readonly) NSUInteger		recentAdvertisingCount;
@property (assign, readonly, nonatomic) BOOL isRecognized;
@property (assign, readonly, nonatomic) BOOL isConnected;	// physical link is up (discovery might not be complete)
@property (assign, readonly, nonatomic) BOOL autoconnectEnabled;
@property (assign, readonly, nonatomic) BOOL locatorBeaconEnabled;
@property (assign, readonly) BOOL			shouldPromptToConnect;
@property (assign, readonly) BOOL			discoveryComplete;	// considered connected when this is YES
@property (assign, readonly) BOOL			isBeingConnected;
@property (assign, readonly) BOOL			isAdvertising;
@property (assign, readonly) BOOL			isLocatable;	// periph can be found with RSSI
@property (assign, readonly) BOOL			isBridged;	// connected through an iPhone 4s or later
@property (assign, readonly) BOOL			isShared;	// Another app connected this peripheral

@property (strong, readonly, nonatomic) NSArray *pens;
@property (assign, readonly) CBPeripheral __unsafe_unretained * parentPeripheral;

- (NSString *)batteryPercentString;

@end
