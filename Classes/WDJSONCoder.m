//
//  WDJSONCoder
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Original implementation by Scott Vachalek
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <objc/runtime.h>
#import "NSData+Base64.h"
#import "WDCoding.h"
#import "WDCodingProgress.h"
#import "WDDataProvider.h"
#import "WDDictionaryDecoder.h"
#import "WDJSONCoder.h"
#import "WDTypedData.h"
#import "WDUtilities.h"

#define TYPE "type"
#define T_COLOR "color"
#define T_COUNTED_SET "NSCountedSet"
#define T_DATA  "data"
#define T_POINT "point"
#define T_RECT "rect"
#define T_SIZE "size"
#define T_TRANSFORM "transform"

@implementation WDJSONCoder {
    NSMutableDictionary *binary_;
    NSMutableString *json_;
    WDCodingProgress *progress_;
    dispatch_group_t dispatchGroup_;
    dispatch_queue_t dispatchQueue_;
    NSMutableSet *refs_;
}

- (id) init
{
    return [self initWithProgress:nil];
}

- (id) initWithProgress:(WDCodingProgress *)progress
{
    self = [super init];
    if (!self) {
        return nil;
    }

    json_ = [[NSMutableString alloc] init];
    refs_ = [[NSMutableSet alloc] init];
    binary_ = [[NSMutableDictionary alloc] init];
    progress_ = progress;

    return self;
}

- (WDCodingProgress *) progress
{
    return progress_;
}

- (void) dispatch:(dispatch_block_t)task
{
    if (!dispatchQueue_) {
        dispatchQueue_ = dispatch_queue_create("com.taptrix.queue.WDDictionaryDecoder", NULL);
        dispatchGroup_ = dispatch_group_create();
    }
    dispatch_group_async(dispatchGroup_, dispatchQueue_, task);
}

- (void) waitForQueue
{
    if (dispatchGroup_) {
        dispatch_group_wait(dispatchGroup_, DISPATCH_TIME_FOREVER);
    }
}

- (NSDictionary *) dataWithRootNamed:(NSString *)name
{
    NSDictionary *copy = [binary_ mutableCopy];
    [copy setValue:[WDTypedData data:[self jsonData] mediaType:@"application/json"] forKey:name];
    return copy;
}

- (NSDictionary *) binaryData 
{
    [self waitForQueue];
    return binary_;
}

- (NSData *) jsonData 
{
    [self waitForQueue];
    return [json_ dataUsingEncoding:NSUTF8StringEncoding];
}

- (void) encodeKey:(NSString *)key 
{
    if (key) {
        if ([json_ hasSuffix:@"{"]) {
            [json_ appendString:@"\""];
        } else {
            [json_ appendString:@",\""];
        }
        [json_ appendString:key];
        [json_ appendString:@"\":"];
    }
}

- (void) encodeObject:(id<WDCoding>)object forKey:(NSString *)key deep:(BOOL)deep 
{
    [self encodeKey:key];
    if (object) {
#if WD_DEBUG
        if ([refs_ containsObject:object]) {
            [NSException raise:@"Circular reference" format:@"Object was found in a circular reference: %@", object];
        }
        [refs_ addObject:object];
#endif
        [json_ appendString:@"{\"" TYPE "\":\""];
        [json_ appendString:@(class_getName([object class]))];
        [json_ appendString:@"\""];
        [object encodeWithWDCoder:self deep:deep];
        [json_ appendString:@"}"];
#if WD_DEBUG
        [refs_ removeObject:object];
#endif
    } else {
        [json_ appendString:@"null"];
    }
}

- (void) encodeArray:(NSArray *)array forKey:(NSString *)key 
{
    [self encodeKey:key];
    if (array) {
        progress_.total += [array count];
        [json_ appendString:@"["];
        BOOL first = YES;
        for (id obj in array) {
            if (first) {
                first = NO;
            } else {
                [json_ appendString:@","];
            }
            [self encodeUnknown:obj forKey:nil];
            progress_.completed++;
        }
        [json_ appendString:@"]"];
    } else {
        [json_ appendString:@"null"];
    }
}

- (void) encodeCountedSet:(NSCountedSet *)set forKey:(NSString *)key
{
    [self encodeKey:key];
    if (set) {
        [json_ appendString:@"{"];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:(set.count * 2)];
        [set enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            [array addObject:obj];
            [array addObject:@([set countForObject:obj])];
        }];
        [self encodeString:@T_COUNTED_SET forKey:@TYPE];
        [self encodeArray:array forKey:@"objects"];
        [json_ appendString:@"}"];
    } else {
        [json_ appendString:@"null"];
    }
}

