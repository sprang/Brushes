//
//  WDActiveState.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "NSArray+Additions.h"

#import "WDActiveState.h"
#import "WDBrush.h"
#import "WDCoder.h"
#import "WDColor.h"
#import "WDEraserTool.h"
#import "WDJSONCoder.h"
#import "WDStylusManager.h"
#import "WDUtilities.h"

#import "WDBristleGenerator.h"
#import "WDCirclesGenerator.h"
#import "WDCrossHatchGenerator.h"
#import "WDMosaicGenerator.h"
#import "WDRoundGenerator.h"
#import "WDSquareBristleGenerator.h"
#import "WDVerticalBristleGenerator.h"
#import "WDPolygonGenerator.h"
#import "WDRectGenerator.h"
#import "WDStarGenerator.h"
#import "WDSpiralGenerator.h"
#import "WDZigZagGenerator.h"
#import "WDSplatGenerator.h"
#import "WDSplotchGenerator.h"

NSString *WDActiveToolDidChange = @"WDActiveToolDidChange";
NSString *WDActivePaintColorDidChange = @"WDActivePaintColorDidChange";
NSString *WDActiveBrushDidChange = @"WDActiveBrushDidChange";

NSString *WDBrushAddedNotification = @"WDBrushAddedNotification";
NSString *WDBrushDeletedNotification = @"WDBrushDeletedNotification";

static NSString *WDBrushesKey = @"WDBrushesKey";
static NSString *WDDeviceIdKey = @"WDDeviceIdKey";
static NSString *WDPaintColorKey = @"WDPaintColorKey";
static NSString *WDSwatchKey = @"WDSwatchKey";

@interface WDActiveState ()
@property (nonatomic) NSMutableArray *brushes;
- (WDColor *) defaultPaintColor;
@end;

@implementation WDActiveState {
    NSMutableDictionary *brushMap_;
    WDBrush *paintBrush;
    WDBrush *eraseBrush;
}

@synthesize activeTool = activeTool_;
@synthesize deviceID = deviceID_;
@synthesize paintColor = paintColor_;
@synthesize tools = tools_;
@synthesize brushes = brushes_;

+ (WDActiveState *) sharedInstance
{
    static WDActiveState *toolManager_ = nil;
    
    if (!toolManager_) {
        toolManager_ = [[WDActiveState alloc] init];
    }
    
    return toolManager_;
}

- (id) init
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Configure swatches
    NSData *archivedSwatches = [defaults objectForKey:WDSwatchKey];
    if (archivedSwatches) {
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:archivedSwatches options:0 error:&error];
        if (json) {
            WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
            swatches_ = [coder reconstruct:json binary:nil];
        }
    }
    if (!swatches_) {
        // swatches were either undefined or could not be unarchived
        swatches_ = [[NSMutableDictionary alloc] init];
        
        // add some default swatches        
        int total = 0;
        [self setSwatch:[WDColor colorWithHue:(180.0f / 360) saturation:0.21f brightness:0.56f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(138.0f / 360) saturation:0.36f brightness:0.71f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(101.0f / 360) saturation:0.38f brightness:0.49f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(215.0f / 360) saturation:0.34f brightness:0.87f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(207.0f / 360) saturation:0.90f brightness:0.64f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(229.0f / 360) saturation:0.59f brightness:0.45f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(331.0f / 360) saturation:0.28f brightness:0.51f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(44.0f / 360) saturation:0.77f brightness:0.85f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(15.0f / 360) saturation:0.39f brightness:0.98f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(84.0f / 360) saturation:0.15f brightness:0.9f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(59.0f / 360) saturation:0.27f brightness:0.99f alpha:1] atIndex:total]; total++;
        [self setSwatch:[WDColor colorWithHue:(51.0f / 360) saturation:0.08f brightness:0.96f alpha:1] atIndex:total]; total++;
        
        for (int i = 0; i <= 4; i++) {
            float w = i; w /= 4.0f;
            [self setSwatch:[WDColor colorWithWhite:w alpha:1.0] atIndex:total]; total++;
        }
    }
    
    // configure paint color
    NSDictionary *colorDict = [defaults objectForKey:WDPaintColorKey];
    paintColor_ = colorDict ? [WDColor colorWithDictionary:colorDict] : [self defaultPaintColor];
    
    // use a unique deviceID since we are not allowed to use the one on UIDevice
    deviceID_ = [defaults objectForKey:WDDeviceIdKey];
    if (!deviceID_) {
        deviceID_ = generateUUID();
        [defaults setObject:deviceID_ forKey:WDDeviceIdKey];
    }
    
    [self performSelector:@selector(configureBrushes) withObject:nil afterDelay:0];
    
    self.activeTool = (self.tools)[0];
    
    brushMap_ = [[NSMutableDictionary alloc] init];
    
    return self;
}

#pragma mark - Paint Color

