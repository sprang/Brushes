//
//  WDColorPickerController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDActiveState.h"
#import "WDBar.h"
#import "WDColor.h"
#import "WDColorComparator.h"
#import "WDColorPickerController.h"
#import "WDColorSlider.h"
#import "WDColorSquare.h"
#import "WDColorWheel.h"
#import "WDMatrix.h"
#import "WDUtilities.h"

@implementation WDColorPickerController

@synthesize color = color_;
@synthesize colorComparator = colorComparator_;
@synthesize colorSquare = colorSquare_;
@synthesize colorWheel = colorWheel_;
@synthesize swatches = swatches_;
@synthesize alphaSlider = alphaSlider_;
@synthesize delegate;
@synthesize bottomBar;
@synthesize firstCell;
@synthesize secondCell;
@synthesize matrix;

- (IBAction)dismiss:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:NO completion:nil];
}

- (void) doubleTapped:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissViewController:)]) {
        [self.delegate performSelector:@selector(dismissViewController:) withObject:self];
    }
}

- (void) takeColorFromComparator:(id)sender
{
    [self setColor:(WDColor *) [sender color]];
}

- (void) takeHueFrom:(id)sender
{
    float hue = [(WDColorWheel *)sender hue];
    WDColor *newColor = [WDColor colorWithHue:hue
                                   saturation:[color_ saturation]
                                   brightness:[color_ brightness]
                                        alpha:[color_ alpha]];
    
    [self setColor:newColor];
}

- (void) takeBrightnessAndSaturationFrom:(id)sender
{
    float saturation = [(WDColorSquare *)sender saturation];
    float brightness = [(WDColorSquare *)sender brightness];
    
    WDColor *newColor = [WDColor colorWithHue:[color_ hue]
                                   saturation:saturation
                                   brightness:brightness
                                        alpha:[color_ alpha]];
    
    [self setColor:newColor];
}

- (void) takeAlphaFrom:(WDColorSlider *)slider
{
    float alpha = slider.floatValue;
    
    WDColor *newColor = [WDColor colorWithHue:[color_ hue]
                                   saturation:[color_ saturation]
                                   brightness:[color_ brightness]
                                        alpha:alpha];
    [self setColor:newColor];
}

- (void) takeBrightnessFrom:(WDColorSlider *)slider
{
    float brightness = slider.floatValue;
    
    WDColor *newColor = [WDColor colorWithHue:[color_ hue]
                                   saturation:[color_ saturation]
                                   brightness:brightness
                                        alpha:[color_ alpha]];
    
    [self setColor:newColor];
}

- (void) takeSaturationFrom:(WDColorSlider *)slider
{
    float saturation = slider.floatValue;
    
    WDColor *newColor = [WDColor colorWithHue:[color_ hue]
                                   saturation:saturation
                                   brightness:[color_ brightness]
                                        alpha:[color_ alpha]];
    
    [self setColor:newColor];
}

- (void) setColor_:(WDColor *)color
{
    color_ = color;
    
    [self.colorWheel setColor:color_];
    [self.colorComparator setCurrentColor:color_];
    [self.colorSquare setColor:color_];
    [self.alphaSlider setColor:color_];
}

- (void) setInitialColor:(WDColor *)color
{
    [self.colorComparator setInitialColor:color];
    [self setColor_:color];
}

- (void) setColor:(WDColor *)color
{
    [self setColor_:color];
    [WDActiveState sharedInstance].paintColor = color;
}

- (WDBar *) bottomBar
{
    if (!bottomBar) {
        WDBar *aBar = [WDBar bottomBar];
        CGRect frame = aBar.frame;
        frame.origin.y  = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(aBar.frame);
        frame.size.width = CGRectGetWidth(self.view.bounds);
        aBar.frame = frame;
        aBar.tightHitTest = YES;
        
        [self.view addSubview:aBar];
        self.bottomBar = aBar;
    }
    
    return bottomBar;
}

- (NSArray *) bottomBarItems
{
    WDBarItem *dismiss = [WDBarItem barItemWithImage:[UIImage imageNamed:@"dismiss.png"]
                                      landscapeImage:[UIImage imageNamed:@"dismissLandscape.png"]
                                              target:self action:@selector(dismiss:)];
    
    NSMutableArray *items = [NSMutableArray arrayWithObjects:[WDBarItem flexibleItem], dismiss, nil];
    
    return items;
}

- (UIView *) rotatingFooterView
{
    return self.bottomBar;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.contentSizeForViewInPopover = self.view.frame.size;
    
    // set up color comparator
    self.colorComparator.target = self;
	self.colorComparator.action = @selector(takeColorFromComparator:);
    
    // set up color wheel
    UIControlEvents dragEvents = (UIControlEventTouchDown | UIControlEventTouchDragInside | UIControlEventTouchDragOutside);
    self.colorWheel.backgroundColor = nil;
    [self.colorWheel addTarget:self action:@selector(takeHueFrom:) forControlEvents:dragEvents];
    
    // set up color square
    [self.colorSquare addTarget:self action:@selector(takeBrightnessAndSaturationFrom:) forControlEvents:dragEvents];
    
    // set up swatches
    self.swatches.delegate = self;
    
    self.alphaSlider.mode = WDColorSliderModeAlpha;
    [alphaSlider_ addTarget:self action:@selector(takeAlphaFrom:) forControlEvents:dragEvents];
    
    self.initialColor = [WDActiveState sharedInstance].paintColor;
    
    if (WDDeviceIsPhone()) {
        self.bottomBar.items = [self bottomBarItems];
        [self.bottomBar setOrientation:self.interfaceOrientation];
        
        CGRect matrixFrame = WDDeviceIs4InchPhone() ? self.view.frame : CGRectInset(self.view.frame, 10, 10);
        matrix = [[WDMatrix alloc] initWithFrame:matrixFrame];
        matrix.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view insertSubview:matrix atIndex:0];
        matrix.columns = 1;
        matrix.rows = 2;
        
        self.secondCell.backgroundColor = nil;
        self.secondCell.opaque = NO;
        
        self.alphaSlider.superview.backgroundColor = nil;
        
        [matrix setCellViews:@[self.firstCell, self.secondCell]];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        if (WDDeviceIs4InchPhone()) {
            matrix.frame = CGRectOffset(CGRectInset(self.view.frame, 5, 20), 0, -5);
        } else {
            matrix.frame = self.view.frame;
        }
        
        matrix.columns = 2;
        matrix.rows = 1;
    } else {
        if (WDDeviceIs4InchPhone()) {
            matrix.frame = CGRectOffset(CGRectInset(self.view.frame, 5, 20), 0, -15);
        } else {
            matrix.frame = CGRectOffset(CGRectInset(self.view.frame, 0, 5), 0, -5);
        }
        
        matrix.columns = 1;
        matrix.rows = 2;
    }
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.bottomBar setOrientation:self.interfaceOrientation];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void) viewDidLayoutSubviews
{
    if (!WDDeviceIsPhone()) {
        return;
    }
    
    [self.bottomBar setOrientation:self.interfaceOrientation];
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
