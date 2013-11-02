//
//  WDColorComparator.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>
#import "WDColorSourceView.h"

@class WDColor;
@class WDColorWell;

@protocol WDColorComparatorDragDestination;

@interface WDColorComparator : WDColorSourceView {
    CGRect  leftCircle_;
    CGRect  rightCircle_;
}

@property (nonatomic, assign) SEL action;
@property (nonatomic, weak) id target;
@property (nonatomic) WDColor *initialColor;
@property (nonatomic) WDColor *currentColor;
@property (nonatomic, weak) WDColor *tappedColor;


@end