- (WDColor *) defaultPaintColor
{
    return [WDColor colorWithHue:(138.0f / 360) saturation:0.36f brightness:0.71f alpha:1];
}

- (void) setPaintColor:(WDColor *)paintColor
{
    paintColor_ = paintColor;
    
    [[NSUserDefaults standardUserDefaults] setObject:[paintColor_ dictionary] forKey:WDPaintColorKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:WDActivePaintColorDidChange object:nil userInfo:nil];
    
    [[WDStylusManager sharedStylusManager] setPaintColor:paintColor.UIColor];
    
    [self setActiveTool:tools_[0]];
}

#pragma mark -  Tools

- (NSArray *) tools
{
    if (!tools_) {
        tools_ = @[[WDFreehandTool tool],
                  [WDEraserTool tool]];
    }
    
    return tools_;
}

- (void) setActiveTool:(WDTool *)activeTool
{
    if (activeTool == activeTool_) {
        return;
    }
    
    [activeTool_ deactivated];
    activeTool_ = activeTool;
    
    [activeTool_ activated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDActiveToolDidChange object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:WDActiveBrushDidChange object:nil userInfo:nil];
}

#pragma mark - Swatches

- (void) saveSwatches
{
    WDJSONCoder *coder = [[WDJSONCoder alloc] init];
    [coder encodeDictionary:swatches_ forKey:nil];
    NSData *swatchData = [coder jsonData];
    [[NSUserDefaults standardUserDefaults] setObject:swatchData forKey:WDSwatchKey];
}

- (WDColor *) swatchAtIndex:(NSUInteger)index
{
    return swatches_[[@(index) stringValue]];
}

- (void) setSwatch:(WDColor *)color atIndex:(NSUInteger)index
{
    NSString *key = [@(index) stringValue];
    
    if (!color) {
        [swatches_ removeObjectForKey:key];
    } else {
        swatches_[key] = color;
    }
    
    [self saveSwatches];
}

#pragma mark - Brushes

- (BOOL) eraseMode
{
    return [activeTool_ isKindOfClass:[WDEraserTool class]];
}

- (WDBrush *) brush
{
    WDBrush *b = self.eraseMode ? eraseBrush : paintBrush;
    if (b) {
        return b;
    } else {
        if (self.eraseMode) {
            b = eraseBrush = paintBrush;
        } else {
            b = paintBrush = eraseBrush;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:WDActiveBrushDidChange object:nil userInfo:nil];
    }
    return b;
}

- (void) mapBrushes
{
    [self.brushes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        WDBrush *brush = obj;
        brushMap_[brush.uuid] = brush;
    }];
}

- (void) saveBrushes
{
    WDJSONCoder *coder = [[WDJSONCoder alloc] init];
    [coder encodeArray:self.brushes forKey:nil];
    NSData *brushData = [coder jsonData];
    [[NSUserDefaults standardUserDefaults] setObject:brushData forKey:@"brushes"];
    [self mapBrushes];
    NSInteger brushIndex = [self.brushes indexOfObjectIdenticalTo:paintBrush];
    [[NSUserDefaults standardUserDefaults] setObject:@(brushIndex) forKey:@"brush"];
    NSInteger eraserIndex = [self.brushes indexOfObjectIdenticalTo:eraseBrush];
    [[NSUserDefaults standardUserDefaults] setObject:@(eraserIndex) forKey:@"eraser"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) initializeBrushes
{
    // configure brushes (temporary setup)
    self.brushes = [NSMutableArray array];
    for (int i = 0; i < 12; i++) {
        [self.brushes addObject:[WDBrush randomBrush]];
    }
    [self saveBrushes];
}

- (void) configureBrushes
{
    NSData *brushData = [[NSUserDefaults standardUserDefaults] objectForKey:@"brushes"];
    
    if (!brushData) {
        // load default brushes
        brushData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"default_brushes" ofType:@"json"]];
    }
    
    if (brushData) {
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:brushData options:0 error:&error];
        if (json) {
            WDJSONCoder *coder = [[WDJSONCoder alloc] initWithProgress:nil];
            self.brushes = [coder reconstruct:json binary:nil];
        } else {
            WDLog(@"Error loading saved brushes: %@", error);
            [self initializeBrushes];
        }
    } else {
        // create some random ones
        [self initializeBrushes];
    }
    [self mapBrushes];
    
    int index = [[[NSUserDefaults standardUserDefaults] objectForKey:@"brush"] intValue];
    if (index < 0 || index >= self.brushes.count) {
        index = 0;
    }
    paintBrush = (self.brushes)[index];

    index = [[[NSUserDefaults standardUserDefaults] objectForKey:@"eraser"] intValue];
    if (index < 0 || index >= self.brushes.count) {
        index = 0;
    }
    eraseBrush = (self.brushes)[index];
}

- (WDBrush *) brushAtIndex:(NSUInteger)index
{
    if (index > self.brushes.count) {
        return nil;
    }
    
    return (self.brushes)[index];
}

