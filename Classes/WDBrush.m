//
//  WDBrush.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import "WDActiveState.h"
#import "WDBristleGenerator.h"
#import "WDBrush.h"
#import "WDBrushPreview.h"
#import "WDCoder.h"
#import "WDDecoder.h"
#import "WDUtilities.h"

NSString *WDBrushPropertyChanged = @"WDBrushPropertyChanged";
NSString *WDBrushGeneratorChanged = @"WDBrushGeneratorChanged";
NSString *WDBrushGeneratorReplaced = @"WDBrushGeneratorReplaced";

static NSString *WDGeneratorKey = @"generator";
static NSString *WDWeightKey = @"weight";
static NSString *WDIntensityKey = @"intensity";
static NSString *WDAngleKey = @"angle";
static NSString *WDSpacingKey = @"spacing";
static NSString *WDRotationalScatterKey = @"rotationalScatter";
static NSString *WDPositionalScatterKey = @"positionalScatter";
static NSString *WDAngleDynamicsKey = @"angleDynamics";
static NSString *WDWeightDynamicsKey = @"weightDynamics";
static NSString *WDIntensityDynamicsKey = @"intensityDynamics";
static NSString *WDUUIDKey = @"uuid";

@interface WDBrush ()
@property (nonatomic, assign) NSUInteger suppressNotifications;
@property (nonatomic) NSMutableSet *changedProperties;

- (void) suppressNotifications:(BOOL)flag;
@end

@implementation WDBrush

@synthesize generator;
@synthesize noise;

@synthesize weight;
@synthesize intensity;

@synthesize angle;
@synthesize spacing;
@synthesize rotationalScatter;
@synthesize positionalScatter;

@synthesize angleDynamics;
@synthesize weightDynamics;
@synthesize intensityDynamics;

@synthesize strokePreview;
@synthesize suppressNotifications;
@synthesize changedProperties;

@synthesize uuid = uuid_;

+ (WDBrush *) brushWithGenerator:(WDStampGenerator *)generator
{
    return [[[self class] alloc] initWithGenerator:generator];
}

+ (WDBrush *) randomBrush
{
    NSArray *generators = [[WDActiveState sharedInstance] canonicalGenerators];
    WDStampGenerator *generator = generators[WDRandomIntInRange(0, generators.count)];
    
    WDBrush *random = [WDBrush brushWithGenerator:[generator copy]];
    
    [generator randomize];
    [generator configureBrush:random];
    
    random.weight.value = WDRandomFloat() * 56 + 44;
    random.intensity.value = 0.15f;
    random.spacing.value = 0.02;
    
    return random;
}

- (id) copyWithZone:(NSZone *)zone
{
    WDStampGenerator *gen = [self.generator copy];
    WDBrush *copy = [[WDBrush alloc] initWithGenerator:gen];
    
    copy.angle.value = angle.value;
    copy.weight.value = weight.value;
    copy.intensity.value = intensity.value;
    copy.spacing.value = spacing.value;
    copy.rotationalScatter.value = rotationalScatter.value;
    copy.positionalScatter.value = positionalScatter.value;
    copy.angleDynamics.value = angleDynamics.value;
    copy.weightDynamics.value = weightDynamics.value;
    copy.intensityDynamics.value = intensityDynamics.value;
    
    copy.uuid = self.uuid;
    return copy;
}

- (BOOL) isEqual:(WDBrush *)object
{
    if (!object) {
        return NO;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    // in theory, if the uuid matches the rest should match too
    return ([self.uuid isEqualToString:object.uuid] &&
            [self.generator isEqual:object.generator] &&
            [[self allProperties] isEqual:[object allProperties]]);
}

- (NSUInteger) hash
{
    return self.uuid.hash;
}

- (void) suppressNotifications:(BOOL)flag
{
    suppressNotifications += flag ? 1 : (-1);
}

- (void) restoreDefaults
{
    self.changedProperties = [NSMutableSet set];
    
    [self suppressNotifications:YES];
    
    [[self generator] configureBrush:self];
    
    [self suppressNotifications:NO];
    
    if (changedProperties.count) {
        self.uuid = nil;
        self.strokePreview = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDBrushPropertyChanged
                                                            object:self
                                                          userInfo:@{@"properties": changedProperties}];
    }
    
    self.changedProperties = nil;
}

