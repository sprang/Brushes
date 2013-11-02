//
//  UIColor+Additions.h
//  Test
//
//  Created by Steve Sprang on 3/18/08.
//  Copyright 2008 Steve Sprang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (WDAdditions)

+ (UIColor *) randomColor:(BOOL)includeAlpha;

- (void) getHue:(float *)hue saturation:(float *)saturation brightness:(float *)brightness;

- (float) hue;
- (float) saturation;
- (float) brightness;

- (float) red;
- (float) green;
- (float) blue;

- (float) alpha;

- (void) openGLSet;
+ (UIColor *) saturatedRandomColor;

@end
