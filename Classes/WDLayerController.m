//
//  WDLayerController.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2010-2013 Steve Sprang
//

#import "WDActionSheet.h"
#import "WDActiveState.h"
#import "WDAddLayer.h"
#import "WDBar.h"
#import "WDBlendModePicker.h"
#import "WDChangeOpacity.h"
#import "WDColor.h"
#import "WDColorSlider.h"
#import "WDDeleteLayer.h"
#import "WDJSONCoder.h"
#import "WDLayer.h"
#import "WDLayerCell.h"
#import "WDLayerController.h"
#import "WDModifyLayer.h"
#import "WDRedoChange.h"
#import "WDReorderLayers.h"
#import "WDUndoChange.h"
#import "WDUpdateLayer.h"
#import "WDUtilities.h"
#import "UIImage+Additions.h"

@interface WDLayerController (Private)
// convert from table cell order to drawing layer order and vice versa
- (NSUInteger) flipIndex_:(NSUInteger)ix;
@end

@implementation WDLayerController

@synthesize painting = painting_;
@synthesize layerCell = layerCell_;
@synthesize opacitySlider = opacitySlider_;
@synthesize opacityLabel = opacityLabel_;
@synthesize blendModePicker;
@synthesize dirtyThumbnails;
@synthesize delegate;
@synthesize topBar;
@synthesize bottomBar;
@synthesize blendModeSheet;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (!self) {
        return nil;
    }
    
    self.title = NSLocalizedString(@"Layers", @"Layers");
        
    if (![self runningOnPhone]) {
        UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                target:self
                                                                                action:@selector(deleteLayer:)];
        
        merge_ = [[UIBarButtonItem alloc] initWithImage:[UIImage relevantImageNamed:@"merge.png"]
                                                 style:UIBarButtonItemStylePlain
                                                target:self
                                                action:@selector(mergeLayerDown:)];
        
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                             target:self                                         
                                                                             action:@selector(addLayer:)];

        UIBarButtonItem *duplicate = [[UIBarButtonItem alloc] initWithImage:[UIImage relevantImageNamed:@"duplicate.png"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(duplicateLayer:)];
        
        self.navigationItem.leftBarButtonItems = @[delete, merge_];;
        self.navigationItem.rightBarButtonItems = @[add, duplicate];
    }
    
    return self;
}

- (void) undoStatusDidChange:(NSNotification *)aNotification
{
    undo_.enabled = [self.painting.undoManager canUndo];
    redo_.enabled = [self.painting.undoManager canRedo];
}

- (void) undo:(id)sender
{
    if ([self.painting.undoManager canUndo]) {
        changeDocument(self.painting, [WDUndoChange undoChange]);
    }
}

- (void) redo:(id)sender
{
    if ([self.painting.undoManager canRedo]) {
        changeDocument(self.painting, [WDRedoChange redoChange]);
    }
}

- (void) mergeLayerDown:(id)sender
{
    changeDocument(self.painting, [WDModifyLayer modifyLayer:self.painting.activeLayer withOperation:WDMergeLayer]);
}

- (void) done:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dismissViewController:)]) {
        [self.delegate performSelector:@selector(dismissViewController:) withObject:self];
    }
}

- (NSUInteger) minimumRowHeight
{
    return [self runningOnPhone] ? 110 : 128;
}

- (void) updateRowHeight
{
    WDLayer *layer = (painting_.layers)[0];
    layerTable_.rowHeight = MAX([self minimumRowHeight], layer.thumbnailImageHeight * 0.5 + 20);
    
    [layerTable_ reloadData];
}

