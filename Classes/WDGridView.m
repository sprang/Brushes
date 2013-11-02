//
//  WDGridView.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2012-2013 Steve Sprang
//

#import "WDGridView.h"
#import "UIView+Additions.h"
#import "WDUtilities.h"

#define kMaxInQueue 10

@implementation WDGridView {
    NSMutableDictionary *cellClassMap_;
    NSMutableDictionary *visibleCellMap_;
    NSMutableSet        *freeCells_;
    NSInteger           lastLayoutStartIndex;
    NSInteger           lastLayoutEndIndex;
}

@synthesize dataSource;

- (NSUInteger) rowsThatFit
{
    NSUInteger height = CGRectGetHeight(self.bounds);
    NSUInteger dimension = [dataSource cellDimension];
    
    NSUInteger result = floor(height / dimension) - 1;
    
    return result;
}

- (NSUInteger) cellsPerRow
{
    NSUInteger width = CGRectGetWidth(self.bounds);
    NSUInteger dimension = [dataSource cellDimension];
    
    NSUInteger num = floor(width / dimension);
    float spacing = (width - (num * dimension)) / (num + 1);
    
    if (spacing < 6) {
        num--;
    }
    
    return num;
}

- (float) centerSpacing
{
    return (CGRectGetWidth(self.bounds) + [dataSource cellDimension]) / ([self cellsPerRow] + 1);
}

- (CGSize) computeContentSize
{
    NSUInteger  numCells = [dataSource numberOfItemsInGridView:self];
    NSUInteger  cellsPerRow = [self cellsPerRow];
    NSUInteger  numRows = (numCells / cellsPerRow) + 1;
    CGSize      contentSize = [self frame].size;
    
    if (numCells % cellsPerRow != 0) {
        numRows++;
    }
    
    contentSize.height = numRows * [self centerSpacing];
    
    return contentSize;
}

- (NSMutableDictionary *) cellClassMap
{
    if (!cellClassMap_) {
        cellClassMap_ = [NSMutableDictionary dictionary];
    }
    
    return cellClassMap_;
}

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier
{
    [self cellClassMap][identifier] = cellClass;
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSUInteger)index
{
    Class cellClass = [self cellClassMap][identifier];
    
    UIView *result = [self dequeue];
    
    if (!result) {
        NSUInteger dim = [dataSource cellDimension];
        return [[cellClass alloc] initWithFrame:CGRectMake(0, 0, dim, dim)];
    }

    return result;
}

- (NSUInteger) approximateIndexOfCenter
{
    CGPoint center = WDCenterOfRect(self.bounds);
    int rowIndex = center.y / [self centerSpacing];
    int colIndex = center.x / [self centerSpacing];
    
    NSUInteger index = [self cellsPerRow] * rowIndex + colIndex;
    
    return index;
}

- (CGRect) centeredFrameForIndex:(NSUInteger)index
{
    NSInteger row = index / [self cellsPerRow];
    NSInteger col = index % [self cellsPerRow];
    float dim = [dataSource cellDimension];
    
    CGRect box = CGRectMake(-dim + (col + 1) * [self centerSpacing],
                            -dim + (row + 1) * [self centerSpacing],
                            dim, dim);
    float delta = (CGRectGetHeight(self.bounds) - CGRectGetHeight(box)) / 2.0f;
    box = CGRectOffset(box, 0, -delta);
    
    if (box.origin.y < 0) {
        box.origin.y = 0.0f;
    }
    
    return box;
}

- (void) centerIndex:(NSUInteger)index
{
    NSInteger numItems = [dataSource numberOfItemsInGridView:self];
    
    if ((index >= numItems) || (numItems <= ([self cellsPerRow] * [self rowsThatFit]))) {
        [self scrollToBottom];
    } else {
        CGPoint offset = [self centeredFrameForIndex:index].origin;
        [self setContentOffset:CGPointMake(0, offset.y)];
    }
}

- (void) scrollToBottom
{
    self.contentSize = [self computeContentSize];
    
    [self scrollRectToVisible:CGRectMake(0.0f, self.contentSize.height - 10, 1, 10) animated:NO];
    [self flashScrollIndicators];
}

- (NSMutableDictionary *) visibleCellMap
{
    if (!visibleCellMap_) {
        visibleCellMap_ = [NSMutableDictionary dictionary];
    }
    
    return visibleCellMap_;
}

- (NSArray *) visibleCells
{
    return [[self visibleCellMap] allValues];
}

-(UIView *) visibleCellForIndex:(NSUInteger)index
{
    NSNumber *key = @(index);
    return [self visibleCellMap][key];
}

- (UIView *) cellForIndex:(NSUInteger)index
{
    NSNumber *key = @(index);
    UIView  *cell = [self visibleCellMap][key];
    
    if (!cell) {
        cell = [dataSource gridView:self cellForIndex:index];
    }
    
    return cell;
}

- (NSMutableSet *) freeCells
{
    if (!freeCells_) {
        freeCells_ = [NSMutableSet set];
    }
    
    return freeCells_;
}

- (void) addToQueue:(UIView *)cell
{
    [[self freeCells] addObject:cell];
    [cell removeFromSuperview];
}

- (UIView *) dequeue
{
    UIView *view = [[self freeCells] anyObject];
    
    if (view) {
        [[self freeCells] removeObject:view];
    }
    
    return view;
}

- (void) cellsDeleted
{
    // for now, just purge everything and layout again
    
    for (UIView *cell in [self visibleCellMap].allValues) {
        [self addToQueue:cell];
        [cell removeFromSuperview];
    }
    
    visibleCellMap_ = [NSMutableDictionary dictionary];
    
    lastLayoutStartIndex = lastLayoutEndIndex = -1;
    [self setNeedsLayout];
}

- (void) layoutSubviews
{
    self.contentSize = [self computeContentSize];

    // figure out the indices of the first and last visible thumbnails
    NSInteger verticalOffset = self.contentOffset.y;
    NSInteger rowIndex = verticalOffset / [self centerSpacing];
    NSInteger index = [self cellsPerRow] * rowIndex;
    NSInteger lastRowIndex = (verticalOffset + CGRectGetHeight(self.bounds)) / [self centerSpacing];
    NSInteger lastIndex = [self cellsPerRow] * (lastRowIndex + 1);
    
    if (lastLayoutStartIndex == index && lastLayoutEndIndex == lastIndex) {
        // we're good
        return;
    }
    
    index = MAX(0, index);
    lastIndex = MIN(lastIndex, [dataSource numberOfItemsInGridView:self]);

    // move any cells that are no longer visible to the free list
    for (NSNumber *key in [self visibleCellMap].allKeys) {
        if (key.integerValue < index || key.integerValue > lastIndex) {
            UIView *cell = [self visibleCellMap][key];
            [self addToQueue:cell];
            [[self visibleCellMap] removeObjectForKey:key];
        }
    }
    
    for (NSInteger current = index; current < lastIndex; current++) {
        UIView *cell = [self cellForIndex:current];
        if (![cell superview]) {
            [self insertSubview:cell atIndex:0];
        }
        
        NSInteger row = current / [self cellsPerRow];
        NSInteger col = current % [self cellsPerRow];
        float dim = [dataSource cellDimension];
        
        CGPoint center = CGPointMake(-(dim / 2) + (col + 1) * [self centerSpacing],
                                     -(dim / 2) + (row + 1) * [self centerSpacing]);
        cell.sharpCenter = center;
        
        // keep our visible cell map up to date
        [self visibleCellMap][@(current)] = cell;
    }
    
    lastLayoutStartIndex = index;
    lastLayoutEndIndex = lastIndex;
}

@end
