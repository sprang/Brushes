#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, T1PogoEventType)	// Pogo Egent types
{
    T1PogoEventTypeUnknown			= 0,	// should never happen
	T1PogoEventTypeButtonDown		= 1,	// a button was pressed down
	T1PogoEventTypeButtonUp			= 2,	// a button was released
	T1PogoEventTypePressureChange	= 3,	// pressure data did change
	T1PogoEventTypeTouchTypeChange	= 4,	// touch type did change
	T1PogoEventTypeExtendedData		= 5,	// extended data for UITouch
	T1PogoEventTypeTipDown			= 6,	// only for advanced use
	T1PogoEventTypeTipUp			= 7		// only for advanced use
};



typedef NS_ENUM(NSInteger, T1PogoTouchType)	// Describes what is touching the display
{
    T1TouchTypeUnknown	= 0,	// type of touch is unknown
	T1TouchTypeFinger	= 1,	// touch is a finger or a palm
	T1TouchTypeEraser	= 2,	// touch is eraser
	T1TouchTypePen1		= 3,	// touch is pen type 1
	T1TouchTypePen2		= 4,	// touch is pen type 2
	T1TouchTypePen3		= 5,	// touch is pen type 3
	T1TouchTypePen4		= 6,	// touch is pen type 4
	T1TouchTypePen5		= 7		// touch is pen type 5
};



typedef NS_ENUM(NSInteger, T1PogoButton)	// Possible button numbers for devices with lots of buttons
{
	T1PogoButton1	= 0,	// first, and usually the only button
	T1PogoButton2	= 1,	// a secondary button, and so on
	T1PogoButton3	= 2,
	T1PogoButton4	= 3,
	T1PogoButton5	= 4,
	T1PogoButton6	= 5,
	T1PogoButton7	= 6,
	T1PogoButton8	= 7
};



@interface T1PogoEvent : NSObject

@property (assign, readonly) id __unsafe_unretained	touch;	// a back-pointer to the associated UITouch object
@property (assign, readonly) id __unsafe_unretained	pen;	// the pen this event came from
@property (assign, readonly) T1PogoEventType		type;	// why this event is being delivered
@property (assign, readonly, nonatomic) BOOL		isPen;	// shortcut to find if it's a pen of any (type>1)
@property (assign, readonly, nonatomic) T1PogoTouchType touchType;	// what type of touch this is associated with
@property (assign, readonly) T1PogoTouchType		previousTouchType;	// what type of touch this used to be
@property (assign, readonly) T1PogoButton			button;	// which button
@property (assign, readonly) float					pressure;	// pressure change for associated UIEvent object
@property (assign, readonly) float					diameter;	// tip contact diameter estimate in mm
@property (assign, readonly) NSTimeInterval			timestamp;	// timestamp of this event
@property (assign, readonly) NSTimeInterval			firstTimestamp;	// first time associated touch has been seen

@end
