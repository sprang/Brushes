//
//  WDExportController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

typedef enum {
    kWDImageFormatBrushes = 0,
    kWDImageFormatPhotoshop,
    kWDImageFormatJPEG,
    kWDImageFormatPNG
} WDImageFormat;

@class WDBrowserController;

@interface WDExportController : UIViewController

@property (nonatomic, weak) WDBrowserController *browserController;

@end
