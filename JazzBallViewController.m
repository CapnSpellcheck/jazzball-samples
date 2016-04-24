//
//  JazzBallViewController.m
//  JazzBall
//
//  Created by Julian on 4/1/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "JazzBallViewController.h"
#import "JazzBallView.h"
#import "GameManager.h"
#import "JBAppController.h"
#import "LevelSummaryView.h"
#import "GADRequest.h"
#import "GADBannerView.h"


#define ARCHIVE_KEY_GAME_MANAGER @"gameman"
#define SAVE_GAME_FILE @"savedgame"
#define SCREEN_UNLOCK_DELAY 1.0
#define ADMOB_VIEW_FRAME (CGRectMake(0, 430, 320, 50))
#define LITE_GAMEVIEW_WIDTH (16*16)

@implementation JazzBallViewController

@synthesize percentCompleteLabel = lblPercentComplete;
@synthesize levelSummaryView;
@synthesize isShowingGameSubmenu = showingGameSubmenu;

static NSString* _saveFilePath = nil;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    [lblLeveLintro.layer setCornerRadius:8.0];
    
    // do this before creating gameMan
#ifdef JBALL_LITE
    CGRect gvframe = gameView.bounds;
    CGPoint center = gameView.center;
    gvframe.size.height -= GAD_SIZE_320x50.height;
    gvframe.size.width = LITE_GAMEVIEW_WIDTH;
    NSLog(@"gv frame: %@", NSStringFromCGRect(gameView.frame));
    center.y -= .5*GAD_SIZE_320x50.height;
    [gameView setBounds:gvframe];
    [gameView setCenter:center];
#endif
    
    // iPad: scale the whole gameView so it works on the big screen
#ifdef TARGET_IPAD
    [gameView setTransform:CGAffineTransformMakeScale(IPAD_SCALE, IPAD_SCALE)];
#endif
    
    gameMan = [[GameManager alloc] initWithController:self];
    [self initViewsAndShit];
    oneLifeColor = [[UIColor alloc] initWithRed:.9 green:0 blue:0 alpha:1];
    [Atom setContainerLayer:self.gameView.layer];
    showingGameSubmenu = false;
}

-(void) initViewsAndShit {
    [self.gameView setGameManager:gameMan];
    [gameMan setLevelSummaryView:levelSummaryView];
    [gameMan setLevelIntroLabel:lblLeveLintro];
}

-(void) viewDidUnload {
    [adView release];
    adView = nil;
    [super viewDidUnload];
}

// ad stuff goes here.
-(void) viewWillAppear:(BOOL)animated {
#ifdef JBALL_LITE
    adView = [[GADBannerView alloc] initWithFrame:ADMOB_VIEW_FRAME];
    [adView setAdUnitID: @"a14b6cdc09b2a67"];
    [adView setRootViewController:self];
    [adView setDelegate:self];
    [self.view addSubview:adView];
    
    GADRequest* request = [GADRequest request];
    dlog(@"GAD SDK: %@", [GADRequest sdkVersion]);
    NSArray* testDeviceArray = [[NSArray alloc] initWithObjects: GAD_SIMULATOR_ID, @"6c2dc822dd43ed5a87c36f8e02d4e6d5c6a474e5", @"74c84bb43fd0e54cce6b80213c9570e1ff7b19b2", nil];
    [request setTestDevices:testDeviceArray];
    
    [adView loadRequest:request];
    [testDeviceArray release];
#endif
}

