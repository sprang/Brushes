//
//  WDTypedData
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

#import "WDDataProvider.h"

@interface WDTypedData : NSObject <WDDataProvider>

@property (nonatomic, assign) BOOL compress;
@property (nonatomic) NSData *data;
@property (nonatomic, assign) WDSaveStatus isSaved;
@property (nonatomic) NSString *mediaType;
@property (nonatomic) NSString *uuid;

+ (WDTypedData *) data:(NSData *)data mediaType:(NSString *)type;
+ (WDTypedData *) data:(NSData *)data mediaType:(NSString *)type compress:(BOOL)compress uuid:(NSString *)uuid isSaved:(WDSaveStatus)saved;

@end
