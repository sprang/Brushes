//
//  WDProperty.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDCoding.h"

@protocol WDPropertyDelegate;

@interface WDProperty : NSObject<NSCopying, WDCoding>

@property (nonatomic, assign) BOOL percentage;
@property (nonatomic, assign) float conversionFactor;
@property (nonatomic) NSString *title;
@property (nonatomic, assign) float minimumValue;
@property (nonatomic, assign) float maximumValue;
@property (nonatomic, readonly) BOOL canDecrement;
@property (nonatomic, readonly) BOOL canIncrement;
@property (nonatomic, assign) float value;

@property (nonatomic, weak) id<WDPropertyDelegate> delegate;

+ (WDProperty *) property;

- (void) increment;
- (void) decrement;

- (void) randomize;

@end

@protocol WDPropertyDelegate <NSObject>
- (void) propertyChanged:(WDProperty *)property;
@end

extern NSString *WDPropertyChangedNotification;
