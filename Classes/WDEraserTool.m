//
//  WDEraserTool.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2009-2013 Steve Sprang
//

#import "WDEraserTool.h"

@implementation WDEraserTool

- (NSString *) iconName
{
    return @"eraser.png";
}

- (id) landscapeIconName
{
    return @"eraser_landscape.png";
}

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.eraseMode = YES;

    return self;
}

@end
