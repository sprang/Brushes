//
//  WDUtilities.h
//  Brushes
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2008-2013 Steve Sprang
//

#import <UIKit/UIKit.h>

#if WD_DEBUG
#define WDLog NSLog
#else
#define WDLog(...)
#endif

#if WD_DEBUG
void WDBeginTiming();
#else
#define WDBeginTiming(...)
#endif

#if WD_DEBUG
void WDLogTiming(NSString *message); // intermediate message to log before end timing is called
#else
#define WDLogTiming(...)
#endif

#if WD_DEBUG
void WDEndTiming(NSString *message);
#else
#define WDEndTiming(...)
#endif

void HSVtoRGB(float h, float s, float v, float *r, float *g, float *b);
void RGBtoHSV(float r, float g, float b, float *h, float *s, float *v);

float WDSineCurve(float input);

void WDDrawCheckersInRect(CGContextRef ctx, CGRect dest, int size);
void WDDrawTransparencyDiamondInRect(CGContextRef ctx, CGRect dest);

void WDContextDrawImageToFill(CGContextRef ctx, CGRect bounds, CGImageRef imageRef);

CGSize WDSizeOfRectWithAngle(CGRect rect, float angle, CGPoint *upperLeft, CGPoint *upperRight);

CGPoint WDNormalizePoint(CGPoint vector);

float OSVersion();

CGRect WDGrowRectToPoint(CGRect rect, CGPoint pt);

NSData * WDSHA1DigestForData(NSData *data);

CGPoint WDSharpPointInContext(CGPoint pt, CGContextRef ctx);

CGPoint WDConstrainPoint(CGPoint pt);

CGRect WDRectFromPoint(CGPoint a, float width, float height);

CGPathRef WDConvertPathQuadraticToCubic(CGPathRef pathRef);

BOOL WDCollinear(CGPoint a, CGPoint b, CGPoint c);

BOOL WDLineInRect(CGPoint a, CGPoint b, CGRect test);

CGPathRef WDTransformCGPathRef(CGPathRef pathRef, CGAffineTransform transform);

BOOL WDLineSegmentsIntersectWithValues(CGPoint A, CGPoint B, CGPoint C, CGPoint D, float *r, float *s);
BOOL WDLineSegmentsIntersect(CGPoint A, CGPoint B, CGPoint C, CGPoint D);

CGRect WDShrinkRect(CGRect rect, float percentage);

CGAffineTransform WDTransformForOrientation(UIInterfaceOrientation orientation);

float WDRandomFloat();
int WDRandomIntInRange(int min, int max);
float WDRandomFloatInRange(float min, float max);

CGRect WDUnionRect(CGRect a, CGRect b);

void WDCheckGLError_(const char *file, int line);
#if WD_DEBUG
#define WDCheckGLError() WDCheckGLError_(__FILE__, __LINE__);
#else
#define WDCheckGLError()
#endif

NSString * generateUUID();

BOOL WDDeviceIsPhone();
BOOL WDDeviceIs4InchPhone();
BOOL WDUseModernAppearance();

BOOL WDCanUseScissorTest();

size_t WDGetTotalMemory();
BOOL WDCanUseHDTextures();

/******************************
 * WDQuad
 *****************************/

typedef struct {
    CGPoint     corners[4];
} WDQuad;

WDQuad WDQuadNull();
WDQuad WDQuadMake(CGPoint a, CGPoint b, CGPoint c, CGPoint d);
WDQuad WDQuadWithRect(CGRect rect, CGAffineTransform transform);
BOOL WDQuadEqualToQuad(WDQuad a, WDQuad b);
BOOL WDQuadIntersectsQuad(WDQuad a, WDQuad b);
CGPathRef WDQuadCreatePathRef(WDQuad q);
NSString * NSStringFromWDQuad(WDQuad quad);

/******************************
 * static inline functions
 *****************************/

static inline float WDIntDistance(int x1, int y1, int x2, int y2) {
    int xd = (x1-x2), yd = (y1-y2);
    return sqrt(xd * xd + yd * yd);
}

static inline CGPoint WDAddPoints(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint WDSubtractPoints(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

static inline CGSize WDAddSizes(CGSize a, CGSize b) {
    return CGSizeMake(a.width + b.width, a.height + b.height);
}


static inline float WDDistance(CGPoint a, CGPoint b) {
    float xd = (a.x - b.x);
    float yd = (a.y - b.y);
    
    return sqrt(xd * xd + yd * yd);
}

static inline float WDClamp(float min, float max, float value) {
    return (value < min) ? min : (value > max) ? max : value;
}

static inline CGPoint WDCenterOfRect(CGRect rect) {
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

static inline CGRect WDMultiplyRectScalar(CGRect r, float s) {
    return CGRectMake(r.origin.x * s, r.origin.y * s, r.size.width * s, r.size.height * s);
}

static inline CGSize WDMultiplySizeScalar(CGSize size, float s) {
    return CGSizeMake(size.width * s, size.height * s);
}

static inline CGPoint WDMultiplyPointScalar(CGPoint p, float s) {
    return CGPointMake(p.x * s, p.y * s);
}

static inline CGRect WDRectWithPoints(CGPoint a, CGPoint b) {
    float minx = MIN(a.x, b.x);
    float maxx = MAX(a.x, b.x);
    float miny = MIN(a.y, b.y);
    float maxy = MAX(a.y, b.y);
    
    return CGRectMake(minx, miny, maxx - minx, maxy - miny);
}

static inline CGRect WDRectWithPointsConstrained(CGPoint a, CGPoint b, BOOL constrained) {
    float minx = MIN(a.x, b.x);
    float maxx = MAX(a.x, b.x);
    float miny = MIN(a.y, b.y);
    float maxy = MAX(a.y, b.y);
    float dimx = maxx - minx;
    float dimy = maxy - miny;
    
    if (constrained) {
        dimx = dimy = MAX(dimx, dimy);
    }
    
    return CGRectMake(minx, miny, dimx, dimy);
}

static inline CGRect WDFlipRectWithinRect(CGRect src, CGRect dst)
{
    src.origin.y = CGRectGetMaxY(dst) - CGRectGetMaxY(src);
    return src;
}

static inline CGPoint WDFloorPoint(CGPoint pt)
{
    return CGPointMake(floor(pt.x), floor(pt.y));
}

static inline CGPoint WDRoundPoint(CGPoint pt)
{
    return CGPointMake(round(pt.x), round(pt.y));
}

static inline CGPoint WDAveragePoints(CGPoint a, CGPoint b)
{
    return WDMultiplyPointScalar(WDAddPoints(a, b), 0.5f);    
}

static inline CGSize WDRoundSize(CGSize size)
{
    return CGSizeMake(round(size.width), round(size.height));
}

static inline float WDMagnitude(CGPoint point)
{
    return WDDistance(point, CGPointZero);
}