- (WDBrush *) brushWithID:(NSString *)uuid
{
    WDBrush *brush = brushMap_[uuid];
    if (!brush) {
        WDLog(@"ERROR: Brush not found: %@", uuid);
        brush = [self brushAtIndex:0];
    }
    return brush;
}

- (NSUInteger) indexOfBrush:(WDBrush *)brush
{
    return [brushes_ indexOfObjectIdenticalTo:brush];
}

- (NSUInteger) indexOfActiveBrush
{
    return [brushes_ indexOfObjectIdenticalTo:self.brush];
}

- (BOOL) canDeleteBrush
{
    return (brushes_.count > 1);
}

- (void) deleteActiveBrush
{
    if ([self canDeleteBrush]) {
        NSUInteger index = self.indexOfActiveBrush;
        
        [brushes_ removeObjectIdenticalTo:self.brush];
        if (paintBrush == eraseBrush) {
            if (self.eraseMode) {
                paintBrush = nil;
            } else {
                eraseBrush = nil;
            }
        }
    
        NSDictionary *userInfo = @{@"index": @(index)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDBrushDeletedNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        index = WDClamp(0, brushes_.count - 1, index);
        [self selectBrushAtIndex:index];
    }
}

- (void) addBrush:(WDBrush *)brush
{
    NSUInteger index = [self indexOfActiveBrush];
    
    [brushes_ insertObject:brush atIndex:index];
    
    NSDictionary *userInfo = @{@"brush": brush,
                              @"index": @(index)};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDBrushAddedNotification
                                                        object:nil
                                                      userInfo:userInfo];
    
    [self selectBrushAtIndex:index];
}

- (void) addTemporaryBrush:(WDBrush *)brush
{
    brushMap_[brush.uuid] = brush;
}

- (void) moveBrushAtIndex:(NSUInteger)src toIndex:(NSUInteger)dst
{
    WDBrush *brush = brushes_[src];
    
    [brushes_ removeObjectIdenticalTo:brush];
    [brushes_ insertObject:brush atIndex:dst];
}

- (void) brushGeneratorChanged:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WDActiveBrushDidChange object:nil userInfo:nil];
}

- (void) brushGeneratorReplaced:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:WDActiveBrushDidChange object:nil userInfo:nil];
}

- (void) selectBrushAtIndex:(NSUInteger)index
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    WDBrush *oldBrush = self.brush;
    WDBrush *newBrush = brushes_[index];
    if (oldBrush) {
        [nc removeObserver:self name:nil object:oldBrush];
    }

    if (self.eraseMode) {
        eraseBrush = newBrush;
    } else {
        paintBrush = newBrush;
    }
    
    [nc addObserver:self selector:@selector(brushGeneratorChanged:) name:WDBrushGeneratorChanged object:newBrush];
    [nc addObserver:self selector:@selector(brushGeneratorReplaced:) name:WDBrushGeneratorReplaced object:newBrush];
    
    [nc postNotificationName:WDActiveBrushDidChange object:nil userInfo:nil];
}

- (NSUInteger) brushesCount
{
    return brushes_.count;
}

#pragma mark - Generators

- (NSArray *) stampClasses
{
    static NSArray *classes_ = nil;
    
    if (!classes_) {
        classes_ = @[[WDBristleGenerator class],
                    [WDRoundGenerator class],
                    [WDSplatGenerator class],
                    [WDSplotchGenerator class],
                    [WDZigZagGenerator class],
                    [WDCirclesGenerator class],
                    [WDSpiralGenerator class],
                    [WDCrossHatchGenerator class],
                    [WDVerticalBristleGenerator class],
                    [WDMosaicGenerator class],
                    [WDSquareBristleGenerator class],
                    [WDPolygonGenerator class],
                    [WDStarGenerator class],
                    [WDRectGenerator class]];
        
    }
    
    return classes_;
}

- (NSArray *) canonicalGenerators
{
    if (!canonicalGenerators_) {
        NSArray *result = [[self stampClasses] map:^id(id obj) {
            WDStampGenerator *gen = [obj generator];
            [gen randomize];
            return gen;
        }];
        
        canonicalGenerators_ = [result mutableCopy];
    }
    
    return canonicalGenerators_;
}

- (void) setCanonicalGenerator:(WDStampGenerator *)aGenerator
{
    int ix = 0;
    
    for (WDStampGenerator *gen in self.canonicalGenerators) {
        if ([gen class] == [aGenerator class]) {
            break;
        }
        ix++;
    }
    
    if (![aGenerator isEqual:canonicalGenerators_[ix]]) {
        canonicalGenerators_[ix] = [aGenerator copy];
    }
}

- (NSUInteger) indexForGeneratorClass:(Class)class
{
    return [[self stampClasses] indexOfObject:class];
}

- (void) resetActiveTool
{
    self.activeTool = tools_[0];
}

@end
