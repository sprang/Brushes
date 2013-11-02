//
//  WDFileData.h
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

@interface WDFileData : NSObject <WDDataProvider>

@property (nonatomic) NSString *mediaType;
@property (nonatomic) NSString *path;

+ (WDFileData *) withPath:(NSString *)path mediaType:(NSString *)mediaType;

@end
