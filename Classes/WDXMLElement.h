//
//  WDXMLElement.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2011-2013 Steve Sprang
//

#import <Foundation/Foundation.h>


@interface WDXMLElement : NSObject {
    NSString                *name_;
    NSMutableArray          *children_;
    NSMutableDictionary     *attributes_;
    NSString                *value_;
}

@property (nonatomic) NSString *name;
@property (nonatomic) NSMutableArray *children;
@property (nonatomic) NSMutableDictionary *attributes;
@property (nonatomic) NSString *value;
@property (weak, nonatomic, readonly) NSString *XMLValue;

+ (WDXMLElement *) elementWithName:(NSString *)name;
- (id) initWithName:(NSString *)name;

- (void) setAttribute:(NSString *)attribute value:(NSString *)value;
- (void) setAttribute:(NSString *)attribute floatValue:(float)value;

- (void) addChild:(WDXMLElement *)element;
- (void) removeAllChildren;

@end
