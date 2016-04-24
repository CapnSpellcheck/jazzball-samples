//
//  RowColumnHighlightLayer.m
//  JazzBall
//
//  Created by Julez on 1/29/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "RowColumnHighlightLayer.h"
#import "JBOptionsViewController.h"

static CGFloat redTraditionalColorComponents[] = {1.0, .3, .3, .7};
static CGFloat blueTraditionalColorComponents[] = {0., 0., 1.0, .7};
static CGFloat redAstralColorComponents[] = {1.0, .3, .3, 1.0};
static CGFloat blueAstralColorComponents[] = {.4, .4, 1.0, 1.0};

@implementation RowColumnHighlightLayer

@synthesize midpoint;
@synthesize direction;

-(id) init {
    if ([super init]) {
        NSString* tilename  = [[NSUserDefaults standardUserDefaults] stringForKey:UDGameTileNameKey];
        if ([tilename isEqualToString:@"astral"]) {
            redColor = redAstralColorComponents;
            blueColor = blueAstralColorComponents;
        }
        else {
            redColor = redTraditionalColorComponents;
            blueColor = blueTraditionalColorComponents;
        }
    }
    return self;
}

- (void) drawInContext:(CGContextRef)ctx {
    static CGColorSpaceRef cspace = nil;
    if (cspace == nil) {
        cspace = CGColorSpaceCreateDeviceRGB();
    }

    CGRect bounds = self.bounds;
    
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetStrokeColorSpace(ctx, cspace);
    
    if (direction == HighlightDirectionRow) {
        CGContextSetStrokeColor(ctx, redColor);
        CGContextMoveToPoint(ctx, 0, CGRectGetMidY(bounds));
        CGContextAddLineToPoint(ctx, midpoint, CGRectGetMidY(bounds));
        CGContextStrokePath(ctx);
        CGContextBeginPath(ctx);
        CGContextSetStrokeColor(ctx, blueColor);
        CGContextMoveToPoint(ctx, midpoint, CGRectGetMidY(bounds));
        CGContextAddLineToPoint(ctx, bounds.size.width, CGRectGetMidY(bounds));
        CGContextStrokePath(ctx);
    }
    else {
        CGContextSetStrokeColor(ctx, redColor);
        CGContextMoveToPoint(ctx, CGRectGetMidX(bounds), 0);
        CGContextAddLineToPoint(ctx, CGRectGetMidX(bounds), midpoint);
        CGContextStrokePath(ctx);
        CGContextBeginPath(ctx);
        CGContextSetStrokeColor(ctx, blueColor);
        CGContextMoveToPoint(ctx, CGRectGetMidX(bounds), midpoint);
        CGContextAddLineToPoint(ctx, CGRectGetMidX(bounds), bounds.size.height);
        CGContextStrokePath(ctx);
    }
}


@end
