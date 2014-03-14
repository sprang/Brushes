//
//  WDHueSaturationController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDCanvas.h"
#import "WDChangeHueSaturation.h"
#import "WDColor.h"
#import "WDColorSlider.h"
#import "WDEtchedLine.h"
#import "WDLayer.h"
#import "WDHueSaturation.h"
#import "WDHueSaturationController.h"
#import "WDHueShifter.h"
#import "WDUtilities.h"

@implementation WDHueSaturationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    self.defaultsName = @"hue/saturation";
    
    return self;
}


- (void) performAdjustment
{
    WDHueSaturation *hueSaturation = [WDHueSaturation hueSaturationWithHue:hueShift_
                                                                saturation:(1.0 + saturationShift_)
                                                                brightness:(1.0 + brightnessShift_)];
    
    self.painting.activeLayer.hueSaturation = hueSaturation;
    [self.canvas drawView];
}

- (void) takeShiftFrom:(WDColorSlider *)sender
{
    if (sender.tag == 0) {
        hueShift_ = [sender floatValue] / 2.0f;
        int h = (int) round(hueShift_ * 360);
        hueLabel_.text = [self.formatter stringFromNumber:@(h)];
    } else if (sender.tag == 1) {
        float saturation = [sender floatValue];
        
        [saturationSlider_ setColor:[WDColor colorWithHue:0.5f saturation:saturation brightness:1 alpha:1]];
        saturationShift_ = (saturation - 0.5f) * 2;
        saturationLabel_.text = [self.formatter stringFromNumber:@(round(saturationShift_ * 100))];
    } else {
        float brightness = [sender floatValue];
        
        [brightnessSlider_ setColor:[WDColor colorWithHue:0 saturation:0 brightness:brightness alpha:1]];
        brightnessShift_ = (brightness - 0.5f) * 2;
        brightnessLabel_.text = [self.formatter stringFromNumber:@(round(brightnessShift_ * 100))];
    }
    
    [self performAdjustment];
}

- (void) takeFinalShiftFrom:(WDColorSlider *)sender
{
    [self performAdjustment];
}

- (IBAction) accept:(id)sender
{
    [super accept:sender];
 
    WDLayer *layer = self.painting.activeLayer;
    changeDocument(self.painting, [WDChangeHueSaturation changeHueSaturation:layer.hueSaturation forLayer:layer]);
}

#pragma mark - View lifecycle

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [saturationSlider_ setMode:WDColorSliderModeSaturation];
    [brightnessSlider_ setMode:WDColorSliderModeBrightness];
    
    UIControlEvents dragEvents = (UIControlEventTouchDown | UIControlEventTouchDragInside | UIControlEventTouchDragOutside);
    
    [hueShifter_ addTarget:self action:@selector(takeShiftFrom:) forControlEvents:dragEvents];
    [saturationSlider_ addTarget:self action:@selector(takeShiftFrom:) forControlEvents:dragEvents];
    [brightnessSlider_ addTarget:self action:@selector(takeShiftFrom:) forControlEvents:dragEvents];
    
    UIControlEvents touchEndEvents = (UIControlEventTouchUpInside | UIControlEventTouchUpOutside);
    
    [hueShifter_ addTarget:self action:@selector(takeFinalShiftFrom:) forControlEvents:touchEndEvents];
    [saturationSlider_ addTarget:self action:@selector(takeFinalShiftFrom:) forControlEvents:touchEndEvents];
    [brightnessSlider_ addTarget:self action:@selector(takeFinalShiftFrom:) forControlEvents:touchEndEvents];
    
    if (!WDUseModernAppearance()) {
        etchedLine_.hidden = YES;
    }
}

- (void) resetShiftsToZero
{
    hueShift_ = 0;
    saturationShift_ = 0;
    brightnessShift_ = 0;
    
    // reset sliders
    [hueShifter_ setFloatValue:hueShift_];
    [saturationSlider_ setColor:[WDColor colorWithHue:0.5 saturation:((saturationShift_ / 2) + 0.5) brightness:1 alpha:1]];
    [brightnessSlider_ setColor:[WDColor colorWithHue:0 saturation:0 brightness:((brightnessShift_ / 2) + 0.5) alpha:1]];
    
    // reset labels
    hueLabel_.text = [self.formatter stringFromNumber:@((int) round(hueShift_ * 360))];
    saturationLabel_.text = [self.formatter stringFromNumber:@((int) round(saturationShift_ * 100))];
    brightnessLabel_.text = [self.formatter stringFromNumber:@((int) round(brightnessShift_ * 100))];    
}

@end
