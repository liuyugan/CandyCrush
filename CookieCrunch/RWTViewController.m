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

@interface RWTViewController ()

@property (strong, nonatomic) RWTLevel *level;
@property (strong, nonatomic) RWTMyScene *scence;

@end

@implementation RWTViewController

-(void)beginGame{
    [self shuffle];
}


-(void)shuffle{
    NSSet *newCookies = [self.level shuffle];
    [self.scence addSpritesForCookies:newCookies];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    /*// Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    SKScene * scene = [RWTMyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];*/
    
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
    
    //Present the scene
    [skview presentScene:self.scence];
    
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
@end
