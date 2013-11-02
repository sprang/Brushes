//
//  WDFileData.m
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

#import "WDFileData.h"
#import "WDJSONCoder.h"

@implementation WDFileData

@synthesize path;
@synthesize mediaType;

+ (WDFileData *)withPath:(NSString *)path mediaType:(NSString *)mediaType
{
    WDFileData *data = [[WDFileData alloc] init];
    data.mediaType = mediaType;
    data.path = path;
    return data;
}

- (NSString *)mediaType
{
    if (mediaType) {
        return mediaType;
    } else {
        return [WDJSONCoder typeForExtension:self.path];
    }
}

- (NSData *)data
{
    return [NSData dataWithContentsOfFile:self.path];
}

- (WDSaveStatus)isSaved
{
    return kWDSaveStatusSaved;
}

- (NSString *)uuid
{
    return nil;
}

@end
