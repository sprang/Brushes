//
//  WDBrushCell.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDBrush;

@interface WDBrushCell : UITableViewCell

@property (nonatomic) IBOutlet UIImageView *preview;
@property (nonatomic) IBOutlet UILabel *size;
@property (nonatomic) IBOutlet UIButton *editButton;

@property (nonatomic) WDBrush *brush;
@property (nonatomic, weak) UITableView *table;

@property (nonatomic) BOOL previewDirty;

- (IBAction)disclose:(id)sender;

@end
