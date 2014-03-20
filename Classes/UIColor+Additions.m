//
//  UIColor+Additions.m
//  Test
//
//  Created by Steve Sprang on 3/18/08.
//  Copyright 2008 Steve Sprang. All rights reserved.
//

#import "UIColor+Additions.h"
#import "WDUtilities.h"
#import <OpenGLES/ES1/gl.h>

@implementation UIColor (WDAdditions)

+ (UIColor *) randomColor:(BOOL)includeAlpha
{
    float components[4];
    
    for (int i = 0; i < 4; i++) {
        components[i] = WDRandomFloat();
    }

    float alpha = (includeAlpha ? components[3] : 1.0f);
    alpha = 0.5 + (alpha * 0.5);
    
    return [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:alpha];
}

+ (UIColor *) saturatedRandomColor
{
    float hue = (random() % 10000);
    
    return [UIColor colorWithHue:(hue / 10000) saturation:0.69f brightness:0.75f alpha:1.0];
}

- (void) getHue:(float *)hue saturation:(float *)saturation brightness:(float *)brightness
{
    size_t          numComponents = CGColorGetNumberOfComponents([self CGColor]);
    const CGFloat   *components = CGColorGetComponents([self CGColor]);
    
    if (numComponents == 2) { // white colorspace
        *hue = 0.0f;
        *saturation = 0.0f;
        *brightness = components[0];
    } else {
        RGBtoHSV(components[0], components[1], components[2], hue, saturation, brightness);
    }
}

- (float) hue
{
    float hue, saturation, brightness;
    
    [self getHue:&hue saturation:&saturation brightness:&brightness];
    
    return hue;
}

- (float) saturation
{
    float hue, saturation, brightness;
    
    [self getHue:&hue saturation:&saturation brightness:&brightness];
    
    return saturation;
}

- (float) brightness
{
    float hue, saturation, brightness;
    
    [self getHue:&hue saturation:&saturation brightness:&brightness];
    
    return brightness;
}

- (float) red
{
    CGFloat red, green, blue, alpha;
    
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    
    return red;
}

- (float) green
{
    CGFloat red, green, blue, alpha;
    
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    
    return green;
}

- (float) blue
{
    CGFloat red, green, blue, alpha;
    
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    
    return blue;
}

- (float) alpha
{
    return CGColorGetAlpha([self CGColor]);
}

- (void) openGLSet
{
    CGFloat r, g, b, a;
    
    [self getRed:&r green:&g blue:&b alpha:&a];
    
    glColor4f(r, g, b, a);    
}

@end