- (void) registerNotifications
{
    NSNotificationCenter    *defaultCenter = [NSNotificationCenter defaultCenter];
    NSUndoManager           *undoManager = painting_.undoManager;
    
    [defaultCenter addObserver:self
                      selector:@selector(undoStatusDidChange:)
                          name:NSUndoManagerDidUndoChangeNotification
                        object:undoManager];
    
    [defaultCenter addObserver:self
                      selector:@selector(undoStatusDidChange:)
                          name:NSUndoManagerDidRedoChangeNotification
                        object:undoManager];
    
    [defaultCenter addObserver:self
                      selector:@selector(undoStatusDidChange:)
                          name:NSUndoManagerWillCloseUndoGroupNotification
                        object:undoManager];
    
    [defaultCenter addObserver:self selector:@selector(activeLayerChanged:)
                          name:WDActiveLayerChangedNotification object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerAdded:)
                          name:WDLayerAddedNotification object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerDeleted:)
                          name:WDLayerDeletedNotification object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerVisibilityChanged:)
                          name:WDLayerVisibilityChanged object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerOpacityChanged:)
                          name:WDLayerOpacityChanged object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerBlendModeChanged:)
                          name:WDLayerBlendModeChanged object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerLockedStatusChanged:)
                          name:WDLayerLockedStatusChanged object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerAlphaLockedStatusChanged:)
                          name:WDLayerAlphaLockedStatusChanged object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layerThumbnailChanged:)
                          name:WDLayerThumbnailChangedNotification object:painting_];
    
    [defaultCenter addObserver:self selector:@selector(layersReordered:)
                          name:WDLayersReorderedNotification object:painting_];
}

- (void) setPainting:(WDPainting *)painting
{
    if (painting == painting_) {
        return;
    }
    
    if (painting_) {
        // stop listening to the old painting
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    
    painting_ = painting;
    [self registerNotifications];

    [self updateRowHeight];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidUnload
{
    layerTable_ = nil;
    [self.dirtyThumbnails removeAllObjects];
}

- (void) deselectSelectedRow
{
    NSUInteger      row = [self flipIndex_:painting_.indexOfActiveLayer];
    NSIndexPath     *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    [layerTable_ deselectRowAtIndexPath:indexPath animated:NO];
}

- (void) deleteLayer:(id)sender
{
    if (painting_.layers.count == 1) {
        // if there's only 1 layer, it's simpler to just clear it
        changeDocument(painting_, [WDModifyLayer modifyLayer:painting_.activeLayer withOperation:WDClearLayer]);
    } else {
        changeDocument(painting_, [WDDeleteLayer deleteLayer:painting_.activeLayer]);
    }
}

- (void) addLayer:(id)sender
{
    NSUInteger index = [painting_ indexOfActiveLayer] + 1;
    changeDocument(painting_, [WDAddLayer addLayerAtIndex:index]);
}

- (void) duplicateLayer:(id)sender
{
    [self.painting duplicateActiveLayer];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return painting_.layers.count;
}

- (void) updateCellIndices
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (WDLayerCell *cell in layerTable_.visibleCells) {
            [cell updateIndex];
        }
    });
}

- (void) layersReordered:(NSNotification *)aNotification
{
    [self updateCellIndices];
    [self enableLayerButtons];
}

- (void) layerAdded:(NSNotification *)aNotification
{
    if (activeField_) {
        [activeField_ resignFirstResponder];
    }
    
    WDLayer *addedLayer = [aNotification userInfo][@"layer"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self flipIndex_:[painting_.layers indexOfObject:addedLayer]] inSection:0];
    
    [layerTable_ beginUpdates];
    [layerTable_ insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [layerTable_ endUpdates];

    [self enableLayerButtons];
    [self updateCellIndices];
    
    // ensure that the selection indicator doesn't disappear when undoing layer reorder
    [self performSelector:@selector(selectActiveLayer) withObject:nil afterDelay:0];
}

