//
//  RWTMyScene.h
//  CookieCrunch
//

//  Copyright (c) 2014年 Razeware LLC. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class RWTLevel;//?

@interface RWTMyScene : SKScene

@property (strong, nonatomic) RWTLevel *level;

-(void)addSpritesForCookies:(NSSet *)cookies;
-(void)addTile;

@end
