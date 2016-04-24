/*
 *  GameMath.h
 *  JazzBall
 *
 *  Created by Julian on 4/1/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#import <QuartzCore/QuartzCore.h>

#ifndef BETWEEN
#define BETWEEN(x, a, b) ((x) > (a) && (x) < (b))
#endif

typedef CGPoint Vector;
typedef struct {
    CGFloat origin;
    CGFloat length;
} JBRange;

static inline Vector MakeVector(CGFloat x, CGFloat y) {
    return CGPointMake(x, y);
}

static inline CGFloat VectorMagnitude(Vector v) {
#if defined(__LP64__) && __LP64__
    return sqrt(v.x*v.x + v.y*v.y);
#else
    return sqrtf(v.x*v.x + v.y*v.y);
#endif
}

static inline Vector UnitDirectionVector(Vector v) {
    CGFloat magnitude = VectorMagnitude(v);
    return MakeVector(v.x/magnitude, v.y/magnitude);
}

static inline void AddVectorToVector(Vector addee, Vector* adder) {
    adder->x += addee.x;
    adder->y += addee.y;
}

static inline Vector AddVector(Vector v, Vector w) {
    return MakeVector(v.x + w.x, v.y + w.y);
}

static inline Vector SubtractVector(Vector v, Vector w) {
    return MakeVector(v.x - w.x, v.y - w.y);
}

static inline void SubtractVectorFromVector(Vector a, Vector* b) {
	b->x -= a.x;
	b->y -= a.y;
}

static inline Vector MultiplyVector(Vector v, CGFloat scalar) {
    return MakeVector(v.x*scalar, v.y*scalar);
}

static inline Vector WeirdProduct(Vector a, Vector b) {
    return MakeVector(a.x*b.x, a.y*b.y);
}

static inline CGFloat DotProduct(Vector a, Vector b) {
    return a.x*b.x + a.y*b.y;
}

static inline Vector FirstQuadrantVector(Vector v) {
    return MakeVector(ABS(v.x), ABS(v.y));
}

static inline BOOL EqualsVector(Vector v, Vector w) {
    return CGPointEqualToPoint((CGPoint)v, (CGPoint)w);
}

#define ALMOST_EQUAL_THRESHOLD .01
//BOOL CGRectAlmostEqualToRect(CGRect r1, CGRect r2);
CGRect JBRectSubtractRect(CGRect container, CGRect other);
BOOL CGRectAdjacentToRect(CGRect r1, CGRect r2);

Vector OrthogonalVector(Vector a);
Vector ProjectVector(Vector v, Vector proj);

CGFloat distanceBetweenPoints(CGPoint first, CGPoint second);
CGFloat squaredDistanceBetweenPoints (CGPoint first, CGPoint second);

CGFloat solveQuadraticForGreaterSolution(CGFloat a, CGFloat b, CGFloat c);
CGFloat solveQuadraticForLesserSolution(CGFloat a, CGFloat b, CGFloat c);
Vector RandomVectorWithMagnitude(CGFloat magnitude);
Vector RandomVelocityWithMagnitude(CGFloat magnitude);

static inline CGFloat signum(CGFloat x) {
    return x < 0 ? -1.0 : (x > 0 ? 1.0 : 0.0);
}

static inline JBRange JBMakeRange(CGFloat origin, CGFloat length) {
    JBRange range;
    range.origin = origin;
    range.length = length;
    return range;
}

static inline BOOL JBRectContainsPoint(CGRect rect, CGPoint point) {
    return point.x >= rect.origin.x && point.y >= rect.origin.y && point.x <= CGRectGetMaxX(rect) && point.y <= CGRectGetMaxY(rect);
}

static inline BOOL RangeIntersectsRange(JBRange range1, JBRange range2) {
    if (range1.origin < range2.origin) {
        return range1.origin + range1.length > range2.origin;
    }
    return range1.origin < range2.origin + range2.length;
}

template <typename Q> Q clampToRange(Q x, Q min, Q max) {
    if (x < min)
        return min;
    if (x > max)
        return max;
    return x;
}