- (void) buildProperties
{
    self.weight = [WDProperty property];
    weight.title = NSLocalizedString(@"Weight", @"Weight");
    weight.conversionFactor = 1;
    weight.minimumValue = 1;
    weight.maximumValue = 512;
    weight.delegate = self;
    
    self.intensity = [WDProperty property];
    intensity.title = NSLocalizedString(@"Intensity", @"Intensity");
    intensity.delegate = self;
    
    self.angle = [WDProperty property];
    angle.title = NSLocalizedString(@"Angle", @"Angle");
    angle.maximumValue = 360;
    angle.conversionFactor = 1;
    angle.delegate = self;
    
    self.spacing = [WDProperty property];
    spacing.title = NSLocalizedString(@"Spacing", @"Spacing");
    spacing.minimumValue = 0.004f;
    spacing.maximumValue = 2.0f;
    spacing.percentage = YES;
    spacing.delegate = self;
    
    self.rotationalScatter = [WDProperty property];
    rotationalScatter.title = NSLocalizedString(@"Jitter", @"Jitter");
    rotationalScatter.delegate = self;
    
    self.positionalScatter = [WDProperty property];
    positionalScatter.title = NSLocalizedString(@"Scatter", @"Scatter");
    positionalScatter.delegate = self;
    
    self.angleDynamics = [WDProperty property];
    angleDynamics.title = NSLocalizedString(@"Dynamic Angle", @"Dynamic Angle");
    angleDynamics.minimumValue = -1.0f;
    angleDynamics.delegate = self;
    
    self.weightDynamics = [WDProperty property];
    weightDynamics.title = NSLocalizedString(@"Dynamic Weight", @"Dynamic Weight");
    weightDynamics.minimumValue = -1.0f;
    weightDynamics.delegate = self;
    
    self.intensityDynamics = [WDProperty property];
    intensityDynamics.title = NSLocalizedString(@"Dynamic Intensity", @"Dynamic Intensity");
    intensityDynamics.minimumValue = -1.0f;
    intensityDynamics.delegate = self;
}

- (id) initWithGenerator:(WDStampGenerator *)shapeGenerator
{
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.generator = shapeGenerator;
    generator.delegate = self;
    [self buildProperties];
    
    return self;
}


- (void) propertyChanged:(WDProperty *)property
{
    if (suppressNotifications == 0) {
        self.uuid = nil;
        self.strokePreview = nil;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:WDBrushPropertyChanged
                                                            object:self
                                                          userInfo:@{@"property": property}];
    } else {
        [changedProperties addObject:property];
    }
}

- (void) generatorChanged:(WDStampGenerator *)aGenerator
{
    self.uuid = nil;
    self.strokePreview = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDBrushGeneratorChanged
                                                        object:self
                                                      userInfo:@{@"generator": aGenerator}];
}

- (void) setGenerator:(WDStampGenerator *)aGenerator
{
    generator = aGenerator;
    
    generator.delegate = self;
    
    self.uuid = nil;
    self.strokePreview = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WDBrushGeneratorReplaced
                                                        object:self
                                                      userInfo:@{@"generator": aGenerator}];
}

- (float) radius
{
    return self.weight.value / 2;
}

- (NSUInteger) numberOfPropertyGroups
{
    return [generator properties] ? 3 : 2;
}
             
- (NSArray *) allProperties
{
    return @[weight, intensity, angle, spacing, rotationalScatter, positionalScatter,
         angleDynamics, weightDynamics, intensityDynamics];
}

- (NSArray *) propertiesForGroupAtIndex:(NSUInteger)ix
{
    if ([generator properties] == nil) {
        ix++;
    }
    
    if (ix == 0) {
        // shape group
        return [generator properties];
    } else if (ix == 1) {
        // spacing group
        return @[intensity, angle, spacing, rotationalScatter, positionalScatter];
    } else if (ix == 2) {
        // dynamic group
        return @[angleDynamics, weightDynamics, intensityDynamics];
    }
    
    return nil;
}