- (void) encodeDictionary:(NSDictionary *)dictionary forKey:(NSString *)key 
{
    [self encodeKey:key];
    if (dictionary) {
        progress_.total += [dictionary count];
        [json_ appendString:@"{"];
        [dictionary enumerateKeysAndObjectsUsingBlock:^void(id subkey, id obj, BOOL *stop) {
    #if WD_DEBUG
            if ([subkey isEqualToString:@TYPE]) {
                [NSException raise:@"Reserved Key" format:@"Key is reserved: %@", key];
            }
            if (![subkey isKindOfClass:[NSString class]]) {
                [NSException raise:@"Non-string Key" format:@"Dictionary key is not a string: %@", key];
            }
    #endif
            [self encodeUnknown:obj forKey:subkey];
            progress_.completed++;
        }];
        [json_ appendString:@"}"];
    } else {
        [json_ appendString:@"null"];
    }
}

- (void) encodeString:(NSString *)string forKey:(NSString *)key 
{
    [self encodeKey:key];
    if (string) {
        [json_ appendString:@"\""];
        [json_ appendString:string];
        [json_ appendString:@"\""];
    } else {
        [json_ appendString:@"null"];
    }
}

- (NSString *) uniqueFilenameWithPrefix:(NSString *)prefix extension:(NSString *)extension
{
    NSString *candidate = [NSString stringWithFormat:@"%@%@", prefix, extension];
    NSString *filename = nil;
    if (![binary_ valueForKey:candidate]) {
        filename = candidate;
    }
    int counter = 2;
    while (!filename) {
        candidate = [NSString stringWithFormat:@"%@%d%@", prefix, counter, extension];
        if (![binary_ valueForKey:candidate]) {
            filename = candidate;
        } else {
            ++counter;
        }
    }
    return filename;
}

