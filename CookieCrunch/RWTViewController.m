//
//  RWTViewController.m
//  CookieCrunch
//
//  Created by Windy on 14-5-27.
//  Copyright (c) 2014年 Razeware LLC. All rights reserved.
//

#import "RWTViewController.h"
#import "RWTMyScene.h"
#import "RWTLevel.h"
@import AVFoundation;


@interface RWTViewController ()

@property (strong, nonatomic) RWTLevel *level;
@property (strong, nonatomic) RWTMyScene *scence;
//score
@property (assign, nonatomic) NSUInteger movesLeft;
@property (assign, nonatomic) NSUInteger score;

@property (weak, nonatomic) IBOutlet UILabel *targetLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
//Game over
@property (weak, nonatomic) IBOutlet UIImageView *gameOverPanel;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
//
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;
//Play Musice
@property (strong, nonatomic) AVAudioPlayer *backgroundMusic;
@end

@implementation RWTViewController

-(void)beginGame{
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    [self.scence animateBeginGame];
    [self shuffle];
    [self.level resetComboMultiplier];
}


-(void)shuffle{
    [self.scence removeAllCookieSprites];
    NSSet *newCookies = [self.level shuffle];
    [self.scence addSpritesForCookies:newCookies];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    //Configure the view
    SKView *skview = (SKView *)self.view;
    skview.multipleTouchEnabled = NO;
    
    //Create and configure the scence
    self.scence = [RWTMyScene sceneWithSize:skview.bounds.size];
    self.scence.scaleMode = SKSceneScaleModeAspectFill;
    
    //load the level
    self.level = [[RWTLevel alloc] initWithFile:@"Level_1"];
    self.scence.level = self.level;
    [self.scence addTile];
    
    //set swap handler.
    id block = ^(RWTSwap *swap){
        
        self.view.userInteractionEnabled = NO;
        
        if ([self.level isPossibleSwap:swap]) {
            
            [self.level performSwap:swap];
            
            [self.scence animateSwap:swap completion:^{
                [self handleMatches];
            }];
            
        } else {
            [self.scence animateInvalidSwap:swap completion:^{
            self.view.userInteractionEnabled = YES;
            }];
            
        }
        
    };
    
    self.scence.swipeHandler = block;
    
    //Hidden "Game over"
    self.gameOverPanel.hidden = YES;
    
    //Present the scene
    [skview presentScene:self.scence];
    
    
    //
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Mining by Moonlight" withExtension:@"mp3"];
    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.backgroundMusic.numberOfLoops = -1;
    [self.backgroundMusic play];
    
    //Let us start the gane
    [self beginGame];
    
    
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
-(BOOL) prefersStatusBarHidden{
    return YES;
}

-(void)handleMatches {
    NSSet *chains = [self.level removeMatches];
    
    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    
    [self.scence animateMatchedCookies:chains completion:^{
        
        for (RWTChain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        
        NSArray *columns = [self.level fillHoles];
        [self.scence animateFallingCookies:columns completion:^{
            NSArray *columns = [self.level topUpCookies];
            [self.scence animateNewCookies:columns completion:^{
                //self.view.userInteractionEnabled = YES;
                [self handleMatches];
            }];
        }];
    }];
}

-(void)beginNextTurn {
    [self.level detectPossibleSwaps];
    self.view.userInteractionEnabled = YES;
    [self.level resetComboMultiplier];
    
    [self decrementMoves];
}

-(void)updateLabels {
    self.targetLabel.text = [NSString stringWithFormat:@"%lu", (long)self.level.targetScore];
    self.movesLabel.text = [NSString stringWithFormat:@"%lu", (long)self.movesLeft];
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)self.score];
}

-(void)decrementMoves{
    self.movesLeft--;
    [self updateLabels];
    
    if (self.score >= self.level.targetScore) {
        self.gameOverPanel.image = [UIImage imageNamed:@"LevelComplete"];
        [self showGameOver];
    } else if (self.movesLeft == 0) {
        self.gameOverPanel.image = [UIImage imageNamed:@"GameOver"];
        [self showGameOver];
    }
}

-(void)showGameOver {
    
    [self.scence animateGameOver];
    
    self.gameOverPanel.hidden = NO;
    self.scence.userInteractionEnabled = NO;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameOver)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    self.shuffleButton.hidden = YES;
}

-(void)hideGameOver {
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    self.gameOverPanel.hidden = YES;
    self.scence.userInteractionEnabled = YES;
    
    [self beginGame];
    self.shuffleButton.hidden = YES;
}

-(IBAction)shuffleButtonPressed:(id)sender {
    [self shuffle];
    [self decrementMoves];
}


@end