- (void) layerDeleted:(NSNotification *)aNotification
{
    if (activeField_) {
        [activeField_ resignFirstResponder];
    }
    
    NSNumber *index = [aNotification userInfo][@"index"];
    NSUInteger row = [self flipIndex_:[index integerValue]] + 1; // add one to account for the fact that the model already deleted the entry
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    [layerTable_ beginUpdates];
    [layerTable_ deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [layerTable_ endUpdates];
    
    [self enableLayerButtons];
    [self updateCellIndices];
}

- (void) activeLayerChanged:(NSNotification *)aNotification
{    
    [self performSelector:@selector(selectActiveLayer) withObject:nil afterDelay:0];
    [self enableLayerButtons];
}

- (void) layerVisibilityChanged:(NSNotification *)aNotification
{
    WDLayer *layer = [aNotification userInfo][@"layer"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self flipIndex_:[painting_.layers indexOfObject:layer]] inSection:0];
    
    WDLayerCell *layerCell = (WDLayerCell *) [layerTable_ cellForRowAtIndexPath:indexPath];
    
    [layerCell updateVisibilityButton];
    [self enableLayerButtons];
}

- (void) layerLockedStatusChanged:(NSNotification *)aNotification
{
    WDLayer *layer = [aNotification userInfo][@"layer"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self flipIndex_:[painting_.layers indexOfObject:layer]] inSection:0];
    
    WDLayerCell *layerCell = (WDLayerCell *) [layerTable_ cellForRowAtIndexPath:indexPath];
    [layerCell updateLockedStatusButton];
    
    [self enableLayerButtons];
}

- (void) layerAlphaLockedStatusChanged:(NSNotification *)aNotification
{
    WDLayer *layer = [aNotification userInfo][@"layer"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self flipIndex_:[painting_.layers indexOfObject:layer]] inSection:0];
    
    WDLayerCell *layerCell = (WDLayerCell *) [layerTable_ cellForRowAtIndexPath:indexPath];
    [layerCell updateAlphaLockedStatusButton];
}

- (void) layerBlendModeChanged:(NSNotification *)aNotification
{
    if ([self runningOnPhone]) {
        WDLayer *layer = [aNotification userInfo][@"layer"];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self flipIndex_:[painting_.layers indexOfObject:layer]] inSection:0];
        
        WDLayerCell *layerCell = (WDLayerCell *) [layerTable_ cellForRowAtIndexPath:indexPath];
        [layerCell updateBlendMode];
    } else {
        [self updateBlendMode];
    }
}

- (void) layerOpacityChanged:(NSNotification *)aNotification
{
    WDLayer *layer = [aNotification userInfo][@"layer"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self flipIndex_:[painting_.layers indexOfObject:layer]] inSection:0];
    
    WDLayerCell *layerCell = (WDLayerCell *) [layerTable_ cellForRowAtIndexPath:indexPath];
    [layerCell updateOpacity];
    
    [self updateOpacity];
}

- (BOOL) isVisible
{
    return (self.isViewLoaded && self.view.window) ? YES : NO;
}

- (NSMutableSet *) dirtyThumbnails
{
    if (!dirtyThumbnails) {
        dirtyThumbnails = [[NSMutableSet alloc] init];
    }
    
    return dirtyThumbnails;
}

