//
//  UIImage+Additions.h
//  Brushes
//
//  Created by Steve Sprang on 7/14/08.
//  Copyright 2008 Steve Sprang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (WDAdditions)

+ (UIImage *) relevantImageNamed:(NSString *)imageName;

- (void) drawToFillRect:(CGRect)bounds;

- (UIImage *) rotatedImage:(int)rotation;

- (UIImage *) downsampleWithMaxDimension:(float)constraint;

- (UIImage *) JPEGify:(float)compressionFactor;

- (BOOL) hasAlpha;
- (BOOL) reallyHasAlpha;

@end