- (void) setStrokePreview:(UIImage *)aStrokePreview
{
    strokePreview = aStrokePreview;
}

- (UIImage *) previewImageWithSize:(CGSize)size
{
    if (strokePreview && CGSizeEqualToSize(size, strokePreview.size)) {
        return strokePreview;
    }

    WDBrushPreview *preview = [WDBrushPreview sharedInstance];

    preview.brush = self;
    self.strokePreview = [preview previewWithSize:size];
    
    return strokePreview;
}

#pragma mark -
#pragma mark WDCoding

- (NSString *) uuid
{
    if (!uuid_) {
        uuid_ = generateUUID();
    }
    return uuid_;
}

- (void) encodeWithWDCoder:(id<WDCoder>)coder deep:(BOOL)deep
{
    if (deep) {
        [coder encodeObject:self.generator forKey:WDGeneratorKey deep:deep];
    }
    [coder encodeString:self.uuid forKey:WDUUIDKey];
    [coder encodeFloat:self.weight.value forKey:WDWeightKey];
    [coder encodeFloat:self.intensity.value forKey:WDIntensityKey];
    [coder encodeFloat:self.angle.value forKey:WDAngleKey];
    [coder encodeFloat:self.spacing.value forKey:WDSpacingKey];
    [coder encodeFloat:self.rotationalScatter.value forKey:WDRotationalScatterKey];
    [coder encodeFloat:self.positionalScatter.value forKey:WDPositionalScatterKey];
    [coder encodeFloat:self.angleDynamics.value forKey:WDAngleDynamicsKey];
    [coder encodeFloat:self.weightDynamics.value forKey:WDWeightDynamicsKey];
    [coder encodeFloat:self.intensityDynamics.value forKey:WDIntensityDynamicsKey];
}

- (float) decodeValue:(NSString *)key fromDecoder:(id<WDDecoder>)decoder defaultTo:(float)deft
{
    float value = [decoder decodeFloatForKey:key defaultTo:NAN];
    if (isnan(value)) {
        // for legacy files
        WDProperty *old = [decoder decodeObjectForKey:([key isEqualToString:WDWeightKey] ? @"noise" : key)];
        return old ? old.value : deft;
    } else {
        return value;
    }
}

- (void) updateWithWDDecoder:(id<WDDecoder>)decoder deep:(BOOL)deep
{
    if (deep) {
        self.generator = [decoder decodeObjectForKey:WDGeneratorKey];
        self.generator.delegate = self;
        [self buildProperties];
    }
    self.weight.value = [self decodeValue:WDWeightKey fromDecoder:decoder defaultTo:self.weight.value];
    self.intensity.value = [self decodeValue:WDIntensityKey fromDecoder:decoder defaultTo:self.intensity.value];
    self.angle.value = [self decodeValue:WDAngleKey fromDecoder:decoder defaultTo:self.angle.value];
    self.spacing.value = [self decodeValue:WDSpacingKey fromDecoder:decoder defaultTo:self.spacing.value];
    self.rotationalScatter.value = [self decodeValue:WDRotationalScatterKey fromDecoder:decoder defaultTo:self.rotationalScatter.value];
    self.positionalScatter.value = [self decodeValue:WDPositionalScatterKey fromDecoder:decoder defaultTo:self.positionalScatter.value];
    self.angleDynamics.value = [self decodeValue:WDAngleDynamicsKey fromDecoder:decoder defaultTo:self.angleDynamics.value];
    self.weightDynamics.value = [self decodeValue:WDWeightDynamicsKey fromDecoder:decoder defaultTo:self.weightDynamics.value];
    self.intensityDynamics.value = [self decodeValue:WDIntensityDynamicsKey fromDecoder:decoder defaultTo:self.intensityDynamics.value];
    self.uuid = [decoder decodeStringForKey:WDUUIDKey];
}

@end