- (void) layerThumbnailChanged:(NSNotification *)aNotification
{
    if (!layerTable_) {
        return;
    }
    
    WDLayer *layer = [aNotification userInfo][@"layer"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self flipIndex_:[painting_.layers indexOfObject:layer]] inSection:0];
    
    WDLayerCell *layerCell = (WDLayerCell *) [layerTable_ cellForRowAtIndexPath:indexPath];
    
    if (layerCell) {
        [self isVisible] ? [layerCell updateThumbnail] : [self.dirtyThumbnails addObject:layerCell];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"LayerCell";
    WDLayer         *layer = (painting_.layers)[[self flipIndex_:indexPath.row]];
    
    WDLayerCell *cell = (WDLayerCell *) [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        NSString *nibName = @"LayerCell";
        [[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil];
        cell = layerCell_;
        self.layerCell = nil;
        cell.delegate = self;
        
        [self.layerCell.blendModeButton addTarget:self action:@selector(blendModeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    cell.paintingLayer = layer;
    
    return cell;
}
     
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return ((UITextField *)textField.superview.superview).selected;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeField_ = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // painting_.activeLayer.name = textField.text;
    activeField_ = nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {    
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (sourceIndexPath == destinationIndexPath) {
        return;
    }
    
    if (activeField_) {
        [activeField_ resignFirstResponder];
    }
    
    NSUInteger srcIndex = sourceIndexPath.row;
    NSUInteger destIndex = destinationIndexPath.row;
    
    srcIndex = [self flipIndex_:srcIndex];
    destIndex = [self flipIndex_:destIndex];
    
    changeDocument(self.painting, [WDReorderLayers moveLayer:(painting_.layers)[srcIndex] toIndex:(int)destIndex]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath
{    
    NSUInteger index = [self flipIndex_:newIndexPath.row];
    
    if (activeField_) {
        [activeField_ resignFirstResponder];
    }
    
    [painting_ activateLayerAtIndex:index];
    
    self.navigationItem.leftBarButtonItem.enabled = [painting_ canDeleteLayer];
    
    if (delete_) {
        delete_.enabled = [painting_ canDeleteLayer];
    }
}

- (void) scrollToSelectedRowIfNotVisible
{
    UITableViewCell *selected = [layerTable_ cellForRowAtIndexPath:[layerTable_ indexPathForSelectedRow]];

    // if the cell is nil or not completely visible, we should scroll the table
    if (!selected || !CGRectIntersectsRect(selected.frame, layerTable_.bounds)) {
        [layerTable_ scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

- (void) selectActiveLayer
{
    [self updateOpacity];
    [self updateBlendMode];
    
    NSUInteger  activeRow = [self flipIndex_:painting_.indexOfActiveLayer];
    
    if ([[layerTable_ indexPathForSelectedRow] isEqual:[NSIndexPath indexPathForRow:activeRow inSection:0]]) {
        [self scrollToSelectedRowIfNotVisible];
        return;
    }
    
    for (NSUInteger i = 0; i < painting_.layers.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        
        if (i != activeRow) {
            [layerTable_ cellForRowAtIndexPath:indexPath].selected = NO;
            [layerTable_ deselectRowAtIndexPath:indexPath animated:NO];
        } else {
            
            [layerTable_ selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        }
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    
    [self.opacitySlider setMode:WDColorSliderModeAlpha];
    
    UIControlEvents dragEvents = (UIControlEventTouchDown | UIControlEventTouchDragInside |UIControlEventTouchDragOutside);
    [self.opacitySlider addTarget:self action:@selector(opacitySliderMoved:) forControlEvents:dragEvents];
    
    UIControlEvents touchEndEvents = (UIControlEventTouchUpInside | UIControlEventTouchUpOutside);
    [self.opacitySlider addTarget:self action:@selector(takeOpacityFrom:) forControlEvents:touchEndEvents];
    
    [layerTable_ setEditing:YES];
    layerTable_.backgroundColor = nil;
    
    [self updateRowHeight];
    
    blendModePicker.titles = WDBlendModeDisplayNames();
    blendModePicker.target = self;
    blendModePicker.action = @selector(takeBlendModeFrom:);
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] init];
    doubleTap.numberOfTapsRequired = 2;
    [doubleTap addTarget:self action:@selector(done:)];
    [layerTable_ addGestureRecognizer:doubleTap];
    
    if ([self runningOnPhone]) {
        [self.topBar addEdge];
        self.topBar.ignoreTouches = NO;
        self.topBar.items = [self topBarItems];
        [self.topBar setTitle:NSLocalizedString(@"Layers", @"Layers")];
        
        [self.bottomBar addEdge];
        self.bottomBar.ignoreTouches = NO;
        self.bottomBar.items = [self bottomBarItems];
    }
    
    self.contentSizeForViewInPopover = self.view.frame.size;
}

- (WDBar *) topBar
{
    if (!topBar) {
        WDBar *aBar = [WDBar topBar];
        CGRect frame = aBar.frame;
        frame.size.width = CGRectGetWidth(self.view.bounds);
        aBar.frame = frame;
        
        [self.view addSubview:aBar];
        self.topBar = aBar;
    }
    
    return topBar;
}

- (WDBar *) bottomBar
{
    if (!bottomBar) {
        WDBar *aBar = [WDBar bottomBar];
        CGRect frame = aBar.frame;
        frame.origin.y  = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(aBar.frame);
        frame.size.width = CGRectGetWidth(self.view.bounds);
        aBar.frame = frame;
        
        [self.view addSubview:aBar];
        self.bottomBar = aBar;
    }
    
    return bottomBar;
}

- (NSArray *) topBarItems
{
    delete_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"trash.png"] target:self action:@selector(deleteLayer:)];
    add_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"add.png"] target:self action:@selector(addLayer:)];
    duplicate_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"duplicate.png"] target:self action:@selector(duplicateLayer:)];
                            
    NSMutableArray *items = [NSMutableArray arrayWithObjects: delete_, [WDBarItem flexibleItem], duplicate_, add_, nil];
    
    return items;
}

- (NSArray *) bottomBarItems
{
    merge_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"merge.png"]
                          landscapeImage:[UIImage imageNamed:@"mergeLandscape.png"]
                                  target:self action:@selector(mergeLayerDown:)];
    
    undo_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"undo.png"]
                         landscapeImage:[UIImage imageNamed:@"undoLandscape.png"]
                                 target:self action:@selector(undo:)];
    
    redo_ = [WDBarItem barItemWithImage:[UIImage imageNamed:@"redo.png"]
                         landscapeImage:[UIImage imageNamed:@"redoLandscape.png"]
                                 target:self action:@selector(redo:)];

    WDBarItem *dismiss = [WDBarItem barItemWithImage:[UIImage imageNamed:@"dismiss.png"]
                                      landscapeImage:[UIImage imageNamed:@"dismissLandscape.png"]
                                              target:self action:@selector(done:)];
    
    NSMutableArray *items = [NSMutableArray arrayWithObjects:merge_, [WDBarItem flexibleItem],
                             undo_, [WDBarItem flexibleItem],
                             redo_, [WDBarItem flexibleItem],
                             dismiss, nil];
    
    return items;
}

