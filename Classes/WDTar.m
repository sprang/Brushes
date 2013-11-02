//
//  WDTar
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

#import "WDTar.h"
#import "WDUtilities.h"


@implementation WDTar {

}

- (void) prepareHeader:(uint8_t *)header filename:(NSString *)filename size:(NSUInteger)size time:(NSUInteger)time
{
    memset(header, 0, 512);
    [filename getCString:(char *) header maxLength:100 encoding:NSASCIIStringEncoding];
    sprintf((char *)(header + 100), "%o", 0644); // permissions
    sprintf((char *)(header + 108), "%o", 0);    // user id
    sprintf((char *)(header + 116), "%o", 0);    // group id
    sprintf((char *)(header + 124), "%lo", (unsigned long)size);
    sprintf((char *)(header + 136), "%lo", (unsigned long)time);
    int checksum = 8 * 32;
    for (int i = 0; i < 512; ++i) {
        checksum += header[i];
    }
    sprintf((char *)(header + 148), "%06o%c ", checksum, 0);
}

- (void) writeFile:(NSData *)file toStream:(NSOutputStream *)stream name:(NSString *)name time:(NSUInteger)time
{
    NSUInteger size = [file length];
    uint8_t header[512];
    [self prepareHeader:header filename:name size:size time:time];
    NSInteger count = [stream write:header maxLength:512];
    assert(count == 512);
    count = [stream write:[file bytes] maxLength:size];
    assert(count == size);
    if (size % 512) {
        memset(header, 0, 512);
        [stream write:header maxLength:(512 - size % 512)];
    }
}

- (void) writeTarToStream:(NSOutputStream *)stream withFiles:(NSDictionary *)files baseURL:(NSURL *)baseURL order:(NSArray *)list
{
    __block NSUInteger time = (NSUInteger) [[NSDate date] timeIntervalSince1970];
    [list enumerateObjectsUsingBlock:^void(id filename, NSUInteger idx, BOOL *stop) {
        id data = [[files valueForKey:filename] data];
        if (!data || (data == [NSNull null])) {
            data = [[NSFileManager defaultManager] contentsAtPath:[[baseURL URLByAppendingPathComponent:filename] path]];
        }
        if (data) {
            [self writeFile:data toStream:stream name:filename time:time];
        }
    }];
    [files enumerateKeysAndObjectsUsingBlock:^void(id filename, id datap, BOOL *stop) {
        if (![list containsObject:filename]) {
            id data = [datap data];
            if (!data || (data == [NSNull null])) {
                data = [[NSFileManager defaultManager] contentsAtPath:[[baseURL URLByAppendingPathComponent:filename] path]];
            }
            if (data) {
                [self writeFile:data toStream:stream name:filename time:time];
            }
        }
    }];
    // two empty records marks end of file
    uint8_t end[1024];
    memset(end, 0, 1024);
    [stream write:end maxLength:1024];
}

- (void) writeTarToFile:(NSURL *)url withFiles:(NSDictionary *)files baseURL:(NSURL *)baseURL order:(NSArray *)list
{
    NSOutputStream *stream = [NSOutputStream outputStreamWithURL:url append:NO];
    [stream open];
    [self writeTarToStream:stream withFiles:files baseURL:baseURL order:list];
    [stream close];
}

- (BOOL) readEntryFrom:(NSInputStream *)stream into:(NSMutableDictionary *)dict error:(NSError **)outError
{
    uint8_t header[512];
    [stream read:header maxLength:512];
    char filename[100];
    filename[0] = 0;
    sscanf((char *)header, "%100s", filename);
    unsigned long size = 0;
    sscanf((char *)(header + 124), "%lo", &size);
    if (filename[0] != 0) {
        int checksum = 8 * 32;
        for (int i = 0; i < 512; ++i) {
            if (i < 148 || i >= 156) {
                checksum += header[i];
            }
        }
        int expectedChecksum = 0;
        sscanf((char *)(header + 148), "%06o", &expectedChecksum);
        if (checksum != expectedChecksum) {
            if (outError) {
                *outError = [NSError errorWithDomain:@"WDTar" code:1 userInfo:@{@"message": @""}];
            }
            return NO;
        }
        uint8_t *buf = calloc(size, 1);
        [stream read:buf maxLength:size];
        NSData *data = [[NSData alloc] initWithBytes:buf length:size];
        free(buf);
        NSString *sfilename = @(filename);
        [dict setValue:data forKey:sfilename];
        if (size % 512) {
            [stream read:header maxLength:(512 - size % 512)];
        }
    }
    return YES;
}

- (NSDictionary *) readTar:(NSURL *)url error:(NSError **)outError
{
    NSError *error = nil;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSInputStream *stream = [NSInputStream inputStreamWithURL:url];
    if (!stream) {
        return nil;
    }
    [stream open];
    while ([stream hasBytesAvailable]) {
        if (![self readEntryFrom:stream into:dict error:outError]) {
            [stream close];
            return nil;
        }
    }
    if ([stream streamStatus] != NSStreamStatusAtEnd) {
        error = [stream streamError];
        WDLog(@"ERROR reading tar: %@", error);
    }
    [stream close];
    if (outError) {
        *outError = error;
    }
    return error ? nil : dict;
}

- (NSData *) readEntry:(NSString *)name fromTar:(NSURL *)url
{
    // could be more efficient but realistically, this isn't expected to be called anymore
    NSError *error = nil;
    NSDictionary *dict = [self readTar:url error:&error];
    if (error) {
        WDLog(@"ERROR: reading tar %@: %@", url, error);
    }
    return dict[name];
}

@end
