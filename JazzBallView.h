//
//  JazzBallView.h
//  JazzBall
//
//  Created by Julian on 4/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GameManager;
@class RowColumnHighlightLayer;

@interface JazzBallView : UIView {
    GameManager* gameMan;
    CGPoint touchStartPoint;
    BOOL touchHandled;
    CGGradientRef redGradient, blueGradient;
    CGColorSpaceRef cspace;
    CALayer* backgroundImageLayer;
    UITouch* firstTouch;
    BOOL touchesEffectivelyCanceled;
    CALayer* wallConstructionLayer;
    RowColumnHighlightLayer* rowHighlightLayer, * columnHighlightLayer;
    CGPoint gameOriginInSuperview;
}

-(void) setBackgroundImage:(UIImage*)image;
@property (nonatomic, retain) GameManager* gameManager;
@property (nonatomic, readonly) CALayer* backgroundImageLayer;

//-(CGRect) gameRect;
-(void) updateWallConstruction;
-(void) hideWallConstruction;
-(void) showWallConstruction;
-(void) showRowColumnHighlight;
-(void) hideRowColumnHighlight;

-(void) prepareForNewGame;

@end