- (BOOL) runningOnPhone
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (dirtyThumbnails) {
        [dirtyThumbnails makeObjectsPerformSelector:@selector(updateThumbnail)];
        [dirtyThumbnails removeAllObjects];
    }
        
    if ([self runningOnPhone]) {
        [self.navigationController setNavigationBarHidden:YES];
        [self configureForOrientation:self.interfaceOrientation];
    }
    
    if (WDDeviceIsPhone()) {
        layerTable_.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    // make sure the undo/redo buttons have the correct enabled state
    [self undoStatusDidChange:nil];

    [self enableLayerButtons];
    [self selectActiveLayer];
         
    [layerTable_ flashScrollIndicators];
}

- (void) enableLayerButtons
{
    self.navigationItem.leftBarButtonItem.enabled = [painting_ canDeleteLayer];
    
    BOOL enabled = [painting_ canAddLayer];
    for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) {
        item.enabled = enabled;
    }
    
    if (delete_) {
        delete_.enabled = [painting_ canDeleteLayer];
        duplicate_.enabled = enabled;
        add_.enabled = enabled;
    }
    
    if (merge_) {
        ((UIBarButtonItem *)merge_).enabled = [painting_ canMergeDown];
    }
}

- (void) updateOpacity
{
    opacitySlider_.color = [WDColor colorWithWhite:1.0 alpha:painting_.activeLayer.opacity];
    
    int rounded = round(painting_.activeLayer.opacity * 100);
    opacityLabel_.text = [NSString stringWithFormat:@"%d%%", rounded];
}

