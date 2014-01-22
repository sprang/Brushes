//
//  Shortcut.h
//  JotSDKLibrary
//
//  Created  on 11/19/12.
//  Copyright (c) 2012 Adonit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JotShortcut : NSObject

/*! Short string representation of the shortcut.
 */
@property (readwrite,copy) NSString *descriptiveText;
/*! Key to access this shortcut.
 */
@property (readwrite,copy) NSString *key;

/*! Selector that is associated with the created shortcut.
 */
@property (readwrite) SEL selector;

/*! Target that is associated with the created shortcut.
 */
@property (readwrite,assign) id target;

/*! Specifies whether the shortcut should be continously repeated.
 */
@property (readwrite) BOOL repeat;

/*! Specifies the rate at which the shortcut will be repeated.
 */
@property (readwrite) NSTimeInterval repeatRate;

/*! Determines if shortcut is usable while the stylus is being pressed.
 */
@property (readwrite) BOOL usableWhenStylusDepressed;

-(id)initWithDescriptiveText:(NSString *)descriptiveText key:(NSString *)key target:(id)target selector:(SEL)selector;
-(id)initWithDescriptiveText:(NSString *)descriptiveText key:(NSString *)key target:(id)target selector:(SEL)selector repeatRate:(NSTimeInterval)repeatRate;
-(id)initWithDescriptiveText:(NSString *)descriptiveText key:(NSString *)key target:(id)target selector:(SEL)selector usableWithStylusDepressed:(BOOL)usableWhenStylusDepressed;
-(id)initWithDescriptiveText:(NSString *)descriptiveText key:(NSString *)key target:(id)target selector:(SEL)selector repeatRate:(NSTimeInterval)repeatRate usableWithStylusDepressed:(BOOL)usableWhenStylusDepressed;;

-(void)start;

/*! Stop the timer for repeating shortcuts.
 */
-(void)stop;

@end
