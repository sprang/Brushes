//
//  WDMatrix.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDMatrix.h"
#import "UIView+Additions.h"

@implementation WDMatrix

@synthesize rows;
@synthesize columns;
@synthesize cellViews;

- (void) setRows:(NSUInteger)inRows
{
    rows = inRows;
    [self setNeedsLayout];
}

- (void) setColumns:(NSUInteger)inColumns
{
    columns = inColumns;
    [self setNeedsLayout];
}

- (void) setCellViews:(NSArray *)inCellViews
{
    // remove old cells
    for (UIView *cell in cellViews) {
        [cell removeFromSuperview];
    }
    
    // release old and retain new
    cellViews = inCellViews;
    
    // add the new cells to the view
    for (UIView *cell in cellViews) {
        [self addSubview:cell];
    }

    [self setNeedsLayout];
}

- (void) layoutSubviews
{
    UIView *canonicalCell = [cellViews lastObject];
    CGSize cellSize = canonicalCell.frame.size;
    
    float halfCellWidth = cellSize.width / 2.0f;
    float halfCellHeight = cellSize.height / 2.0f;
    
    float xOffset = (CGRectGetWidth(self.bounds) - (columns * cellSize.width)) / (columns + 1);
    xOffset += halfCellWidth;
    float yOffset = (CGRectGetHeight(self.bounds) - (rows * cellSize.height)) / (rows + 1);
    yOffset += halfCellHeight;
    
    float xSpacing = xOffset + halfCellWidth;
    float ySpacing = yOffset + halfCellHeight;
    
    NSEnumerator *oe = [cellViews objectEnumerator];
    
    for (int y = 0; y < rows; y++) {
        for (int x = 0; x < columns; x++) {
            UIView *cell = [oe nextObject];
            cell.sharpCenter = CGPointMake(xOffset + x * xSpacing, yOffset + y * ySpacing);
        }
    }
}

@end
