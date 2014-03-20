//
//  UIView+Additions.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import <UIKit/UIKit.h>


@interface UIView (Additions)

@property (nonatomic, assign) CGPoint sharpCenter;

- (UIImage *) imageForViewWithScale:(float)scale;
- (void) setFramePreservingHeight:(CGRect)frame;

@end