- (void) updateBlendMode
{
    NSUInteger blendIx = painting_.activeLayer.blendMode;
    
    blendIx = [WDBlendModes() indexOfObject:@(blendIx)];
    
    if (blendModePicker.selectedIndex != blendIx) {
        [blendModePicker chooseItemAtIndexSilent:blendIx];
    }    
}

- (void) opacitySliderMoved:(WDColorSlider *)sender
{
    int rounded = round(sender.floatValue * 100);
    opacityLabel_.text = [NSString stringWithFormat:@"%d%%", rounded];
    
    WDLayerCell *cell = (WDLayerCell *) [layerTable_ cellForRowAtIndexPath:[layerTable_ indexPathForSelectedRow]];
    [cell setOpacity:sender.floatValue];

    opacitySlider_.color = [WDColor colorWithWhite:1.0 alpha:sender.floatValue];
}

- (void) takeBlendModeFrom:(WDBlendModePicker *)picker
{
    NSUInteger modeIndex = picker.selectedIndex;
    NSNumber *blendModeValue = WDBlendModes()[modeIndex];
    WDBlendMode mode = (WDBlendMode) blendModeValue.integerValue;
    
    [self setBlendMode:mode forLayer:painting_.activeLayer];
}

- (void) takeOpacityFrom:(WDColorSlider *)sender
{
    float opacity = sender.floatValue;
    WDLayer *layer = painting_.activeLayer;
    if (opacity != layer.opacity) {
        changeDocument(painting_, [WDChangeOpacity changeOpacity:opacity forLayer:layer]);
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (UIView *) rotatingHeaderView
{
    return self.topBar;
}

- (UIView *) rotatingFooterView
{
    return self.bottomBar;
}

- (void) configureForOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{    
    [self.topBar setOrientation:toInterfaceOrientation];
    [self.bottomBar setOrientation:toInterfaceOrientation];
    layerTable_.contentInset = UIEdgeInsetsMake(CGRectGetHeight(topBar.frame), 0, 0, 0);
    
    CGRect frame = opacitySlider_.superview.frame;
    frame.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.bottomBar.frame) - CGRectGetHeight(frame);
    opacityLabel_.superview.frame = frame;
    
    frame = layerTable_.frame;
    frame.size.height = CGRectGetMinY(opacitySlider_.superview.frame);
    layerTable_.frame = frame;
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self runningOnPhone]) {
        [self configureForOrientation:toInterfaceOrientation];
    }
}

- (void) setBlendMode:(WDBlendMode)mode forLayer:(WDLayer *)layer
{
    NSString *format = NSLocalizedString(@"Blend Mode: %@", @"Blend Mode: %@");
    NSString *actionName = [NSString stringWithFormat:format, WDDisplayNameForBlendMode(mode)];
    [[painting_ undoManager] setActionName:actionName];
    
    if (mode != layer.blendMode) {
        WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
        WDLayer *updated = [coder copy:layer deep:NO];
        updated.blendMode = mode;
        changeDocument(painting_, [WDUpdateLayer updateLayer:updated]);
    }
}

- (void) editBlendModeForLayer:(WDLayer *)layer
{
    self.blendModeSheet = [WDActionSheet sheet];
    
    __unsafe_unretained WDLayerController *layerController = self;
    
    for (NSNumber *mode in WDBlendModes()) {
        [blendModeSheet addButtonWithTitle:WDDisplayNameForBlendMode((WDBlendMode)mode.integerValue)
                                    action:^(id sender) {
                                        [layerController setBlendMode:(WDBlendMode)mode.integerValue forLayer:layer];
                                    }];
    }
    
    [blendModeSheet addCancelButton];
    
    blendModeSheet.delegate = self;
    [blendModeSheet.sheet showInView:self.view];
}

- (void) actionSheetDismissed:(WDActionSheet *)actionSheet
{
    if (actionSheet == blendModeSheet) {
        self.blendModeSheet = nil;
    }
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end

@implementation WDLayerController (Private)

- (NSUInteger) flipIndex_:(NSUInteger)ix
{
    return (painting_.layers.count - ix - 1);
}

@end
