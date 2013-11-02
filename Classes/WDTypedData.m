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

#import "NSData+Additions.h"
#import "WDTypedData.h"

@implementation WDTypedData {
    NSData *data_;
}

@synthesize compress;
@synthesize isSaved;
@synthesize mediaType;
@synthesize uuid;


+ (WDTypedData *) data:(NSData *)data mediaType:(NSString *)type
{
    return [WDTypedData data:data mediaType:type compress:NO uuid:nil isSaved:kWDSaveStatusUnsaved];
}

+ (WDTypedData *) data:(NSData *)data mediaType:(NSString *)type compress:(BOOL)compress uuid:(NSString *)uuid isSaved:(WDSaveStatus)saved
{
    WDTypedData *typedData = [[WDTypedData alloc] init];
    typedData.data = data;
    typedData.isSaved = saved;
    typedData.mediaType = type;
    typedData.compress = compress;
    typedData.uuid = uuid;
    return typedData;
}

- (NSData *) data
{
    if (compress && data_ != nil && data_ != (id) [NSNull null]) {
        return [data_ compress];
    } else {
        return data_;
    }
}

- (void) setData:(NSData *)data
{
    data_ = data;
}

@end
