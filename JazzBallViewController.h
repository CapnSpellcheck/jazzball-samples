//
//  JazzBallViewController.h
//  JazzBall
//
//  Created by Julian on 4/1/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JazzBallView.h"
#import "GADBannerViewDelegate.h"

#define UDHasReadInstructionsKey @"seenInstrs"

@class GameManager, LevelSummaryView, GADBannerView;

@interface JazzBallViewController : UIViewController<UIActionSheetDelegate, GADBannerViewDelegate> {
    GameManager* gameMan;
    IBOutlet JazzBallView* gameView;
    IBOutlet LevelSummaryView* levelSummaryView;
    IBOutlet UILabel* lblPercentComplete;
    IBOutlet UILabel* lblScore;
    IBOutlet UILabel* lblLives;
    IBOutlet UILabel* lblBonus;
    IBOutlet UILabel* lblLeveLintro;
    UIColor* oneLifeColor;
    bool didStartByViewingInstructions;
    BOOL showingGameSubmenu;
    GADBannerView* adView;
}

@property (nonatomic, readonly) JazzBallView* gameView;
@property (nonatomic, readonly) UILabel* percentCompleteLabel;
@property (nonatomic, readonly) LevelSummaryView* levelSummaryView;
@property (nonatomic, readonly) BOOL isShowingGameSubmenu;

-(void) initViewsAndShit;

-(void) startGame;
-(void) startGameWithContext:(NSDictionary*)context;
-(void) pauseGame;
-(BOOL) resumeGame;
-(void) saveGame;
-(void) loadGame;

-(void) endLevel;
-(void) beginLevel;

-(void) setScore:(unsigned long)score;
-(void) setLives:(unsigned short)lives;
-(void) setPercentComplete:(short)pct;
-(void) updateBonusTimer:(short)bonus;
-(void) gameTileChanged:(id)sender;
-(void) showSubmenuActionSheet;

+(NSString*) saveFilePath;

@end

