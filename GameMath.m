/*
 *  GameMath.c
 *  JazzBall
 *
 *  Created by Julian on 4/1/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "GameMath.h"
#import <Foundation/NSObjCRuntime.h>


CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
	CGFloat deltaX = second.x - first.x;
	CGFloat deltaY = second.y - first.y;
#if defined(__LP64__) && __LP64__
	return sqrt(deltaX*deltaX + deltaY*deltaY );
#else
    return sqrtf(deltaX*deltaX + deltaY*deltaY);
#endif
};

CGFloat squaredDistanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return (deltaX*deltaX + deltaY*deltaY);
};
/*
BOOL CGRectAlmostEqualToRect(CGRect r1, CGRect r2) {
    return ABS(r1.origin.x - r2.origin.x) < ALMOST_EQUAL_THRESHOLD && ABS(r1.origin.y - r2.origin.y) < ALMOST_EQUAL_THRESHOLD && ABS(r1.size.width - r2.size.width) < ALMOST_EQUAL_THRESHOLD && ABS(r1.size.height - r2.size.height) < ALMOST_EQUAL_THRESHOLD;
}
*/
Vector OrthogonalVector(Vector a) {
    CGFloat denom;
#if defined(__LP64__) && __LP64__
    denom = sqrt(a.x*a.x + a.y*a.y);
#else
    denom = sqrtf(a.x*a.x + a.y*a.y);
#endif
    return MakeVector(-a.y*signum(a.x)/denom, ABS(a.x)/denom);
}

Vector ProjectVector(Vector v, Vector proj) {
    Vector projHat = UnitDirectionVector(proj);
    CGFloat dotProduct = v.x*proj.x + v.y*proj.y;
    return MakeVector(projHat.x*dotProduct, projHat.y*dotProduct);
}

CGFloat solveQuadraticForGreaterSolution(CGFloat a, CGFloat b, CGFloat c) {
    CGFloat D;
//    dlog(@"quadratic: a=%f, b=%f, c=%f", a, b, c);
#if defined(__LP64__) && __LP64__
    D = sqrt(b*b - 4*a*c);
#else
    D = sqrtf(b*b - 4*a*c);
#endif
    CGFloat t = -0.5*(b + signum(b)*D);
    CGFloat r1 = t/a;
    CGFloat r2 = c/t;
    return MAX(r1, r2);
}

CGFloat solveQuadraticForLesserSolution(CGFloat a, CGFloat b, CGFloat c) {
    CGFloat D;
//	dlog(@"quadratic: a=%f, b=%f, c=%f", a, b, c);
#if defined(__LP64__) && __LP64__
    D = sqrt(b*b - 4*a*c);
#else
    D = sqrtf(b*b - 4*a*c);
#endif
    CGFloat t = -0.5*(b + signum(b)*D);
    CGFloat r1 = t/a;
    CGFloat r2 = c/t;
//    dlog(@"SolveQuadraticForLesserSolultion: %f, %f", r1, r2);
    return MIN(r1, r2);
}

Vector RandomVectorWithMagnitude(CGFloat magnitude) {
    CGFloat theta = (float)myrandom()/RAND_MAX*2*M_PI;
    // convert polar coords to euclidean
    return MakeVector(magnitude*cos(theta), magnitude*sin(theta));
}

// in RandomVelocity. we make sure that the velocity isn't too x- or y-oriented,
// which would make the level start boring.
Vector RandomVelocityWithMagnitude(CGFloat magnitude) {
    CGFloat theta = 0;
    while (1) {
        theta = (float)myrandom()/RAND_MAX*2*M_PI;
        CGFloat thetaP = theta;
        while (thetaP > .5*M_PI) {
            thetaP -= .5*M_PI;
        }
        if (thetaP >= .5*.25*M_PI && thetaP <= .5*.75*M_PI) {
            break;
        }
        dlog(@"repeat for theta=%f, thetaP=%f", theta*180.0/M_PI, thetaP*180.0/M_PI);
    }
    // convert polar coords to euclidean
    return MakeVector(magnitude*cos(theta), magnitude*sin(theta));
}

CGRect JBRectSubtractRect(CGRect container, CGRect other) {
    CGFloat w, h;
    BOOL hsplit = other.size.width == container.size.width;
    w = hsplit ? container.size.width : container.size.width - other.size.width;
    h = !hsplit ? container.size.height : container.size.height - other.size.height;
    if (CGPointEqualToPoint(container.origin, other.origin)) {
        return CGRectMake(hsplit ? other.origin.x : other.origin.x + other.size.width, hsplit ? other.origin.y + other.size.height : other.origin.y, w, h);
    }
    return CGRectMake(container.origin.x, container.origin.y, w, h);
}

BOOL CGRectAdjacentToRect(CGRect r1, CGRect r2) {
    JBRange r1Range, r2Range;
    // first test: adjacent in x
    if (r2.origin.x == r1.origin.x + r1.size.width) {
        r1Range = JBMakeRange(r1.origin.y, r1.size.height);
        r2Range = JBMakeRange(r2.origin.y, r2.size.height);
        return RangeIntersectsRange(r1Range, r2Range);
    }
    else if (r2.origin.y == r1.origin.y + r1.size.height) {
        r1Range = JBMakeRange(r1.origin.x, r1.size.width);
        r2Range = JBMakeRange(r2.origin.x, r2.size.width);
        return RangeIntersectsRange(r1Range, r2Range);
    }
    else if (r1.origin.x == r2.origin.x + r2.size.width) {
        r1Range = JBMakeRange(r1.origin.y, r1.size.height);
        r2Range = JBMakeRange(r2.origin.y, r2.size.height);
        return RangeIntersectsRange(r1Range, r2Range);
    }
    else if (r1.origin.y == r2.origin.y + r2.size.height) {
        r1Range = JBMakeRange(r1.origin.x, r1.size.width);
        r2Range = JBMakeRange(r2.origin.x, r2.size.width);
        return RangeIntersectsRange(r1Range, r2Range);
    }
    
    return NO;
}