- (void) encodeData:(NSData *)data forKey:(NSString *)key mediaType:(NSString *)mediaType 
{
    [self encodeKey:key];
    if ([data length] > 256) {
        NSString *extension = [WDJSONCoder extensionForType:mediaType];
        NSString *filename = [self uniqueFilenameWithPrefix:key extension:extension];
        [binary_ setValue:[WDTypedData data:data mediaType:mediaType] forKey:filename];
        [json_ appendString:@"{"];
        [self encodeString:@T_DATA forKey:@TYPE];
        [self encodeString:@"binary" forKey:@"encoding"];
        if (mediaType) {
            [self encodeString:mediaType forKey:@"content-type"];
        }
        [self encodeString:filename forKey:@"src"];
        [json_ appendString:@"}"];
    } else if (data) {
        NSString *encoded = [data base64EncodedString];
        NSArray *lines = [encoded componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [json_ appendString:@"{"];
        [self encodeString:@T_DATA forKey:@TYPE];
        [self encodeString:@"base64" forKey:@"encoding"];
        if (mediaType) {
            [self encodeString:mediaType forKey:@"content-type"];
        }
        [self encodeArray:lines forKey:@"data"];
        [json_ appendString:@"}"];
    } else {
        [json_ appendString:@"null"];
    }
}

- (void) encodeDataProvider:(id<WDDataProvider>)data forKey:(NSString *)key
{
    [self encodeKey:key];
    if (data) {
        NSString *mediaType = [data mediaType];
        NSString *extension = [WDJSONCoder extensionForType:mediaType];
        NSString *filename;
        if (data.uuid) {
            filename = [data.uuid stringByAppendingString:extension];
        } else {
            filename = [self uniqueFilenameWithPrefix:key extension:extension];
        }
        [binary_ setValue:data forKey:filename];
        [json_ appendString:@"{"];
        [self encodeString:@T_DATA forKey:@TYPE];
        [self encodeString:@"binary" forKey:@"encoding"];
        if (mediaType) {
            [self encodeString:mediaType forKey:@"content-type"];
        }
        [self encodeString:filename forKey:@"src"];
        [json_ appendString:@"}"];
    } else {
        [json_ appendString:@"null"];
    }
}

- (void) encodeBoolean:(BOOL)boolean forKey:(NSString *)key 
{
    [self encodeKey:key];
    [json_ appendString:(boolean ? @"true" : @"false")];
}

- (void) encodeInteger:(int)number forKey:(NSString *)key 
{
    [self encodeKey:key];
    [json_ appendFormat:@"%d", number];
}

- (void) encodeFloat:(float)number forKey:(NSString *)key 
{
    [self encodeKey:key];
    [json_ appendFormat:@"%g", number];
}

- (void) encodeColor:(UIColor *)color forKey:(NSString *)key 
{
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    [self encodeKey:key];
    [json_ appendString:@"{\"" TYPE "\":\"" T_COLOR "\""];
    if (red > 0.f) {
        [json_ appendString:@",\"r\":"];
        [json_ appendFormat:@"%g", red];
    }
    if (green > 0.f) {
        [json_ appendString:@",\"g\":"];
        [json_ appendFormat:@"%g", green];
    }
    if (blue > 0.f) {
        [json_ appendString:@",\"b\":"];
        [json_ appendFormat:@"%g", blue];
    }
    if (alpha < 1.f) {
        [json_ appendString:@",\"a\":"];
        [json_ appendFormat:@"%g", alpha];
    }
    [json_ appendString:@"}"];
}

- (void) encodeSize:(CGSize)size forKey:(NSString *)key 
{
    [self encodeKey:key];
    [json_ appendString:@"{\"" TYPE "\":\"" T_SIZE "\",\"w\":"];
    [json_ appendFormat:@"%g", size.width];
    [json_ appendString:@",\"h\":"];
    [json_ appendFormat:@"%g", size.height];
    [json_ appendString:@"}"];
}

- (void) encodePoint:(CGPoint)point forKey:(NSString *)key 
{
    [self encodeKey:key];
    [json_ appendString:@"{\"" TYPE "\":\"" T_POINT "\",\"x\":"];
    [json_ appendFormat:@"%g", point.x];
    [json_ appendString:@",\"y\":"];
    [json_ appendFormat:@"%g", point.y];
    [json_ appendString:@"}"];
}

- (void) encodeRect:(CGRect)rect forKey:(NSString *)key 
{
    [self encodeKey:key];
    [json_ appendString:@"{\"" TYPE "\":\"" T_RECT "\",\"x\":"];
    [json_ appendFormat:@"%g", rect.origin.x];
    [json_ appendString:@",\"y\":"];
    [json_ appendFormat:@"%g", rect.origin.y];
    [json_ appendString:@",\"w\":"];
    [json_ appendFormat:@"%g", rect.size.width];
    [json_ appendString:@",\"h\":"];
    [json_ appendFormat:@"%g", rect.size.height];
    [json_ appendString:@"}"];
}

- (void)encodeTransform:(CGAffineTransform)transform forKey:(NSString *)key
{
    [self encodeKey:key];
    [json_ appendString:@"{\"" TYPE "\":\"" T_TRANSFORM "\",\"a\":"];
    [json_ appendFormat:@"%g", transform.a];
    [json_ appendString:@",\"b\":"];
    [json_ appendFormat:@"%g", transform.b];
    [json_ appendString:@",\"c\":"];
    [json_ appendFormat:@"%g", transform.c];
    [json_ appendString:@",\"d\":"];
    [json_ appendFormat:@"%g", transform.d];
    [json_ appendString:@",\"tx\":"];
    [json_ appendFormat:@"%g", transform.tx];
    [json_ appendString:@",\"ty\":"];
    [json_ appendFormat:@"%g", transform.ty];
    [json_ appendString:@"}"];
}

- (void) encodeUnknown:(id)object forKey:(NSString *)key {
    if ([object isKindOfClass:[NSString class]]) {
        [self encodeString:object forKey:key];
    } else if ([object isKindOfClass:[NSArray class]]) {
        [self encodeArray:object forKey:key];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        [self encodeDictionary:object forKey:key];
    } else if ([object conformsToProtocol:@protocol(WDCoding)]) {
        [self encodeObject:object forKey:key deep:YES];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        NSNumber *number = object;
        if ([number isEqual:@YES]) {
            [self encodeBoolean:YES forKey:key];
        } else if ([number isEqual:@NO]) {
            [self encodeBoolean:NO forKey:key];
        } else if (CFNumberIsFloatType((__bridge CFNumberRef)(number))) {
            [self encodeFloat:[number floatValue] forKey:key];
        } else {
            [self encodeInteger:[number intValue] forKey:key];
        }
    } else if ([object isKindOfClass:[NSData class]]) {
        [self encodeData:object forKey:key mediaType:nil];
    } else if ([object conformsToProtocol:@protocol(WDDataProvider)]) {
        [self encodeDataProvider:object forKey:key];
    } else {
        // unknown type
#if WD_DEBUG
        [NSException raise:@"Unknown Type" format:@"Don't know how to convert to JSON: %@=%@", key, object];
#endif
    }
}

- (NSString *) description 
{
    return [NSString stringWithFormat:@"%@: %@", [super description], json_];
}

- (id) reconstructDictionary:(NSDictionary *)dict binary:(NSDictionary *)binary 
{
    progress_.total += dict.count;
    __block NSString *type = nil;
    NSMutableDictionary *converted = [NSMutableDictionary dictionaryWithCapacity:dict.count];
    [dict enumerateKeysAndObjectsUsingBlock:^void(id key, id obj, BOOL *stop) {
        if ([key isEqual:@TYPE]) {
            type = obj;
        } else {
            // convert recursively
            id reconstructed = [self reconstruct:obj binary:binary];
            if (reconstructed) {
                converted[key] = reconstructed;
            } else {
                WDLog(@"ERROR: nil in reconstructed dictionary, key %@", key);
            }
        }
        ++progress_.completed;
    }];
    if (!type) {
        // treat as an NSDictionary
        return converted;
    }
    switch ([type characterAtIndex:0]) {
        case 'c':
            if ([type isEqualToString:@T_COLOR]) {
                CGFloat red   = [converted[@"r"] floatValue];
                CGFloat green = [converted[@"g"] floatValue];
                CGFloat blue  = [converted[@"b"] floatValue];
                id a = dict[@"a"];
                CGFloat alpha = a ? [a floatValue] : 1.f;
                return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            }
            break;
        case 'd':
            if ([type isEqualToString:@T_DATA]) {
                NSArray *data = converted[@"data"];
                if (data) {
                    return [NSData dataFromBase64String:[data componentsJoinedByString:@"\n"]];
                } else {
                    NSString *src = converted[@"src"];
                    NSData *value = binary[src];
                    NSString *type = converted[@"content-type"];
                    if ([value conformsToProtocol:@protocol(WDDataProvider)]) {
                        return value;
                    } else if ([value isKindOfClass:[NSData class]]) {
                        return [WDTypedData data:value mediaType:type];
                    } else if (value) {
                        WDLog(@"ERROR: Binary data of unknown type! src: %@ type: %@", src, [value class]);
                        return [WDTypedData data:[NSData data] mediaType:type];
                    } else {
                        WDLog(@"ERROR: Missing binary data! src: %@", src);
                        return [WDTypedData data:[NSData data] mediaType:type];
                    }
                }
            }
            break;
        case 'N':
            if ([type isEqualToString:@T_COUNTED_SET]) {
                NSArray *array = [self reconstructArray:converted[@"objects"] binary:binary];
                NSCountedSet *set = [NSCountedSet set];
                for (int i = 0; i < array.count; i += 2) {
                    id obj = array[i];
                    int count = [array[(i + 1)] intValue];
                    // TODO there's got to be a better way than this loop
                    for (int i = 0; i < count; ++i) {
                        [set addObject:obj];
                    }
                }
                return set;
            }
            break;
        case 'p':
            if ([type isEqualToString:@T_POINT]) {
                CGFloat x = [converted[@"x"] floatValue]; 
                CGFloat y = [converted[@"y"] floatValue];
                return [NSValue valueWithCGPoint:CGPointMake(x, y)];
            }
            break;
        case 'r':
            if ([type isEqualToString:@T_RECT]) {
                CGFloat x = [converted[@"x"] floatValue]; 
                CGFloat y = [converted[@"y"] floatValue];
                CGFloat width = [converted[@"w"] floatValue];
                CGFloat height = [converted[@"h"] floatValue];
                return [NSValue valueWithCGRect:CGRectMake(x, y, width, height)];
            }
            break;
        case 's':
            if ([type isEqualToString:@T_SIZE]) {
                CGFloat width = [converted[@"w"] floatValue];
                CGFloat height = [converted[@"h"] floatValue];
                return [NSValue valueWithCGSize:CGSizeMake(width, height)];
            }
            break;
        case 't':
            if ([type isEqualToString:@T_TRANSFORM]) {
                CGFloat a = [converted[@"a"] floatValue];
                CGFloat b = [converted[@"b"] floatValue];
                CGFloat c = [converted[@"c"] floatValue];
                CGFloat d = [converted[@"d"] floatValue];
                CGFloat tx = [converted[@"tx"] floatValue];
                CGFloat ty = [converted[@"ty"] floatValue];
                return [NSValue valueWithCGAffineTransform:CGAffineTransformMake(a, b, c, d, tx, ty)];
            }
            break;
    }
    Class class = NSClassFromString(type);
    if ([class conformsToProtocol:@protocol(WDCoding)]) {
        id<WDCoding> obj = [[class alloc] init];
        WDDictionaryDecoder *decoder = [[WDDictionaryDecoder alloc] initWithDictionary:converted progress:progress_];
        [obj updateWithWDDecoder:decoder deep:YES];
        [decoder waitForQueue];
        return obj;
    } else {
        [NSException raise:@"Unknown Class" format:@"Type is not supported: %@", type];
        return nil;
    }
}

- (id) reconstructArray:(NSArray *)array binary:(NSDictionary *)binary {
    // convert recursively
    progress_.total += array.count;
    NSMutableArray *converted = [NSMutableArray arrayWithCapacity:[array count]];
    for (id obj in array) {
        id reconstructed = [self reconstruct:obj binary:binary];
        if (reconstructed) {
            [converted addObject:reconstructed];
        } else {
            WDLog(@"ERROR: nil in reconstructed array");
        }
        ++progress_.completed;
    }
    return converted;
}

- (id) reconstruct:(id)obj binary:(NSDictionary *)binary {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self reconstructDictionary:obj binary:binary];
    } else if ([obj isKindOfClass:[NSArray class]]) {
        return [self reconstructArray:obj binary:binary];
    } else {
        return obj;
    }
}

