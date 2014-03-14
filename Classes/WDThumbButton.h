//
//  WDThumbButton.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import <Foundation/Foundation.h>

@interface WDThumbButton : UIView

+ (WDThumbButton *) thumbButtonWithFrame:(CGRect)frame;

@property (nonatomic) UIImage *image;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) BOOL pressed;
@property (nonatomic, assign) BOOL marked;

@end
