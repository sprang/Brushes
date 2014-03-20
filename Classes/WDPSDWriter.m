//
//  WDPSDWriter
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

#import <Accelerate/Accelerate.h>
#import "WDPSDWriter.h"
#import "WDPainting.h"
#import "WDLayer.h"

#define CHANNELS 4 /* R, G, B, A */
#define DEPTH 8 /* 8-bit channels */
#define COLOR_MODE 3 /* RGB */

typedef uint8_t const * bytes;

@implementation WDPSDWriter {
    WDPainting* painting_;
}

- (id) initWithPainting:(WDPainting *)painting
{
    self = [super init];
    if (!self) {
        return nil;
    }

    painting_ = painting;

    return self;
}


- (void) writeFileHeader:(NSOutputStream *)out
{
    [out write:(bytes) "8BPS" maxLength:4];

    uint16_t version = CFSwapInt16HostToBig(1);
    [out write:(bytes) &version maxLength:2];

    [out write:(bytes) "\0\0\0\0\0\0" maxLength:6];

    uint16_t channels = CFSwapInt16HostToBig(CHANNELS);
    [out write:(bytes) &channels maxLength:2];

    uint32_t height = CFSwapInt32HostToBig((uint32_t) [painting_ height]);
    [out write:(bytes) &height maxLength:4];

    uint32_t width = CFSwapInt32HostToBig((uint32_t) [painting_ width]);
    [out write:(bytes) &width maxLength:4];

    uint16_t depth = CFSwapInt16HostToBig(DEPTH);
    [out write:(bytes) &depth maxLength:2];

    uint16_t colorMode = CFSwapInt16HostToBig(COLOR_MODE);
    [out write:(bytes) &colorMode maxLength:2];
}

- (void) writeColorModeData:(NSOutputStream *)out
{
    uint32_t size = CFSwapInt32HostToBig(0);
    [out write:(bytes) &size maxLength:4];
}

- (void) writeImageResources:(NSOutputStream *)out
{
    uint32_t size = CFSwapInt32HostToBig(0);
    [out write:(bytes) &size maxLength:4];
    // TODO: thumbnail
}

