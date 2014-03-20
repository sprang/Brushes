//
//  WDPaintingSizeController.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@class WDBrowserController;

@interface WDPaintingSizeController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate>

@property (nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic) IBOutlet UILabel *sizeLabel;
@property (nonatomic) IBOutlet UILabel *xLabel;
@property (nonatomic) IBOutlet UITextField *widthField;
@property (nonatomic) IBOutlet UITextField *heightField;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UIButton *rotateButton;
@property (nonatomic) NSUInteger currentPage;
@property (nonatomic) NSArray *configuration;
@property (nonatomic) NSUInteger width;
@property (nonatomic) NSUInteger height;
@property (nonatomic, weak) WDBrowserController *browserController;
@property (nonatomic) NSMutableArray *miniCanvases;

+ (void) registerDefaults;

- (IBAction) rotate:(id)sender;

- (BOOL) isCustomSize;

@end
