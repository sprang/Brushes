#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "T1PogoEvent.h"

@class T1Peripheral;


typedef struct penCapabilities
{
	unsigned touchDetect:           1;
	unsigned pressure:              1;
	unsigned led:                   1;
	unsigned multicolorLed:         1;
	unsigned button:                1;
	unsigned multibutton:           1;
	unsigned multitip:              1;	// hint that there's another logical pen on this peripheral
	unsigned extendedPressureRange: 1;
	unsigned tilt:                  1;
	unsigned tangental:             1;
	unsigned rotation:              1;
	unsigned z:                     1;
	unsigned isFirmwareUpdatable:   1;

} penCapabilities;


typedef NS_ENUM(NSInteger, T1PogoPenPressureResponse)
{
    T1PogoPenPressureResponseLinear	= 0,	// standard linear response (default)
	T1PogoPenPressureResponseLight	= 1,	// medium pressure results in lighter stroke
	T1PogoPenPressureResponseHeavy	= 2		// medium pressure results in heavier stroke
};


@interface T1PogoPen : NSObject

@property (assign, readonly) T1Peripheral __unsafe_unretained	*peripheral;
@property (strong, readonly, nonatomic) CBService	*parentService;
@property (assign, readonly) BOOL					isConnected;
@property (assign, readonly) NSTimeInterval			connectionTimestamp;
@property (assign, readonly) T1PogoTouchType		type;
@property (assign, readonly) penCapabilities		*capabilitiesBitfield;
@property (assign, readonly) NSUInteger				numberOfButtons;
@property (strong, readonly, nonatomic) UIColor		*LEDColor;
@property (strong, readonly, nonatomic) UIColor		*penBodyColor;	// may not be accurate
@property (strong, readonly, nonatomic) NSString	*tipIdentifier;
@property (assign, readonly) float					lastPressure;
@property (assign, readonly) float					lastDiameter;	// diameter in mm of tip touching glass
@property (assign, readonly) CGPoint				lastWindowLocation;
@property (assign, readonly) BOOL					tipIsDown;
@property (assign, readonly) BOOL					tipIsDownInRegisteredView;
@property (assign, readonly) BOOL					tipIsStationary;
@property (assign, readonly) NSTimeInterval			lastMovementTimestamp;
@property (assign, readonly) NSTimeInterval			lastTipDownTimestamp;
@property (assign) BOOL								usePressureSmoothing;
@property (assign) T1PogoPenPressureResponse		pressureResponse;

@end
