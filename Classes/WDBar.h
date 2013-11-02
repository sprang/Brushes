//
//  WDBar.h
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
    WDBarTypeView,
    WDBarTypeFlexible,
    WDBarTypeFixed
} WDBarItemType;

@interface WDBarItem : NSObject 
    
@property (nonatomic) UIView *view;
@property (nonatomic) UIView *landscapeView;
@property (nonatomic, readonly) UIView *activeView;
@property (nonatomic) WDBarItemType type;
@property (nonatomic) NSUInteger width;
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL flexibleContent;
@property (nonatomic) BOOL phoneLandscapeMode;

+ (WDBarItem *) barItemWithView:(UIView *)view;
+ (WDBarItem *) barItemWithImage:(UIImage *)image target:(id)target action:(SEL)action;
+ (WDBarItem *) barItemWithImage:(UIImage *)image landscapeImage:(UIImage *)landscapeImage target:(id)target action:(SEL)action;
+ (WDBarItem *) flexibleItem;
+ (WDBarItem *) fixedItemWithWidth:(NSUInteger)width;
+ (WDBarItem *) backButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;

- (void) setImage:(UIImage *)image;

@end

typedef enum {
    WDBarTypeBottom,
    WDBarTypeTop
} WDBarType;

@interface WDBar : UIView

@property (nonatomic) NSArray *items;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) BOOL ignoreTouches;
@property (nonatomic) BOOL animateAfterLayout;
@property (nonatomic) WDBarType barType;
@property (nonatomic) float defaultFlexibleSpacing;
@property (nonatomic) BOOL phoneLandscapeMode;
@property (nonatomic) BOOL tightHitTest;

+ (WDBar *) bottomBar;
+ (WDBar *) topBar;

- (void) setTitle:(NSString *)title;
- (void) setItems:(NSArray *)items animated:(BOOL)animated;
- (void) addEdge;

- (void) setOrientation:(UIInterfaceOrientation)orientation;

@end