- (void) writeLayerRecord:(WDLayer *)layer to:(NSOutputStream *)out channelSizes:(uint32_t[])channelSizes
{
    uint32_t top = CFSwapInt32HostToBig(0);
    [out write:(bytes) &top maxLength:4];

    uint32_t left = CFSwapInt32HostToBig(0);
    [out write:(bytes) &left maxLength:4];

    uint32_t bottom = CFSwapInt32HostToBig((uint32_t) painting_.height);
    [out write:(bytes) &bottom maxLength:4];

    uint32_t right = CFSwapInt32HostToBig((uint32_t) painting_.width);
    [out write:(bytes) &right maxLength:4];

    uint16_t channels = CFSwapInt16HostToBig(CHANNELS);
    [out write:(bytes) &channels maxLength:2];

    uint16_t redChannel = CFSwapInt16HostToBig(0);
    uint32_t redChannelSize = CFSwapInt32HostToBig(channelSizes[0]);
    [out write:(bytes) &redChannel maxLength:2];
    [out write:(bytes) &redChannelSize maxLength:4];

    uint16_t greenChannel = CFSwapInt16HostToBig(1);
    uint32_t greenChannelSize = CFSwapInt32HostToBig(channelSizes[1]);
    [out write:(bytes) &greenChannel maxLength:2];
    [out write:(bytes) &greenChannelSize maxLength:4];

    uint16_t blueChannel = CFSwapInt16HostToBig(2);
    uint32_t blueChannelSize = CFSwapInt32HostToBig(channelSizes[2]);
    [out write:(bytes) &blueChannel maxLength:2];
    [out write:(bytes) &blueChannelSize maxLength:4];

    uint16_t alphaChannel = CFSwapInt16HostToBig(0xffff);
    uint32_t alphaChannelSize = CFSwapInt32HostToBig(channelSizes[3]);
    [out write:(bytes) &alphaChannel maxLength:2];
    [out write:(bytes) &alphaChannelSize maxLength:4];

    [out write:(bytes) "8BIM" maxLength:4];
    switch ([layer blendMode]) {
            case WDBlendModeNormal:
                [out write:(bytes) "norm" maxLength:4];
                break;
            case WDBlendModeMultiply:
                [out write:(bytes) "mul " maxLength:4];
                break;
            case WDBlendModeScreen:
                [out write:(bytes) "scrn" maxLength:4];
                break;
            case WDBlendModeExclusion:
                [out write:(bytes) "smud" maxLength:4];
                break;
            default:
                [out write:(bytes) "????" maxLength:4];
        }

    uint8_t opacity = (uint8_t) (layer.opacity * 255);
    [out write:&opacity maxLength:1];

    uint8_t clipping = 0; // "base"
    [out write:&clipping maxLength:1];

    uint8_t flags = (layer.alphaLocked ? 1 : 0) | (layer.visible ? 0 : 2);
    [out write:&flags maxLength:1];

    uint8_t filler = 0;
    [out write:&filler maxLength:1];

//    NSString *name = (layer.name.length <= 255) ? layer.name : [layer.name substringToIndex:255];
    NSString *name = @"Unnamed"; // if this plus the length byte is not a multiple of 4, it needs to be padded!
    uint8_t nameLength = (uint8_t) name.length;
    uint32_t blendingRanges = (CHANNELS + 1) * 2 * sizeof(uint32_t);
    uint32_t extraDataLength = (uint32_t) CFSwapInt32HostToBig((uint32_t) (4 + 4 + blendingRanges + 1 + nameLength));
    [out write:(bytes) &extraDataLength maxLength:4];

    uint32_t layerMask = CFSwapInt32HostToBig(0);
    [out write:(bytes) &layerMask maxLength:4];

    uint32_t blendingRangesDataLength = CFSwapInt32HostToBig(blendingRanges);
    [out write:(bytes) &blendingRangesDataLength maxLength:4];
    for (int i = 0; i < CHANNELS + 1; ++i) {
        uint32_t sourceRange = CFSwapInt32HostToBig(0x0000ffff);
        [out write:(bytes) &sourceRange maxLength:4];
        uint32_t destRange = CFSwapInt32HostToBig(0x0000ffff);
        [out write:(bytes) &destRange maxLength:4];
    }

    [out write:&nameLength maxLength:1];
    char const *cname = [name cStringUsingEncoding:NSUTF8StringEncoding];
    [out write:(bytes) cname maxLength:nameLength];
}

uint16_t rleCompress(uint8_t *dest, uint8_t *src, int length)
{
    uint8_t *start = dest;
    for (int i = 0; i < length;) {
        if ((i + 1 < length) && (src[i] == src[i + 1])) {
            int run = 1;
            while ((i + run + 1 < length)
                   && (run < 127)
                   && (src[i + run + 1] == src[i])) {
                ++run;
            }
            *dest++ = -run;
            *dest++ = src[i];
            i += (run + 1);
        } else {
            int count = 1;
            dest[count] = src[i];
            while ((i + count < length)
                   && (count < 127)
                   && ((i + count + 1 == length) || (src[i + count + 1] != src[i + count]))) {
                ++count;
                dest[count] = src[i + count - 1];
            }
            // we've either hit the end or a pair, thus one too far
            --count;
            *dest++ = count;
            dest += (count + 1);
            i += (count + 1);
        }
    }
    return dest - start;
}

- (uint32_t) writeChannel:(uint8_t *)data width:(vImagePixelCount)width height:(vImagePixelCount)height to:(NSOutputStream *)out channel:(BOOL)channel
{
    uint32_t size = 0;
    if (channel) {
        uint16_t compression = CFSwapInt16HostToBig(1);
        [out write:(bytes) &compression maxLength:2];
    }
    size += 2;
    uint8_t *buf = malloc(width * 2);
    for (int y = 0; y < height; ++y) {
        uint16_t len = rleCompress(buf, data + y * width, (int) width);
        if (channel) {
            len = len + (len % 2);
        }
        uint16_t nlen = CFSwapInt16HostToBig(len);
        [out write:(bytes) &nlen maxLength:2]; 
        size += 2;
    }
    for (int y = 0; y < height; ++y) {
        uint16_t len = rleCompress(buf, data + y * width, (int) width);
        [out write:buf maxLength:len];
        size += len;
        if (channel && (len % 2)) {
            const uint8_t zero = 0;
            [out write:&zero maxLength:1];
            ++size;
        }
    }
    free(buf);
    
    return size;
}

