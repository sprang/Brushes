//
//  WDUtilities.m
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import "NSData+Base64.h"
#import "WDBezierNode.h"
#import "UIDeviceHardware.h"
#import "WDUtilities.h"
#include <CommonCrypto/CommonHMAC.h>
#include <sys/sysctl.h>

#define kMiterLimit 10

void HSVtoRGB(float h, float s, float v, float *r, float *g, float *b)
{
    if (s == 0) {
        *r = *g = *b = v;
    } else {
        float   f,p,q,t;
        int     i;
        
        h *= 360;
        
        if (h == 360.0f) {
            h = 0.0f;
        }
        
        h /= 60;
        i = floor(h);
        
        f = h - i;
        p = v * (1.0 - s);
        q = v * (1.0 - (s*f));
        t = v * (1.0 - (s * (1.0 - f)));
        
        switch (i) {
            case 0: *r = v; *g = t; *b = p; break;
            case 1: *r = q; *g = v; *b = p; break;
            case 2: *r = p; *g = v; *b = t; break;
            case 3: *r = p; *g = q; *b = v; break;
            case 4: *r = t; *g = p; *b = v; break;
            case 5: *r = v; *g = p; *b = q; break;
        }
    }
}   

void RGBtoHSV(float r, float g, float b, float *h, float *s, float *v)
{
    float max = MAX(r, MAX(g, b));
    float min = MIN(r, MIN(g, b));
    float delta = max - min;
    
    *v = max;
    *s = (max != 0.0f) ? (delta / max) : 0.0f;
    
    if (*s == 0.0f) {
        *h = 0.0f;
    } else {
        if (r == max) {
            *h = (g - b) / delta;
        } else if (g == max) {
            *h = 2.0f + (b - r) / delta;
        } else if (b == max) {
            *h = 4.0f + (r - g) / delta;
        }
        
        *h *= 60.0f;
        
        if (*h < 0.0f) {
            *h += 360.0f;
        }
    }
    
    *h /= 360.0f;
}

float WDSineCurve(float input)
{
    float result;
    
    input *= M_PI; // move from [0.0, 1.0] tp [0.0, Pi]
    input -= M_PI_2; // shift back onto a trough
    
    result = sin(input) + 1; // add 1 to put in range [0.0,2.0]
    result /= 2; // back to [0.0, 1.0];
    
    return result;
}

void WDDrawCheckersInRect(CGContextRef ctx, CGRect dest, int size)
{
    CGRect  square = CGRectMake(0, 0, size, size);
    float   startx = CGRectGetMinX(dest);
    float   starty = CGRectGetMinY(dest);
    
    CGContextSaveGState(ctx);
    CGContextClipToRect(ctx, dest);
    
    [[UIColor colorWithWhite:0.9f alpha:1.0f] set];
    CGContextFillRect(ctx, dest);
    
    [[UIColor colorWithWhite:0.78f alpha:1.0f] set];
    for (int y = 0; y * size < CGRectGetHeight(dest); y++) {
        for (int x = 0; x * size < CGRectGetWidth(dest); x++) {
            if ((y + x) % 2) {
                square.origin.x = startx + x * size;
                square.origin.y = starty + y * size;
                CGContextFillRect(ctx, square);
            }
        }
    }
    
    CGContextRestoreGState(ctx);
}

void WDDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest)
{
    float   minX = CGRectGetMinX(dest);
    float   maxX = CGRectGetMaxX(dest);
    float   minY = CGRectGetMinY(dest);
    float   maxY = CGRectGetMaxY(dest);
    
    // preserve the existing color
    CGContextSaveGState(ctx);
        [[UIColor whiteColor] set];
        CGContextFillRect(ctx, dest);
            
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, minX, minY);
        CGPathAddLineToPoint(path, NULL, maxX, minY);
        CGPathAddLineToPoint(path, NULL, minX, maxY);
        CGPathCloseSubpath(path);
        
        [[UIColor blackColor] set];
        CGContextAddPath(ctx, path);
        CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);
    
    CGPathRelease(path);
}

