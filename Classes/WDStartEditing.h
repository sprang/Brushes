//
//  WDStartEditing.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <Foundation/Foundation.h>
#import "WDSimpleDocumentChange.h"

@interface WDStartEditing : WDSimpleDocumentChange

@property (nonatomic) NSString *deviceID;
@property (nonatomic) NSString *deviceModel;
@property (nonatomic) NSArray *features;
@property (nonatomic, strong) NSString *historyVersion;
@property (nonatomic) NSString *systemVersion;

+ (WDStartEditing *) startEditing;

@end