- (uint32_t *) writeChannelImageData:(GLubyte *)data to:(NSOutputStream *)out
{
    vImagePixelCount height = (vImagePixelCount) painting_.height;
    vImagePixelCount width = (vImagePixelCount) painting_.width;
    vImage_Buffer srcVib = { data, height, width, width * CHANNELS };
    const size_t area = height * width;
    uint8_t *aBytes = malloc(area);
    uint8_t *rBytes = malloc(area);
    uint8_t *gBytes = malloc(area);
    uint8_t *bBytes = malloc(area);
    vImage_Buffer aVib = { aBytes, height, width, width };
    vImage_Buffer rVib = { rBytes, height, width, width };
    vImage_Buffer gVib = { gBytes, height, width, width };
    vImage_Buffer bVib = { bBytes, height, width, width };
    vImageConvert_ARGB8888toPlanar8(&srcVib, &rVib, &gVib, &bVib, &aVib, kvImageDoNotTile);

    uint32_t *channelSizes = malloc(sizeof(uint32_t) * 4);
    channelSizes[0] = [self writeChannel:rBytes width:width height:height to:out channel:YES];
    channelSizes[1] = [self writeChannel:gBytes width:width height:height to:out channel:YES];
    channelSizes[2] = [self writeChannel:bBytes width:width height:height to:out channel:YES];
    channelSizes[3] = [self writeChannel:aBytes width:width height:height to:out channel:YES];

    free(aBytes);
    free(rBytes);
    free(gBytes);
    free(bBytes);
    
    return channelSizes;
}

- (void) writeImageData:(GLubyte *)data to:(NSOutputStream *)out
{
    vImagePixelCount height = (vImagePixelCount) painting_.height;
    vImagePixelCount width = (vImagePixelCount) painting_.width;
    vImage_Buffer srcVib = { data, height, width, width * CHANNELS };
    const size_t area = height * width;
    uint8_t *xbytes = malloc(area * CHANNELS);
    vImage_Buffer rVib = { xbytes + area * 0, height, width, width };
    vImage_Buffer gVib = { xbytes + area * 1, height, width, width };
    vImage_Buffer bVib = { xbytes + area * 2, height, width, width };
    vImage_Buffer aVib = { xbytes + area * 3, height, width, width };
    vImageConvert_ARGB8888toPlanar8(&srcVib, &rVib, &gVib, &bVib, &aVib, kvImageDoNotTile);

    uint16_t compression = CFSwapInt16HostToBig(1);
    [out write:(bytes) &compression maxLength:2];

    uint8_t *buf = malloc(width * 2);
    NSMutableData *mdata = [[NSMutableData alloc] init];
    [mdata increaseLengthBy:CHANNELS * height * 2];
    for (int channel = 0; channel < CHANNELS; ++channel) {
        for (int y = 0; y < height; ++y) {
            uint16_t len = rleCompress(buf, xbytes + (channel * area) + (y * width), (int) width);
            uint16_t nlen = CFSwapInt16BigToHost(len);
            [mdata replaceBytesInRange:NSMakeRange((channel * height + y) * 2, 2) withBytes:&nlen];
            [mdata appendBytes:buf length:len];
        }
    }
    [out write:[mdata bytes] maxLength:[mdata length]];
    free(buf);

    free(xbytes);
}