void WDContextDrawImageToFill(CGContextRef ctx, CGRect bounds, CGImageRef imageRef)
{
    size_t  width = CGImageGetWidth(imageRef);
    size_t  height = CGImageGetHeight(imageRef);
    float   wScale = CGRectGetWidth(bounds) / width;
    float   hScale = CGRectGetHeight(bounds) / height;
    float   scale = MAX(wScale, hScale);
    float   hOffset = 0.0f, vOffset = 0.0f;
    
    CGRect  rect = CGRectMake(0, 0, width * scale, height * scale);
    
    if (CGRectGetWidth(rect) > CGRectGetWidth(bounds)) {
        hOffset = CGRectGetWidth(rect) - CGRectGetWidth(bounds);
        hOffset /= -2;
    } 
    
    if (CGRectGetHeight(rect) > CGRectGetHeight(bounds)) {
        vOffset = CGRectGetHeight(rect) - CGRectGetHeight(bounds);
        vOffset /= -2;
    }
    
    rect = CGRectOffset(rect, hOffset, vOffset);
    
    CGContextDrawImage(ctx, rect, imageRef);
}

CGSize WDSizeOfRectWithAngle(CGRect rect, float angle, CGPoint *upperLeft, CGPoint *upperRight)
{
    CGPoint center, corners[4];
    
    center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle * M_PI / 180.0f);
    
    corners[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    corners[1] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    corners[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    corners[3] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    
    for (int i = 0; i < 4; i++) {
        corners[i] = CGPointApplyAffineTransform(corners[i], transform);
    }
    center = CGPointApplyAffineTransform(center, transform);
    
    float minx = corners[0].x;
    float maxx = corners[0].x;
    float miny = corners[0].y;
    float maxy = corners[0].y;
    
    for (int i = 1; i < 4; i++) {
        minx = MIN(minx, corners[i].x);
        maxx = MAX(maxx, corners[i].x);
        miny = MIN(miny, corners[i].y);
        maxy = MAX(maxy, corners[i].y);
    }
    
    if (upperLeft) {
        *upperLeft = WDSubtractPoints(corners[0], center);
    }
    
    if (upperRight) {
        *upperRight = WDSubtractPoints(corners[3], center);
    }
    
    return CGSizeMake(maxx - minx, maxy - miny);
}

CGPoint WDNormalizePoint(CGPoint vector)
{
    float distance = WDDistance(CGPointZero, vector);
    
    if (distance == 0.0f) {
        return vector;
    }
    
    return WDMultiplyPointScalar(vector, 1.0f / WDDistance(CGPointZero, vector));
}

float OSVersion()
{
    static NSInteger  version_ = 0;
    
    if (version_ == 0) {
        version_ = [[[UIDevice currentDevice] systemVersion] integerValue];
    }
    
    return version_;
}

BOOL WDUseModernAppearance()
{
    return OSVersion() >= 7 ? YES : NO;
}

CGRect WDGrowRectToPoint(CGRect rect, CGPoint pt)
{
    float minX, minY, maxX, maxY;
    
    minX = MIN(CGRectGetMinX(rect), pt.x);
    minY = MIN(CGRectGetMinY(rect), pt.y);
    maxX = MAX(CGRectGetMaxX(rect), pt.x);
    maxY = MAX(CGRectGetMaxY(rect), pt.y);
    
    return CGRectUnion(rect, CGRectMake(minX, minY, maxX - minX, maxY - minY));
}

NSData * WDSHA1DigestForData(NSData *data)
{    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, NULL, 0, [data bytes], [data length], cHMAC);
    
    return [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
}

CGPoint WDSharpPointInContext(CGPoint pt, CGContextRef ctx)
{
    pt = CGContextConvertPointToDeviceSpace(ctx, pt);
    pt = WDFloorPoint(pt);
    pt = WDAddPoints(pt, CGPointMake(0.5f, 0.5f));
    pt = CGContextConvertPointToUserSpace(ctx, pt);
    
    return pt;
}

CGPoint WDConstrainPoint(CGPoint delta)
{
    float   angle = atan2(delta.y, delta.x);
    float   magnitude = WDDistance(delta, CGPointZero);
    
    angle = roundf(angle / M_PI_4) * M_PI_4;
    delta.x = cos(angle) * magnitude;
    delta.y = sin(angle) * magnitude;
    
    return delta;
}

CGRect WDRectFromPoint(CGPoint a, float width, float height)
{
    return CGRectMake(a.x - (width / 2), a.y - (height / 2), width, height);
}

void convertQuadraticPathElement(void *info, const CGPathElement *element)
{
    CGMutablePathRef    converted = (CGMutablePathRef) info;
    CGPoint             prev;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            CGPathMoveToPoint(converted, NULL, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddLineToPoint:
            CGPathAddLineToPoint(converted, NULL, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddQuadCurveToPoint:
            prev = CGPathGetCurrentPoint(converted);
            
            // convert quadratic to cubic: http://fontforge.sourceforge.net/bezier.html
            CGPoint outPoint = WDAddPoints(prev, WDMultiplyPointScalar(WDSubtractPoints(element->points[0], prev), 2.0f / 3));
            CGPoint inPoint = WDAddPoints(element->points[1], WDMultiplyPointScalar(WDSubtractPoints(element->points[0], element->points[1]), 2.0f / 3));
            
            CGPathAddCurveToPoint(converted, NULL, outPoint.x, outPoint.y, inPoint.x, inPoint.y, element->points[1].x, element->points[1].y);
            break;
        case kCGPathElementAddCurveToPoint:
            CGPathAddCurveToPoint(converted, NULL, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
            break;
        case kCGPathElementCloseSubpath:
            CGPathCloseSubpath(converted);
            break;
            
    }
}

CGPathRef WDConvertPathQuadraticToCubic(CGPathRef pathRef)
{
    CGMutablePathRef converted = CGPathCreateMutable();
        
    CGPathApply(pathRef, converted, &convertQuadraticPathElement);
    
    return converted;
}

BOOL WDCollinear(CGPoint a, CGPoint b, CGPoint c)
{
    float distances[3];
    
    distances[0] = WDDistance(a, b);
    distances[1] = WDDistance(b, c);
    distances[2] = WDDistance(a, c);
    
    if (distances[0] > distances[1]) {
        float temp = distances[1];
        distances[1] = distances[0];
        distances[0] = temp;
    }
    
    if (distances[1] > distances[2]) {
        float temp = distances[2];
        distances[2] = distances[1];
        distances[1] = temp;
    }
    
    float difference = (fabs((distances[0] + distances[1]) - distances[2]));
    
    return (difference < 0.0001f) ? YES : NO;
}

BOOL WDLineInRect(CGPoint a, CGPoint b, CGRect test)
{
    int			acode = 0, bcode = 0;
    float		ymin, ymax, xmin, xmax;
    int         TOP = 0x1, BOTTOM = 0x2, RIGHT = 0x4, LEFT = 0x8;
    
    xmin = CGRectGetMinX(test);
    ymin = CGRectGetMinY(test);
    xmax = CGRectGetMaxX(test);
    ymax = CGRectGetMaxY(test);
    
    if(a.y > ymax) {
        acode |= TOP;
    } else if(a.y < ymin) {
        acode |= BOTTOM;
    }
    
    if(a.x > xmax) {
        acode |= RIGHT;
    } else if(a.x < xmin) {
        acode |= LEFT;
    }
    
    if(b.y > ymax) {
        bcode |= TOP;
    } else if(b.y < ymin) {
        bcode |= BOTTOM;
    }
    
    if(b.x > xmax) {
        bcode |= RIGHT;
    } else if(b.x < xmin) {
        bcode |= LEFT;
    }
    
    if(acode == 0 || bcode == 0) { // one or both endpoints within rect
        return YES;
    } else if(acode & bcode) { // completely outside of rectangle
        return NO;
    } else { // special case
        CGPoint		middle;
        // split line and test each half recursively
        middle.x = (a.x + b.x) / 2.0f;
        middle.y = (a.y + b.y) / 2.0f;
        
        if (WDLineInRect(a, middle, test)) {
            return YES;
        }
        
        if (WDLineInRect(middle, b, test)) {
            return YES;
        }
        return NO;
    }
}

typedef struct {
    CGMutablePathRef mutablePath;
    CGAffineTransform transform;
} WDPathAndTransform;

void transformPathElement(void *info, const CGPathElement *element)
{
    WDPathAndTransform  pathAndTransform = *((WDPathAndTransform *) info);
    CGAffineTransform   transform = pathAndTransform.transform;
    CGMutablePathRef    pathRef = pathAndTransform.mutablePath;
    
    switch (element->type) {
        case kCGPathElementMoveToPoint:
            CGPathMoveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddLineToPoint:
            CGPathAddLineToPoint(pathRef, &transform, element->points[0].x, element->points[0].y);
            break;
        case kCGPathElementAddQuadCurveToPoint:
            CGPathAddQuadCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y);
            break;
        case kCGPathElementAddCurveToPoint:
            CGPathAddCurveToPoint(pathRef, &transform, element->points[0].x, element->points[0].y, element->points[1].x, element->points[1].y, element->points[2].x, element->points[2].y);
            break;
        case kCGPathElementCloseSubpath:
            CGPathCloseSubpath(pathRef);
            break;
            
    }
}

CGPathRef WDTransformCGPathRef(CGPathRef pathRef, CGAffineTransform transform)
{
    CGMutablePathRef    transformedPath = CGPathCreateMutable();
    WDPathAndTransform  pathAndTransform = {transformedPath, transform};
    
    CGPathApply(pathRef, &pathAndTransform, &transformPathElement);
    
    return transformedPath;
}

BOOL WDLineSegmentsIntersectWithValues(CGPoint A, CGPoint B, CGPoint C, CGPoint D, float *rV, float *sV) 
{
    float denom = (B.x - A.x) * (D.y - C.y) - (B.y - A.y) * (D.x - C.x);
    
    if (denom == 0) {
        return NO;
    }
    
    float r = (A.y - C.y) * (D.x - C.x) - (A.x - C.x) * (D.y - C.y);
    r /= denom;
    
    float s = (A.y - C.y) * (B.x - A.x) - (A.x - C.x) * (B.y - A.y);
    s /= denom;
    
    if (rV) {
        *rV = r;
    }
    
    if (sV) {
        *sV = s;
    }
    
    return (r < 0 || r > 1 || s < 0 || s > 1) ? NO : YES;;
}

BOOL WDLineSegmentsIntersect(CGPoint A, CGPoint B, CGPoint C, CGPoint D) 
{
    return WDLineSegmentsIntersectWithValues(A, B, C, D, NULL, NULL);
}

CGRect WDShrinkRect(CGRect rect, float percentage)
{
    float   widthInset = CGRectGetWidth(rect) * percentage;
    float   heightInset = CGRectGetHeight(rect) * percentage;
    
    return CGRectInset(rect, widthInset, heightInset);
}

CGAffineTransform WDTransformForOrientation(UIInterfaceOrientation orientation)
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            transform = CGAffineTransformRotate(transform, M_PI / -2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            transform = CGAffineTransformRotate(transform, M_PI / 2);
            break;
    }
    
    return transform;
}

float WDRandomFloat()
{
    float r = random() % 10000;
    return r / 10000.0f;
}

int WDRandomIntInRange(int min, int max)
{
    return min + WDRandomFloat() * (max - min);
}

float WDRandomFloatInRange(float min, float max)
{
    return min + WDRandomFloat() * (max - min);
}

CGRect WDUnionRect(CGRect a, CGRect b)
{
    if (CGRectEqualToRect(a, CGRectZero)) {
        return b;
    } else if (CGRectEqualToRect(b, CGRectZero)) {
        return a;
    }
    
    return CGRectUnion(a, b);
}

/******************************
 * WDQuad
 *****************************/

WDQuad WDQuadNull()
{
    CGPoint bogusPoint = CGPointMake(INFINITY, INFINITY);
    return WDQuadMake(bogusPoint, bogusPoint, bogusPoint, bogusPoint);
}

WDQuad WDQuadMake(CGPoint a, CGPoint b, CGPoint c, CGPoint d)
{
    WDQuad quad;
    
    quad.corners[0] = a;
    quad.corners[1] = b;
    quad.corners[2] = c;
    quad.corners[3] = d;
    
    return quad;
}

WDQuad WDQuadWithRect(CGRect rect, CGAffineTransform transform)
{
    WDQuad quad;
    
    quad.corners[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    quad.corners[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    quad.corners[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    quad.corners[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    
    for (int i = 0; i < 4; i++) {
        quad.corners[i] = CGPointApplyAffineTransform(quad.corners[i], transform);
    }
    
    return quad;
}

BOOL WDQuadEqualToQuad(WDQuad a, WDQuad b)
{
    for (int i = 0; i < 4; i++) {
        if (!CGPointEqualToPoint(a.corners[i], b.corners[i])) {
            return NO;
        }
    }
    
    return YES;
}

BOOL WDQuadIntersectsQuad(WDQuad a, WDQuad b)
{
    WDQuad nullQuad = WDQuadNull();
    if (WDQuadEqualToQuad(a, nullQuad) || WDQuadEqualToQuad(b, nullQuad)) {
        return NO;
    }
    
    for (int i = 0; i < 4; i++) {
        for (int n = 0; n < 4; n++) {
            if (WDLineSegmentsIntersect(a.corners[i], a.corners[(i+1)%4], b.corners[n], b.corners[(n+1)%4])) {
                return YES;
            }
        }
    }
    
    return NO;
}

NSString * NSStringFromWDQuad(WDQuad quad)
{
    return [NSString stringWithFormat:@"{{%@}, {%@}, {%@}, {%@}}", NSStringFromCGPoint(quad.corners[0]), NSStringFromCGPoint(quad.corners[1]),
            NSStringFromCGPoint(quad.corners[2]), NSStringFromCGPoint(quad.corners[3])];
}

CGPathRef WDQuadCreatePathRef(WDQuad q)
{
    CGMutablePathRef pathRef = CGPathCreateMutable();
    
    CGPathMoveToPoint(pathRef, NULL, q.corners[0].x, q.corners[0].y);
    for (int i = 1; i < 4; i++) {
        CGPathAddLineToPoint(pathRef, NULL, q.corners[i].x, q.corners[i].y);
    }
    CGPathCloseSubpath(pathRef);
    
    return pathRef;
}

void WDCheckGLError_(const char* file, int line) {
    GLenum error = glGetError();
    if (error) {
        NSString *message;
        switch (error) {
            case GL_INVALID_ENUM: message = @"invalid enum"; break;
            case GL_INVALID_FRAMEBUFFER_OPERATION: message = @"invalid framebuffer operation"; break;
            case GL_INVALID_OPERATION: message = @"invalid operation"; break;
            case GL_INVALID_VALUE: message = @"invalid value"; break;
            case GL_OUT_OF_MEMORY: message = @"out of memory"; break;
            default: message = [NSString stringWithFormat:@"unknown error: 0x%x", error];
        }
        WDLog(@"ERROR: glGetError returned: %@ at %s:%d", message, file, line);
    }
}

#ifdef WD_DEBUG

static NSMutableArray *timings_ = nil;

void WDBeginTiming()
{
    if (!timings_) {
        timings_ = [[NSMutableArray alloc] init];
    }
    
    [timings_ addObject:[NSDate date]];
}

void WDLogTiming(NSString *message)
{
    if (!timings_ || timings_.count == 0) {
        NSLog(@"WDLogTiming() Error: unbalanced calls.");
        return;
    }
    
    NSDate *date = (NSDate *) [timings_ lastObject];
    
    if (message) {
        NSLog(@"%@ in %gs", message, -[date timeIntervalSinceNow]);
    } else {
        NSLog(@"%gs", -[date timeIntervalSinceNow]);
    }
}

void WDEndTiming(NSString *message)
{
    if (!timings_ || timings_.count == 0) {
        NSLog(@"WDEndTiming() Error: unbalanced calls.");
        return;
    }

    WDLogTiming(message);
    [timings_ removeLastObject];
}

#endif

NSString *generateUUID()
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuid);
    NSData *data = [NSData dataWithBytes:&bytes length:16];
    // only 22 digits are required to encode 128 bits; the last two characters are always "=="
    // replace "/" with "-" to make it safe for filenames
    NSString *uuidString = [[[data base64EncodedString] substringToIndex:22] stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    CFRelease(uuid);
    return uuidString;
}

BOOL WDDeviceIsPhone()
{
    static BOOL isPhone;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        isPhone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? YES : NO;
    });
    
    return isPhone;
}

BOOL WDDeviceIs4InchPhone()
{
    return (WDDeviceIsPhone() && [UIScreen mainScreen].bounds.size.height == 568) ? YES : NO;
}

BOOL WDCanUseScissorTest()
{
    static BOOL canScissor;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSString *reqSysVer = @"6.0";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
            canScissor = YES;
        } else {
            // on iOS 5 we can only scissor if both screen dimensions are less than 1536
            CGSize size = WDMultiplySizeScalar([UIScreen mainScreen].bounds.size, [UIScreen mainScreen].scale);
            canScissor = (size.width > 1536 || size.height > 1536) ? NO : YES;
        }
    });
    
    return canScissor;
}

size_t WDGetTotalMemory()
{
    int mib[] = { CTL_HW, HW_PHYSMEM };
    size_t mem;
    size_t len = sizeof(mem);
    sysctl(mib, 2, &mem, &len, NULL, 0);
    return mem;
}

BOOL WDCanUseHDTextures()
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    static BOOL canUseHDTextures_;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSString    *device = [[UIDeviceHardware platform] componentsSeparatedByString:@","][0];
        NSScanner   *scanner = [NSScanner scannerWithString:device];
        NSString    *model = nil;
        int         version = 0;
        
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&model];
        [scanner scanInt:&version];
        
        if ([model isEqualToString:@"iPhone"]) {
            canUseHDTextures_ = (version >= 4) ? YES : NO;
        } else if ([model isEqualToString:@"iPod"]) {
            canUseHDTextures_ = (version >= 5) ? YES : NO;
        } else if ([model isEqualToString:@"iPad"]) {
            canUseHDTextures_ = (version >= 2) ? YES : NO;
        }
    });
    
    return canUseHDTextures_;
#endif
}