-(void) viewWillDisappear:(BOOL)animated {
    // get rid of the banner, it auto refreshes!
    [adView removeFromSuperview];
    [adView release];
    adView = nil;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

-(JazzBallView*) gameView {
    return gameView;
}

-(void) startGame {
    [self startGameWithContext:nil];
}

-(void) startGameWithContext:(NSDictionary*)context {
    [gameMan prepareNewGame];
    [gameView prepareForNewGame];

    if (context) {
        [gameMan setGameContext:context];
    }
    
    NSUserDefaults* sud = [NSUserDefaults standardUserDefaults];
    didStartByViewingInstructions = false;
    
    if ([sud boolForKey:UDHasReadInstructionsKey] == NO) {
        UIViewController* instructionsViewController = ((JBAppController*)[[UIApplication sharedApplication] delegate]).instructionsViewController;
        [self presentModalViewController:instructionsViewController animated:YES];
        didStartByViewingInstructions = true;
    }
    else {
        [gameMan startGame];
    }
}

-(void) pauseGame {
    if ([gameMan levelPlaying] == 0)
        return;
    [gameMan pause];
}

-(BOOL) resumeGame {
    if ([gameMan levelPlaying] == 0)
        return true;
    // note that because we can't tell if the screen was unlocked, or if it was something else (call, text msg)
    // we always delay.
    
    // bugfix: if showing the submenu, don't resume.
    if (showingGameSubmenu)
        return false;
    [gameMan performSelector:@selector(resume) withObject:nil afterDelay:SCREEN_UNLOCK_DELAY];
    return true;
}

-(void) saveGame {
    dlog(@"SAVING GAME");
    NSString* savefile = [JazzBallViewController saveFilePath];
    
    NSMutableData* mdata = [NSMutableData new];
    NSKeyedArchiver* keyarch = [[NSKeyedArchiver alloc] initForWritingWithMutableData:mdata];
    [keyarch encodeObject:gameMan forKey:ARCHIVE_KEY_GAME_MANAGER];
    [keyarch finishEncoding];
    if (![mdata writeToFile:savefile atomically:NO]) {
        NSLog(@"failed to write save file");
    }
    [keyarch release];
    [mdata release];
}

-(void) loadGame {
    dlog(@"LOADING GAME");
    NSString* savefile = [JazzBallViewController saveFilePath];
    
    NSMutableData* mdata = [[NSMutableData alloc] initWithContentsOfFile:savefile];
    NSKeyedUnarchiver* keyunarch = [[NSKeyedUnarchiver alloc] initForReadingWithData:mdata];
    [gameMan release];
    gameMan = [keyunarch decodeObjectForKey:ARCHIVE_KEY_GAME_MANAGER];
    [gameMan retain];
    [keyunarch finishDecoding];
    [keyunarch release];
    [mdata release];
    
    [gameMan setController:self];
    [self initViewsAndShit];
    [gameMan resumeSavedGame];
}

-(void) endLevel {
    [levelSummaryView setHidden:NO];
}

-(void) beginLevel {
    [levelSummaryView setHidden:YES];
}

-(void) setScore:(unsigned long)score {
    NSString* scoreStr = [[NSString alloc] initWithFormat:@"%u", score];
    [lblScore setText:scoreStr];
    [scoreStr release];
}

-(void) setLives:(unsigned short)lives {
    static unsigned short lastLives = 0;
    NSString* livesStr = [[NSString alloc] initWithFormat:@"%hu", lives];
    [lblLives setText:livesStr];
    if (lastLives == 1) {
        [lblLives setTextColor:[UIColor blackColor]];
    }
    if (lives == 1) {
        [lblLives setTextColor:[UIColor redColor]];
    }
    lastLives = lives;
    [livesStr release];
}

-(void) setPercentComplete:(short)pct {
    NSString* completedAreaPercent = [NSString stringWithFormat:@"%i%%", pct];
    [lblPercentComplete setText:completedAreaPercent];
}

-(void) updateBonusTimer:(short)bonus {
    NSString* bonusString = [NSString stringWithFormat:@"%i", bonus];
    [lblBonus setText:bonusString];
}

-(void) gameTileChanged:(id)sender {
    [gameMan checkLoadTileImage];
}

-(void) showSubmenuActionSheet {
    if (showingGameSubmenu) {
        return;
    }
    
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Resume" destructiveButtonTitle:@"Quit to Menu" otherButtonTitles:nil];
    [sheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [self pauseGame];
    [sheet showInView:self.view];
    [sheet release];
    showingGameSubmenu = true;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

+(NSString*) saveFilePath {
    if (_saveFilePath == nil) {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if ([paths count] == 0) {
            NSLog(@"CRITICAL ERROR: documents directory not found");
            return @"";
        }
        NSString* docsDir = [paths objectAtIndex:0];
        _saveFilePath = [[docsDir stringByAppendingPathComponent:SAVE_GAME_FILE] retain];
    }
    return _saveFilePath;
}

- (void)dealloc {
//    [window release];
    [oneLifeColor release];

    [super dealloc];
}


#pragma mark -
#pragma mark UIViewController Overrides

-(void)dismissModalViewControllerAnimated:(BOOL)animated {
    if (didStartByViewingInstructions) {
        [gameMan startGame];
    }
    [super dismissModalViewControllerAnimated:animated];
}


#pragma mark -
#pragma mark UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [gameMan resume];
    }
    else {
        UIAlertView* confirmAlert = [[UIAlertView alloc] initWithTitle:@"End Game?" message:@"Your score will not be considered for the high scores list." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"End Game", nil];
        [confirmAlert show];
        [confirmAlert release];
    }
    
    showingGameSubmenu = false;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [gameMan resume];
    }
    else {
        [gameMan endGame];
        JBAppController* appC = (JBAppController*)[[UIApplication sharedApplication] delegate];
        [appC dismissModalViewControllerAnimated:NO];
    }
}

#pragma mark -
#pragma mark Touch Events

-(void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    [gameMan touchEvent:event];
    
}

#pragma mark -
#pragma mark AdMob delegate

// Sent when an ad request loaded an ad.  This is a good opportunity to add this
// view to the hierarchy if it has not yet been added.  If the ad was received
// as a part of the server-side auto refreshing, you can examine the
// hasAutoRefreshed property of the view.
- (void)adViewDidReceiveAd:(GADBannerView *)view {
}

// Sent when an ad request failed.  Normally this is because no network
// connection was available or no ads were available (i.e. no fill).  If the
// error was received as a part of the server-side auto refreshing, you can
// examine the hasAutoRefreshed property of the view.
- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
}

// Sent just before presenting the user a full screen view, such as a browser,
// in response to clicking on an ad.  Use this opportunity to stop animations,
// time sensitive interactions, etc.
//
// Normally the user looks at the ad, dismisses it, and control returns to your
// application by calling adViewDidDismissScreen:.  However if the user hits the
// Home button or clicks on an App Store link your application will end.  On iOS
// 4.0+ the next method called will be applicationWillResignActive: of your
// UIViewController (UIApplicationWillResignActiveNotification).  Immediately
// after that adViewWillLeaveApplication: is called.
- (void)adViewWillPresentScreen:(GADBannerView *)bannerView {
    [self pauseGame];
}

// Sent just before dismissing a full screen view.
//- (void)adViewWillDismissScreen:(GADBannerView *)adView;

// Sent just after dismissing a full screen view.  Use this opportunity to
// restart anything you may have stopped as part of adViewWillPresentScreen:.
- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    [self resumeGame];
}


@end
