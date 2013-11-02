//
//  WDStampPicker.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

@interface WDStampPicker : UIView <UIScrollViewDelegate>

@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic) NSArray *images;
@property (nonatomic) NSMutableArray *buttonBounds;
@property (nonatomic, assign) NSUInteger selectedIndex;
@property (nonatomic) UIImageView *indicatorImageView;

- (void) chooseItemAtIndex:(NSUInteger)index;
- (void) chooseItemAtIndex:(NSUInteger)index animated:(BOOL)animated;

- (void) setImage:(UIImage *)image forIndex:(NSUInteger)ix;

@end
