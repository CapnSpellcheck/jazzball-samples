//
//  JazzBallView.m
//  JazzBall
//
//  Created by Julian on 4/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "JazzBallView.h"
#import "Atom.h"
#import "GameManager.h"
#import "Room.h"
#import "JBUtil.h"
#import "UIImageUncachedConvenience.h"
#import "JazzBallViewController.h"
#import "RowColumnHighlightLayer.h"
#import <QuartzCore/QuartzCore.h>

#define SWIPE_DISTANCE 10.0
#define GRADIENT_VERTICAL_DISTANCE 230
#define GRADIENT_HORIZ_DISTANCE 160
#define GAME_SUBMENU_TOUCH_COUNT 2

@implementation JazzBallView

@synthesize backgroundImageLayer;
@synthesize gameManager = gameMan;

static UIColor* atomFillColor;
static CGFloat redGradientColors[] = {
    255/255.0, 89/255.0, 89/255.0, 1.,
    1., 0., 0., 1.,
//    1., .37, 0., 1.,  //red-orange
};
static CGFloat blueGradientColors[] = {
    58/255.0, 134/255.0, 202/255.0, 1.,
    0., 0., 1., 1.,
//    .43, 0., 1., 1.,
};
static CGFloat gradientLocs[] = {0., 1.};
static float oneOverSqrt3 = 0.57735;

-(void) awakeFromNib {
    [super awakeFromNib];
    dlog(@"ClearsContext: %i", [self clearsContextBeforeDrawing] == YES ? 1 : 0);
    atomFillColor = [[UIColor alloc] initWithRed:1 green:0 blue:0 alpha:1];
    cspace = CGColorSpaceCreateDeviceRGB();
    redGradient = CGGradientCreateWithColorComponents(cspace, redGradientColors, gradientLocs, 2);
    blueGradient = CGGradientCreateWithColorComponents(cspace, blueGradientColors, gradientLocs, 2);
    CGColorRef clearCGColor = [UIColor clearColor].CGColor;
    backgroundImageLayer = [CALayer new];
    CGSize windowSize = [[UIApplication sharedApplication] keyWindow].bounds.size;
    // assuming first child view is the game status...
    CGFloat statusHeight = [[[self.superview subviews] objectAtIndex:0] bounds].size.height;
    CGRect backgroundImageFrame = CGRectMake(0, statusHeight, windowSize.width, windowSize.height - statusHeight);
    [backgroundImageLayer setFrame:backgroundImageFrame];//[self.layer frame]];
    [backgroundImageLayer setContentsGravity:kCAGravityResizeAspectFill];
    [backgroundImageLayer setBackgroundColor:clearCGColor];
    [self.layer.superlayer insertSublayer:backgroundImageLayer atIndex:0];
    dlog(@"Layer tree after JazzBallView awakeFromNib:");
    //PrintLayerTree(self.layer.superlayer);
    
    // TODO: make the layers into separate classes so do not need to be the delegate and do not need to add to superlayer
    
    wallConstructionLayer = [CALayer new];
    [wallConstructionLayer setBackgroundColor:clearCGColor];
    [wallConstructionLayer setDelegate:self];
    [wallConstructionLayer setAnchorPoint:CGPointZero];
    [wallConstructionLayer setHidden:YES];
    [self.layer.superlayer addSublayer:wallConstructionLayer];
}

-(void) setBackgroundImage:(UIImage*)image {
    [backgroundImageLayer setContents:(id)image.CGImage];
}

-(void) updateWallConstruction {
    [wallConstructionLayer setNeedsDisplay];
}

-(void) hideWallConstruction {
    [wallConstructionLayer setHidden:YES];
}

-(void) showWallConstruction {
    WallConstruction* constr = gameMan.wallConstruction;
    CGRect constructionRect = constr.theoreticalCompletedExtent;
    constructionRect = [self.layer.superlayer convertRect:constructionRect fromLayer:self.layer];
    //NSLog(@"constructionRect: %@", NSStringFromCGRect(constructionRect));
    [wallConstructionLayer setPosition:constructionRect.origin];
    [wallConstructionLayer setBounds:CGRectMake(0, 0, constructionRect.size.width, constructionRect.size.height)];
    [wallConstructionLayer setHidden:NO];
    [wallConstructionLayer setNeedsDisplay];
}

