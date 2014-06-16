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

//
@property (strong, nonatomic) SKCropNode *cropLayer;
@property (strong, nonatomic) SKNode *maskLayer;

@end

@implementation RWTMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        
        self.gameLayer = [SKNode node];
        self.gameLayer.hidden = YES;
        [self addChild:self.gameLayer];
        
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);
        
        // The tiles layer represents the shape of the level. It contains a sprite
        // node for each square that is filled in.
        self.tileslayer = [SKNode node];
        self.tileslayer.position = layerPosition;
        [self.gameLayer addChild:self.tileslayer];
        
        //Drawing Better Tiles
        self.cropLayer = [SKCropNode node];
        [self.gameLayer addChild:self.cropLayer];
        
        self.maskLayer = [SKNode node];
        self.maskLayer.position = layerPosition;
        self.cropLayer.maskNode = self.maskLayer;
        
        //
        self.cookieLayer = [SKNode node];
        self.cookieLayer.position = layerPosition;
        [self.cropLayer addChild:self.cookieLayer];
        
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
        
        //
        cookie.sprite.alpha = 0;
        cookie.sprite.xScale = cookie.sprite.yScale = 0.5;
        
        [cookie.sprite runAction:[SKAction sequence:@[
                                                      [SKAction waitForDuration:0.25 withRange:0.5],
                                                      [SKAction group:@[
                                                                        [SKAction fadeInWithDuration:0.25],
                                                                        [SKAction scaleTo:1.0 duration:0.25]
                                                                        ]]]]];
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
                //[self.tileslayer addChild:tileNode];
                [self.maskLayer addChild:tileNode];
            }
        }
    }
    
    
     for (NSInteger row = 0; row <= NumRows; row++) {
        for (NSInteger column = 0; column <= NumColumns; column++) {
            
            BOOL topLeft     = (column > 0) && (row < NumRows)
            && [self.level tileAtColumn:column - 1 row:row];
            
            BOOL bottomLeft  = (column > 0) && (row > 0)
            && [self.level tileAtColumn:column - 1 row:row - 1];
            
            BOOL topRight    = (column < NumColumns) && (row < NumRows)
            && [self.level tileAtColumn:column row:row];
            
            BOOL bottomRight = (column < NumColumns) && (row > 0)
            && [self.level tileAtColumn:column row:row - 1];
            
            // The tiles are named from 0 to 15, according to the bitmask that is
            // made by combining these four values.
            NSUInteger value = topLeft | topRight << 1 | bottomLeft << 2 | bottomRight << 3;
            
            // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
            if (value != 0 && value != 6 && value != 9) {
                NSString *name = [NSString stringWithFormat:@"Tile_%lu", (long)value];
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:name];
                CGPoint point = [self pointForColumn:column row:row];
                point.x -= TileWidth/2;
                point.y -= TileHeight/2;
                tileNode.position = point;
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
    //Score
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
}

- (void)animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion {
    
    for (RWTChain *chain in chains) {
        
        //Score
        [self animateScoreForChain:chain];
        
        for (RWTCookie *cookie in chain.cookies) {
            
            // 1
            /*The same RWTCookie could be part of two chains (one horizontal and one vertical), but you only want to add one animation to the sprite. This check ensures that you only animate the sprite once.*/
            if (cookie.sprite != nil) {
                
                // 2
                /*You put a scaling animation on the cookie sprite to shrink its size. When the animation is done, you remove the sprite from the cookie layer.*/
                SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                scaleAction.timingMode = SKActionTimingEaseOut;
                [cookie.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                
                // 3
                /*You remove the link between the RWTCookie and its sprite as soon as you’ve added the animation. This simple trick prevents the situation described in point 1.*/
                cookie.sprite = nil;
            }
        }
    }
    
    [self runAction:self.matchSound];
    
    // 4
    /*You only continue with the rest of the game after the animations finish.*/
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:0.3],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    // 1
    /*As with the other animation methods, you should only call the completion block after all the animations are finished. Because the number of falling cookies may vary, you can’t hardcode this total duration but instead have to compute it.*/
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        [array enumerateObjectsUsingBlock:^(RWTCookie *cookie, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            
            // 2
            /*The higher up the cookie is, the bigger the delay on the animation. That looks more dynamic than dropping all the cookies at the same time. This calculation works because fillHoles guarantees that lower cookies are first in the array.*/
            NSTimeInterval delay = 0.05 + 0.15*idx;
            
            // 3
            /*Likewise, the duration of the animation is based on how far the cookie has to fall (0.1 seconds per tile). You can tweak these numbers to change the feel of the animation.*/
            NSTimeInterval duration = ((cookie.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            
            // 4
            /*You calculate which animation is the longest. This is the time the game has to wait before it may continue.*/
            longestDuration = MAX(longestDuration, duration + delay);
            
            // 5 You perform the animation, which consists of a delay, a movement and a sound effect.
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            [cookie.sprite runAction:[SKAction sequence:@[
                                                          [SKAction waitForDuration:delay],
                                                          [SKAction group:@[moveAction, self.fallingCookieSound]]]]];
        }];
    }
    
    // 6 You wait until all the cookies have fallen down before allowing the gameplay to continue.
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    // This is very similar to the “falling cookies” animation.
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        
        
        NSInteger startRow = ((RWTCookie *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(RWTCookie *cookie, NSUInteger idx, BOOL *stop) {
            
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
            sprite.position = [self pointForColumn:cookie.column row:startRow];
            [self.cookieLayer addChild:sprite];
            cookie.sprite = sprite;
            
            NSTimeInterval delay = 0.1 + 0.2*([array count] - idx - 1);
            
            NSTimeInterval duration = (startRow - cookie.row) * 0.1;
            longestDuration = MAX(longestDuration, duration + delay);
            
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            cookie.sprite.alpha = 0;
            [cookie.sprite runAction:[SKAction sequence:@[
                                                          [SKAction waitForDuration:delay],
                                                          [SKAction group:@[
                                                                            [SKAction fadeInWithDuration:0.05], moveAction, self.addCookieSound]]]]];
        }];
    }

    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateScoreForChain:(RWTChain *)chain {
    // Figure out what the midpoint of the chain is.
    RWTCookie *firstCookie = [chain.cookies firstObject];
    RWTCookie *lastCookie = [chain.cookies lastObject];
    CGPoint centerPosition = CGPointMake(
                                         (firstCookie.sprite.position.x + lastCookie.sprite.position.x)/2,
                                         (firstCookie.sprite.position.y + lastCookie.sprite.position.y)/2 - 8);
    
    // Add a label for the score that slowly floats up.
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"+%lu", (long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self.cookieLayer addChild:scoreLabel];
    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 3) duration:0.7];
    moveAction.timingMode = SKActionTimingEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[
                                               moveAction,
                                               [SKAction removeFromParent]
                                               ]]];
}

- (void)animateGameOver {
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseIn;
    [self.gameLayer runAction:action];
}

- (void)animateBeginGame {
    self.gameLayer.hidden = NO;
    
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self.gameLayer runAction:action];
}

- (void)removeAllCookieSprites {
    [self.cookieLayer removeAllChildren];
}

@end