+ (NSData *) dataFrom:(id)obj
{
    if ([obj isKindOfClass:[NSData class]]) {
        return obj;
    } else if ([obj conformsToProtocol:@protocol(WDDataProvider)]) {
        return [obj data];
    } else {
        WDLog(@"Unknown type where NSData expected: %@", obj);
        return nil;
    }
}

- (id) decodeRoot:(NSString *)name from:(NSDictionary *)source
{
    NSError *err;
    NSData *jsonSource = [WDJSONCoder dataFrom:[source valueForKey:name]];
    id json = [NSJSONSerialization JSONObjectWithData:jsonSource options:0 error:&err];
    if (!json) {
        [NSException raise:@"Error in JSON data" format:@"%@", [err description]];
    }
    return [self reconstruct:json binary:source];
}

- (id<WDCoding>) copy:(id <WDCoding>)source deep:(BOOL)deep 
{
    WDJSONCoder *coder = [[WDJSONCoder alloc] init];
    [coder encodeObject:source forKey:nil deep:deep];
    NSString *root = @"root.json";
    NSDictionary *data = [coder dataWithRootNamed:root];
    id<WDCoding> copy = [coder decodeRoot:root from:data];
    return copy;
}

- (void) update:(id <WDCoding>)dest with:(id <WDCoding>)source 
{
    WDJSONCoder *coder = [[WDJSONCoder alloc] init];
    [coder encodeObject:source forKey:nil deep:NO];
    NSError *err;
    NSData *jsonSource = [WDJSONCoder dataFrom:coder.jsonData];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonSource options:0 error:&err];
    if (!dict) {
        [NSException raise:@"Error in JSON data" format:@"%@", [err description]];
    }
    NSMutableDictionary *converted = [NSMutableDictionary dictionaryWithCapacity:[dict count]];
    [dict enumerateKeysAndObjectsUsingBlock:^void(id key, id obj, BOOL *stop) {
        if (![key isEqual:@TYPE]) {
            // convert recursively
            converted[key] = [self reconstruct:obj binary:nil];
        }
    }];
    WDDictionaryDecoder *decoder = [[WDDictionaryDecoder alloc] initWithDictionary:converted progress:progress_];
    [dest updateWithWDDecoder:decoder deep:NO];
    [decoder waitForQueue];
}

+ (NSString *) extensionForType:(NSString *)type
{
    if ([type isEqualToString:@"image/jpeg"]) {
        return @".jpg";
    } else if ([type isEqualToString:@"image/png"]) {
        return @".png";
    } else if ([type isEqualToString:@"image/svg"]) {
        return @".svg";
    } else if ([type isEqualToString:@"application/json"]) {
        return @".json";
    } else {
        return @"";
    }
}

+ (NSString *) typeForExtension:(NSString *)filename
{
    if ([filename hasSuffix:@".jpg"]) {
        return @"image/jpeg";
    } else if ([filename hasSuffix:@".png"]) {
        return @"image/png";
    } else if ([filename hasSuffix:@".svg"]) {
        return @"image/svg";
    } else if ([filename hasSuffix:@".json"]) {
        return @"application/json";
    } else {
        return nil;
    }
}

@end
