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
#import "RWTSwap.h"

static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface RWTMyScene ()

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *cookieLayer;
@property (strong, nonatomic) SKNode * tileslayer;

@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;
@property (strong, nonatomic) SKSpriteNode *selectionSprite;

@property (strong, nonatomic) SKAction *swapSound;
@property (strong, nonatomic) SKAction *invilidSwapSound;
@property (strong, nonatomic) SKAction *matchSound;
@property (strong, nonatomic) SKAction *fallingCookieSound;
@property (strong, nonatomic) SKAction *addCookieSound;

@end

@implementation RWTMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
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
        self.selectionSprite = [SKSpriteNode node];
        
        [self preloadResources];
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
            //highlight selected Cooike.
            [self showSelectionIndicatorForCooike:cookie];
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
            //hithlight selected Cooike.
            [self hideSelectonIndicator];
            //5
            self.swipeFromColumn = NSNotFound;
        }
        
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    self.swipeFromRow = self.swipeFromRow = NSNotFound;
    //hithlight selected Cooike.
    if (self.selectionSprite.parent != nil && self.swipeFromColumn != NSNotFound) {
        [self hideSelectonIndicator];
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [self touchesEnded:touches withEvent:event];
}

-(void)animateSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion{//?dispatch_block_t is a simply shorthand for a block that retuens void and takes no parameters.
    //put the cookie you started with on top.
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, [SKAction runBlock:completion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.cookieB.sprite runAction:moveB];
    //Sound
    [self runAction:self.swapSound];
}

-(void)animateInvalidSwap:(RWTSwap *)swap completion:(dispatch_block_t)completion{
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    [swap.cookieB.sprite runAction:[SKAction sequence:@[moveB,moveA]]];
    
    [self runAction:self.invilidSwapSound];
}

-(void)showSelectionIndicatorForCooike:(RWTCookie *)cooike{
    //if the selection indicator is still visible ,the first remove it.
    
    if (self.selectionSprite.parent != nil) {
        [self.selectionSprite removeFromParent];
    }
    
    SKTexture *texture = [SKTexture textureWithImageNamed:[cooike highlightedSpirteNale]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
     
     [cooike.sprite addChild:self.selectionSprite];
     self.selectionSprite.alpha = 1.0;
}

-(void)hideSelectonIndicator{
    [self.selectionSprite runAction:[SKAction sequence:@[
                                                         [SKAction fadeOutWithDuration:0.3],
                                                         [SKAction removeFromParent]]]];
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
    
    //NSLog(@"*** swapping %@ with %@",fromCooike,toCooike);
    
    if (self.swipeHandler != nil) {
        RWTSwap *swap = [[RWTSwap alloc] init];
        swap.cookieA = fromCooike;
        swap.cookieB = toCooike;
        
        self.swipeHandler(swap);
    }
}

-(void)preloadResources{
    self.swapSound = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invilidSwapSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingCookieSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addCookieSound = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
}

@end
