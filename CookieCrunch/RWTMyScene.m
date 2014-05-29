//
//  RWTMyScene.m
//  CookieCrunch
//
//  Created by Windy on 14-5-27.
//  Copyright (c) 2014年 Razeware LLC. All rights reserved.
//

#import "RWTMyScene.h"
#import "RWTCookie.h"
#import "RWTLevel.h"

static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface RWTMyScene ()

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *cookieLayer;
@property (strong, nonatomic) SKNode * tileslayer;

@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;
@end

@implementation RWTMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        
        /*self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:@"Chalkduster"];
        
        myLabel.text = @"Hello, World!";
        myLabel.fontSize = 30;
        myLabel.position = CGPointMake(CGRectGetMidX(self.frame),
                                       CGRectGetMidY(self.frame));
        
        [self addChild:myLabel];*/
       
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        
        self.gameLayer = [SKNode node];
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        self.cookieLayer = [SKNode node];
        self.cookieLayer.position = layerPosition;
        
        //Add Tiles layer
        self.tileslayer = [SKNode node];
        self.tileslayer.position = layerPosition;
        
        [self.gameLayer addChild:self.tileslayer];
        [self.gameLayer addChild:self.cookieLayer];
        
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
    }
    return self;
}

-(void) addSpritesForCookies:(NSSet *)cookies{

    for (RWTCookie *cookie in cookies) {
        
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
        sprite.position = [self pointForColumn:cookie.column row:cookie.row];
        [self.cookieLayer addChild:sprite];
        cookie.sprite = sprite;
    }
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger) row{

    return CGPointMake(column* TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

-(BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row{
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    //Is this a vaild location within the cookies later?
    //If yes,calculate the corresponding row and column number.
    
    if (point.x>=0 && point.x< NumColumns*TileWidth &&
        point.y>=0 && point.y< NumRows*TileHeight) {
        *column = point.x / TileWidth;
        *row = point.y /TileHeight;
        return YES;
    } else  {
        *column = NSNotFound;
        *row = NSNotFound;
        return NO;
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

-(void)addTile{
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0 ; column < NumColumns; column++) {
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"Tile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.tileslayer addChild:tileNode];
            }
        }
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //1
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookieLayer];
    
    //2
    NSInteger column,row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        //3
        RWTCookie *cookie = [self.level cookieAtColumn:column row:row];
        if (cookie != nil) {
            //4
            self.swipeFromColumn = column;
            self.swipeFromRow = row;
        }
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    //1
    if (self.swipeFromColumn == NSNotFound) {
        return;
    }
    
    //2
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookieLayer];
    
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        //3
        NSInteger horzDelta = 0, vertDelta = 0;
        if (column < self.swipeFromColumn) {
            horzDelta = -1;//swipe left
        } else if (column > self.swipeFromColumn){
            horzDelta = 1;//swipe right
        } else if (row < self.swipeFromRow){
            vertDelta = -1;//swipe down
        } else if (row > self.swipeFromRow){
            vertDelta = 1;//swipe up
        }
        if (horzDelta != 0 || vertDelta != 0) {
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            
            //5
            self.swipeFromColumn = NSNotFound;
        }
        
    }
}

-(void)trySwapHorizontal:(NSInteger)horzDelta vertical:(NSInteger)verDelta{
    //1
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + verDelta;
    
    //2
    if (toColumn < 0 || toColumn >= NumColumns)   return;
    if (toRow < 0 || toRow >= NumRows)   return;

    //3
    RWTCookie *toCooike = [self.level cookieAtColumn:toColumn row:toRow];
    if (toCooike == nil) {
        return;
    }
    
    //4
    RWTCookie *fromCooike = [self.level cookieAtColumn:self.swipeFromColumn row:self.swipeFromRow];
    
    NSLog(@"*** swapping %@ with %@",fromCooike,toCooike);
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.swipeFromRow = self.swipeFromRow = NSNotFound;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [self touchesEnded:touches withEvent:event];
}


@end
