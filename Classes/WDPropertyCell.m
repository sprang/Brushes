//
//  WDPropertyCell.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDProperty.h"
#import "WDPropertyCell.h"

@implementation WDPropertyCell

@synthesize slider;
@synthesize title;
@synthesize value;
@synthesize decrement;
@synthesize increment;

@synthesize property;

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) updateInterfaceElements
{
    slider.value = property.value;
    
    if (property.percentage) {
        value.text = [NSString stringWithFormat:@"%d%%", (int) roundf(property.value * property.conversionFactor)];
    } else {
        value.text = [NSString stringWithFormat:@"%d", (int) roundf(property.value * property.conversionFactor)];
    }

    increment.enabled = property.canIncrement;
    decrement.enabled = property.canDecrement;
}

- (void) propertyChanged:(NSNotification *)aNotification
{
    [self updateInterfaceElements];
}

- (void) setProperty:(WDProperty *)aProperty
{
    property = aProperty;
    title.text = property.title;
    
    // set min/max before setting the value
    slider.minimumValue = property.minimumValue;
    slider.maximumValue = property.maximumValue;
    slider.value = property.value;

    [self updateInterfaceElements];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(propertyChanged:)
                                                 name:WDPropertyChangedNotification
                                               object:aProperty];
}

- (IBAction) takeValueFrom:(UISlider *)sender
{
    self.property.value = sender.value;
}

- (IBAction)increment:(id)sender
{
    [property increment];
}

- (IBAction)decrement:(id)sender
{
    [property decrement];
}

@end