- (NSData *) layerInfo
{
    NSInteger layers = painting_.layers.count;
    uint32_t **channelSizes = malloc(sizeof(uint32_t*) * layers);
    NSMutableArray *imageDatas = [NSMutableArray array];
    for (int i = 0; i < layers; ++i) {
        WDLayer *layer = [painting_ layers][i];
        NSOutputStream *imageOut = [[NSOutputStream alloc] initToMemory];
        [imageOut open];
        channelSizes[i] = [self writeChannelImageData:layer.bytes to:imageOut];
        [imageOut close];
        [imageDatas addObject:[imageOut propertyForKey:NSStreamDataWrittenToMemoryStreamKey]];
    }
    
    NSOutputStream *layerOut = [NSOutputStream outputStreamToMemory];
    [layerOut open];
    uint16_t layerCount = CFSwapInt16HostToBig((uint16_t) layers);
    [layerOut write:(bytes) &layerCount maxLength:2];
    for (int i = 0; i < layers; ++i) {
        WDLayer *layer = [painting_ layers][i];
        [self writeLayerRecord:layer to:layerOut channelSizes:channelSizes[i]];
        free(channelSizes[i]);
    }
    
    for (NSData *imageData in imageDatas) {
        [layerOut write:imageData.bytes maxLength:imageData.length];
    }
    [layerOut close];
    free(channelSizes);

    return [layerOut propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}

- (NSData *) globalLayerMaskInfo
{
    NSOutputStream *out = [NSOutputStream outputStreamToMemory];
    [out open];

    uint16_t overlayColorSpace = CFSwapInt16HostToBig(0); // "undocumented" !?
    [out write:(bytes) &overlayColorSpace maxLength:2];

    uint16_t colorComponent = CFSwapInt16HostToBig(0); // purpose unknown
    [out write:(bytes) &colorComponent maxLength:2];
    [out write:(bytes) &colorComponent maxLength:2];
    [out write:(bytes) &colorComponent maxLength:2];
    [out write:(bytes) &colorComponent maxLength:2];

    uint16_t opacity = CFSwapInt16HostToBig(0); // transparent
    [out write:(bytes) &opacity maxLength:2];

    uint8_t kind = 128; // use value stored per layer
    [out write:&kind maxLength:1];

    uint8_t filler = 0;
    [out write:&filler maxLength:1]; // bring it up to 16
    [out write:&filler maxLength:1];
    [out write:&filler maxLength:1];

    [out close];

    return [out propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}

- (void) writeLayerAndMaskInfo:(NSOutputStream *)out
{
    NSData *layerInfo = [self layerInfo];
    NSData *globalLayerMaskInfo = [self globalLayerMaskInfo];

    uint32_t totalLength = CFSwapInt32HostToBig(4 + (uint32_t)layerInfo.length + 4 + (uint32_t)globalLayerMaskInfo.length);
    [out write:(bytes) &totalLength maxLength:4];

    uint32_t layerInfoLength = CFSwapInt32HostToBig((uint32_t)layerInfo.length);
    [out write:(bytes) &layerInfoLength maxLength:4];
    [out write:layerInfo.bytes maxLength:layerInfo.length];

    uint32_t globalLayerMaskInfoLength = CFSwapInt32HostToBig((uint32_t)globalLayerMaskInfo.length);
    [out write:(bytes) &globalLayerMaskInfoLength maxLength:4];
    if (globalLayerMaskInfoLength) {
        // writing 0 bytes seems to blow it all up
        [out write:globalLayerMaskInfo.bytes maxLength:globalLayerMaskInfo.length];
    }
}

- (void) writePSD:(NSOutputStream *)out
{
    [self writeFileHeader:out];
    [self writeColorModeData:out];
    [self writeImageResources:out];
    [self writeLayerAndMaskInfo:out];

    NSData *imageData = [painting_ imageDataWithSize:painting_.dimensions backgroundColor:[UIColor whiteColor]];
    
    // we need to unpremultiply the data
    vImagePixelCount height = (vImagePixelCount) painting_.height;
    vImagePixelCount width = (vImagePixelCount) painting_.width;
    vImage_Buffer data = {(void *) imageData.bytes, height, width, width * CHANNELS};
    vImageUnpremultiplyData_RGBA8888(&data, &data, kvImageNoFlags);
    
    [self writeImageData:(GLubyte *)imageData.bytes to:out];
}

+ (void) validatePSD:(NSData *)data
{
    uint8_t const *bytes = data.bytes;

    uint8_t const *header = bytes;

    uint32_t signature = CFSwapInt32BigToHost(*(uint32_t *) (header + 0));
    if (signature != '8BPS') {
        [NSException raise:@"Invalid PSD" format:@"Incorrect signature: %08X", signature];
    }

    uint64_t version = CFSwapInt64BigToHost(*(uint64_t *) (header + 4));
    if (version != 0x0001000000000000L) {
        [NSException raise:@"Invalid PSD" format:@"Incorrect version: %016llX", version];
    }

    uint16_t channels = CFSwapInt16BigToHost(*(uint16_t *) (header + 12));
    if (channels != 4) {
        [NSException raise:@"Invalid PSD" format:@"Incorrect channels: %u", channels];
    }

    uint32_t height = CFSwapInt32BigToHost(*(uint32_t *) (header + 14));
    if (height < 1 || height > 30000) {
        [NSException raise:@"Invalid PSD" format:@"Invalid height: %u", height];
    }

    uint32_t width = CFSwapInt32BigToHost(*(uint32_t *) (header + 18));
    if (width < 1 || width > 30000) {
        [NSException raise:@"Invalid PSD" format:@"Invalid width: %u", width];
    }

    uint16_t depth = CFSwapInt16BigToHost(*(uint16_t *) (header + 22));
    if (depth != DEPTH) {
        [NSException raise:@"Invalid PSD" format:@"Incorrect channels: %u", channels];
    }

    uint16_t colorMode = CFSwapInt16BigToHost(*(uint16_t *) (header + 24));
    if (colorMode != COLOR_MODE) {
        [NSException raise:@"Invalid PSD" format:@"Incorrect channels: %u", channels];
    }

    uint32_t colorModeDataLength = CFSwapInt32BigToHost(*(uint32_t *) (bytes + 26));
    if (colorModeDataLength != 0) {
        [NSException raise:@"Invalid PSD" format:@"Invalid color mode data length: %u", colorModeDataLength];
    }

    uint32_t imageResourcesDataLength = CFSwapInt32BigToHost(*(uint32_t *) (bytes + 30));
    if (imageResourcesDataLength != 0) {
        [NSException raise:@"Invalid PSD" format:@"Invalid image resources length: %u", imageResourcesDataLength];
    }

    uint8_t const *layerAndMaskInfo = bytes + 34;
    uint32_t layerAndMaskDataLength = CFSwapInt32BigToHost(*(uint32_t *) (layerAndMaskInfo + 0));
    // validated in summation later

    uint8_t const *layerInfo = layerAndMaskInfo + 4;
    uint32_t layerInfoDataLength = CFSwapInt32BigToHost(*(uint32_t *) (layerInfo + 0));
    // validated in summation later

    int16_t layerCount = CFSwapInt16BigToHost(*(uint16_t *) (layerInfo + 4));
    if (layerCount < 0) {
        // "first alpha channel contains the transparency data for the merged result." ?
        layerCount = -layerCount;
    }

    uint32_t channelDataSizeTotal = 0;

    uint8_t const *layerRecord = layerInfo + 4 + 2;
    for (int i = 0; i < layerCount; ++i) {
        uint32_t top = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 0));
        uint32_t left = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 4));
        uint32_t bottom = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 8));
        uint32_t right = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 12));
        if (top > bottom) {
            [NSException raise:@"Invalid PSD" format:@"Top > bottom: %u > %u", top, bottom];
        }
        if (left > right) {
            [NSException raise:@"Invalid PSD" format:@"Left > right: %u > %u", left, right];
        }
        uint16_t layerChannels = CFSwapInt16BigToHost(*(uint16_t *) (layerRecord + 16));
        for (int channel = 0; channel < layerChannels; ++channel) {
            uint16_t channelNumber = CFSwapInt16BigToHost(*(uint16_t *) (layerRecord + 18 + channel * 6 ));
            if (channelNumber > 2 && channelNumber != 0xFFFF) {
                [NSException raise:@"Invalid PSD" format:@"Incorrect channel number: %04X", channelNumber];
            }
            uint32_t channelDataSize = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 18 + channel * 6 + 2));
            channelDataSizeTotal += channelDataSize;
        }
        
        uint32_t blendModeSignature = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 18 + layerChannels * 6));
        if (blendModeSignature != '8BIM') {
            [NSException raise:@"Invalid PSD" format:@"Incorrect blend mode signature: %08X", blendModeSignature];
        }

        uint32_t blendModeKey = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 18 + layerChannels * 6 + 4));
        switch (blendModeKey) {
            case 'norm':
            case 'dark':
            case 'lite':
            case 'hue ':
            case 'sat ':
            case 'colr':
            case 'lum ':
            case 'mul ':
            case 'scrn':
            case 'diss':
            case 'over':
            case 'hLit':
            case 'sLit':
            case 'diff':
            case 'smud':
            case 'div ':
            case 'idiv':
            case 'lbrn':
            case 'lddg':
            case 'vLit':
            case 'iLit':
            case 'pLit':
            case 'hMix':
            case 'pass':
            case 'dkCl':
            case 'lgCl':
            case 'fsub':
            case 'fdiv':
                // OK!
                break;
            default:
                [NSException raise:@"Invalid PSD" format:@"Invalid blend mode key: %08X", blendModeKey];
        }

        // uint8_t opacity = *(layerRecord + 18 + layerChannels * 6 + 8);

        uint8_t clipping = *(layerRecord + 18 + layerChannels * 6 + 9);
        if (clipping > 1) {
            [NSException raise:@"Invalid PSD" format:@"Unknown clipping: %02X", clipping];
        }

        uint8_t flags = *(layerRecord + 18 + layerChannels * 6 + 10);
        if ((flags & 0xe0) != 0) {
            [NSException raise:@"Invalid PSD" format:@"Unknown flags: %02X", flags];
        }

        uint8_t filler = *(layerRecord + 18 + layerChannels * 6 + 11);
        if (filler != 0) {
            [NSException raise:@"Invalid PSD" format:@"Unknown filler: %02X", filler];
        }

        uint32_t extraDataFieldFieldLength = CFSwapInt32BigToHost(*(uint32_t *) (layerRecord + 18 + layerChannels * 6 + 12));

        layerRecord += (18 + layerChannels * 6 + 16 + extraDataFieldFieldLength);
    }
    
    if (layerInfoDataLength != (layerRecord - layerInfo) - 4 + channelDataSizeTotal) {
        [NSException raise:@"Invalid PSD" format:@"Layer info does not add up: %d + %u != %u", (int)((layerRecord - layerInfo) - 4), channelDataSizeTotal, layerInfoDataLength];
    }

    const uint8_t *globalLayerInfo = layerInfo + 4 + layerInfoDataLength;
    uint32_t globalLayerInfoDataLength = CFSwapInt32BigToHost(*(uint32_t *) (globalLayerInfo + 0));
    if (layerAndMaskDataLength != layerInfoDataLength + globalLayerInfoDataLength + 8) {
        [NSException raise:@"Invalid PSD" format:@"Layer section sizes do not add up: 4 + %u + 4 + %u != %u", layerInfoDataLength, globalLayerInfoDataLength, layerAndMaskDataLength];
    }

//    uint32_t imageDataLength = height * width * CHANNELS;
//    if (data.length != 26 + (4 + colorModeDataLength) + (4 + imageResourcesDataLength) + (4 + layerAndMaskDataLength) + (2 + imageDataLength)) {
//        [NSException raise:@"Invalid PSD" format:@"Section sizes do not add up: 26 + (4 + %u) + (4 + %u) + (4 + %u) + (2 + %u * %u * %u) != %u",
//           colorModeDataLength, imageResourcesDataLength, layerAndMaskDataLength, height, width, CHANNELS, data.length];
//    }
}

@end
