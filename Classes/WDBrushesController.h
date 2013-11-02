//
//  WDBrushesController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDBar;
@class WDBrushCell;
@class WDColorSlider;

@interface WDBrushesController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSMutableArray *toolbarItems_;
}

@property (nonatomic) IBOutlet UITableView *brushTable;
@property (nonatomic) IBOutlet WDBrushCell *brushCell;
@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) WDBar *topBar;
@property (nonatomic, weak) WDBar *bottomBar;
@property (nonatomic) WDBarSlider *brushSlider;


@end