-(void) showRowColumnHighlight {
    // Get the center of the tile that the touch start point is over.
    CGFloat rowY = WALL_CONSTRUCTION_THICKNESS*int(touchStartPoint.y/WALL_CONSTRUCTION_THICKNESS);
    CGPoint rowPos = CGPointMake(0, rowY);
    [rowHighlightLayer setMidpoint:touchStartPoint.x];
    [rowHighlightLayer setPosition:rowPos];
    [rowHighlightLayer setHidden:NO];
    [rowHighlightLayer setNeedsDisplay];
    
    CGFloat columnX = WALL_CONSTRUCTION_THICKNESS*int(touchStartPoint.x/WALL_CONSTRUCTION_THICKNESS);
    CGPoint colPos = CGPointMake(columnX, 0);
    [columnHighlightLayer setMidpoint:touchStartPoint.y];
    [columnHighlightLayer setPosition:colPos];
    [columnHighlightLayer setHidden:NO];
    [columnHighlightLayer setNeedsDisplay];
}

-(void) hideRowColumnHighlight {
    [rowHighlightLayer setHidden:YES];
    [columnHighlightLayer setHidden:YES];
}


-(void) prepareForNewGame {
    [rowHighlightLayer removeFromSuperlayer];
    [rowHighlightLayer release];
    [columnHighlightLayer removeFromSuperlayer];
    [columnHighlightLayer release];
    
    rowHighlightLayer = [RowColumnHighlightLayer new];
    [rowHighlightLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [rowHighlightLayer setAnchorPoint:CGPointZero];
    [rowHighlightLayer setBounds:CGRectMake(0, 0, self.bounds.size.width, WALL_CONSTRUCTION_THICKNESS)];
    dlog(@"rowHighlightLayer bounds: %@", NSStringFromCGRect(rowHighlightLayer.bounds));
    [rowHighlightLayer setHidden:YES];
    // using insert so will be "below" the atom layers.
    [self.layer insertSublayer:rowHighlightLayer atIndex:0];
    
    columnHighlightLayer = [RowColumnHighlightLayer new];
    [columnHighlightLayer setDirection:HighlightDirectionColumn];
    [columnHighlightLayer setBackgroundColor:[UIColor clearColor].CGColor];
    [columnHighlightLayer setAnchorPoint:CGPointZero];
    [columnHighlightLayer setBounds:CGRectMake(0, 0, WALL_CONSTRUCTION_THICKNESS, self.bounds.size.height)];
    [columnHighlightLayer setHidden:YES];
    [self.layer insertSublayer:columnHighlightLayer atIndex:1];
}


-(void) drawLayer:(CALayer*)layer inContext:(CGContextRef)ctx {
    if (layer == wallConstructionLayer) {
#if PERFLOG
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
#endif
        WallConstruction* constr = gameMan.wallConstruction;
        
        if ([gameMan isConstructingWall]) {
            //gameOriginInSuperview = [self convertPoint:CGPointZero toView:self.superview];
            //CGAffineTransform wallTx = CGAffineTransformMakeTranslation(gameOriginInSuperview.x-wallConstructionLayer.position.x, gameOriginInSuperview.y-wallConstructionLayer.position.y);
            CGRect minusComponent = [constr extentForComponent:WallComponentTowardsZero];
            CGRect plusComponent = [constr extentForComponent:WallComponentTowardsInfinity];
            
            CGRect testClip = CGContextGetClipBoundingBox(ctx);
            dlog(@"** drawing wall construction: safe to draw in %@", NSStringFromCGRect(testClip));
            
            CGContextSaveGState(ctx);
            CGContextSaveGState(ctx);
            CGRect minusComponentTxRect = [self.layer convertRect:minusComponent toLayer:wallConstructionLayer];
            CGContextClipToRect(ctx, minusComponentTxRect);
            CGPoint origin = [constr origin];
            CGPoint endpoint = constr.direction == WallDirectionHorizontal ? CGPointMake(constr.minGoalValue, origin.y) : CGPointMake(origin.x, constr.minGoalValue);
            CGPoint originTx = [self.layer convertPoint:origin toLayer:wallConstructionLayer];
            endpoint = [self.layer convertPoint:endpoint toLayer:wallConstructionLayer];
            CGContextDrawLinearGradient(ctx, redGradient, originTx, endpoint, kCGGradientDrawsAfterEndLocation);
            CGContextRestoreGState(ctx);
            CGRect plusComponentTxRect = [self.layer convertRect:plusComponent toLayer:wallConstructionLayer];
            CGContextClipToRect(ctx, plusComponentTxRect);
            endpoint = constr.direction == WallDirectionHorizontal ? CGPointMake(constr.maxGoalValue, origin.y) : CGPointMake(origin.x, constr.maxGoalValue);
            endpoint = [self.layer convertPoint:endpoint toLayer:wallConstructionLayer];
            CGContextDrawLinearGradient(ctx, blueGradient, originTx, endpoint, kCGGradientDrawsAfterEndLocation);
            CGContextRestoreGState(ctx);
        }
        
#if PERFLOG
        NSTimeInterval end = [NSDate timeIntervalSinceReferenceDate];
#if !TARGET_IPHONE_SIMULATOR
        static unsigned short _qz = 0;
        if (_qz++ == 10) {
            _qz = 0;
#endif
            NSLog(@"drawRect time: %f", end - start);
#if !TARGET_IPHONE_SIMULATOR
        }
#endif
#endif
    }
    else {
        [super drawLayer:layer inContext:ctx];
    }
}

-(void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    short touchCount = [[event allTouches] count];
//    NSLog(@"touchesBegan: %i (%i total)", [touches count], [[event allTouches] count]);

    if (touchCount == 1) {
        firstTouch = [touches anyObject];
        touchStartPoint = [firstTouch locationInView:self];
        touchHandled = NO;
        
        // before showing the highlight, validate over the playing area
        if ([gameMan.mainRoom roomContainingPoint:touchStartPoint] != nil) {
            [self showRowColumnHighlight];
        }
    }
    else if (touchCount == GAME_SUBMENU_TOUCH_COUNT) {
        [gameMan.controller showSubmenuActionSheet];
        return;
    }
    
}

-(void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
//    NSLog(@"Touches moved: %i (total %i) ", [touches count], [[event allTouches] count]);
    if (touchHandled)
        return;
    if (![touches containsObject:firstTouch]) {
        return;
    }
    
    short touchCount = [[event allTouches] count];
    if (touchCount == GAME_SUBMENU_TOUCH_COUNT) {
        [gameMan.controller showSubmenuActionSheet];
        return;
    }
    
    CGPoint touchPoint = [firstTouch locationInView:self];
    CGFloat absx = ABS(touchPoint.x - touchStartPoint.x);
    CGFloat absy = ABS(touchPoint.y - touchStartPoint.y);
    if (absx >= SWIPE_DISTANCE && absy <= oneOverSqrt3*absx) {
        CGFloat midx = .5*(touchPoint.x + touchStartPoint.x);
        dlog(@"View checking isConstructing wall");
        if (![gameMan isConstructingWall]) {
            dlog(@"Not constructing wall");
            [gameMan startWallConstructionWithOrigin:CGPointMake(midx, touchStartPoint.y) direction:WallDirectionHorizontal];
        }
        else {
            [gameMan noteUnhandledTouch];
        }
        touchHandled = YES;
    }
    else if (absy >= SWIPE_DISTANCE && absx <= oneOverSqrt3*absy) {
        CGFloat midy = .5*(touchPoint.y + touchStartPoint.y);
        dlog(@"View checking isConstructing wall");
        if (![gameMan isConstructingWall]) {
            dlog(@"Not constructing wall");
            [gameMan startWallConstructionWithOrigin:CGPointMake(touchStartPoint.x, midy) direction:WallDirectionVertical];
        }
        else {
            [gameMan noteUnhandledTouch];
        }
        touchHandled = YES;
    }
    if (touchHandled) {
        [self hideRowColumnHighlight];
    }
}

-(void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
    UITouch* endedTouch = [touches anyObject];
    if (endedTouch == firstTouch && !touchHandled) {
        [gameMan noteUnhandledTouch];
    }
    [self hideRowColumnHighlight];
    touchHandled = NO;
    firstTouch = nil;
}

-(void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
    [self hideRowColumnHighlight];
    touchHandled = NO;
    firstTouch = nil;
}

- (void)dealloc {
    [gameMan release];
    [atomFillColor release];
    CGColorSpaceRelease(cspace);
    CGGradientRelease(redGradient);
    CGGradientRelease(blueGradient);
    [backgroundImageLayer removeFromSuperlayer];
    [backgroundImageLayer release];
    [super dealloc];
    [wallConstructionLayer removeFromSuperlayer];
    [wallConstructionLayer release];
}


@end
