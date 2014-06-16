//
//  RWTLevel.m
//  CookieCrunch
//
//  Created by Windy on 14-5-28.
//  Copyright (c) 2014年 Razeware LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RWTLevel.h"
#import "RWTTile.h"

@interface RWTLevel ()
@property (strong, nonatomic) NSSet *possibleSwaps;
@property (assign, nonatomic) NSUInteger comboMultiplier;

@end

@implementation RWTLevel

RWTCookie *_cookies[NumColumns][NumRows];
RWTTile *_tiles[NumColumns][NumRows];


-(RWTCookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row{
    
    NSAssert1(column >=0 && column < NumColumns,@"Invalid column %ld",(long)column);
    NSAssert1(row >=0 && row < NumRows,@"Invalid row: %ld",(long)row);
    
    return _cookies[column][row];
}

-(RWTCookie *)createCookieAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSUInteger)cookieType{
    
    RWTCookie *cookie = [[RWTCookie alloc]init];
    cookie.cookieType = cookieType;
    cookie.column = column;
    cookie.row = row;
    
    _cookies[column][row] = cookie;
    
    return cookie;
}

-(NSSet *)shuffle{
    //return [self createInitialCookies];
    NSSet *set;
    do{
        set = [self createInitialCookies];
        [self detectPossibleSwaps];
        NSLog(@"possible swaps: %@",self.possibleSwaps);
    }
    while ([self.possibleSwaps count] == 0);
    
    return set;
}

-(BOOL)hasChainAtColumn:(NSInteger)column row:(NSInteger)row{
    NSUInteger cookieType = _cookies[column][row].cookieType;
    
    NSUInteger horzLength = 1;
    for (NSInteger i = column -1; i >= 0 && _cookies[i][row].cookieType == cookieType; i--,horzLength++) ;
    for (NSInteger i = column +1; i < NumColumns && _cookies[i][row].cookieType == cookieType; i++,horzLength++) ;
    if (horzLength >=3) {
        return YES;
    }
    
    NSUInteger vertLength = 1;
    for (NSInteger i = row -1; i >= 0 && _cookies[column][i].cookieType == cookieType; i--,vertLength++) ;
    for (NSInteger i = row +1; i < NumRows && _cookies[column][i].cookieType == cookieType; i++,vertLength++) ;
    
    return vertLength >= 3;
}

-(void)detectPossibleSwaps{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            RWTCookie *cookie = _cookies[column][row];
            if (cookie != nil) {
                
                //Detect logic.
                if (column < NumColumns -1) {
                    RWTCookie *other = _cookies[column+1][row];
                    
                    if (other != nil) {
                        //Swap them
                        _cookies[column][row] = other;
                        _cookies[column+1][row] = cookie;
                        
                        if ([self hasChainAtColumn:column+1 row:row] ||
                             [self hasChainAtColumn:column row:row]) {
                            RWTSwap *swap = [[RWTSwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        //Swap them back
                        _cookies[column][row] = cookie;
                        _cookies[column+1][row] = other;
                        
                    }
                }
                
                
                if (row < NumRows -1) {
                    RWTCookie *other = _cookies[column][row +1];
                    
                    if (other != nil) {
                        //Swap them
                        _cookies[column][row] = other;
                        _cookies[column][row +1] = cookie;
                        
                        if ([self hasChainAtColumn:column row:row + 1] ||
                            [self hasChainAtColumn:column row:row]) {
                            RWTSwap *swap = [[RWTSwap alloc]init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        //Swap them back
                        _cookies[column][row] = cookie;
                        _cookies[column][row +1] = other;
                    }
                }
            }
        }
    }
    self.possibleSwaps = set;
}

-(NSSet *)createInitialCookies{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row=0; row < NumRows; row++) {
        
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            /*NSInteger cookieType = arc4random_uniform(NumCookieTypes) + 1;
            
            RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
            
            [set addObject:cookie];*/
            if (_tiles[column][row] != nil) {
                //NSInteger cookieType = arc4random_uniform(NumCookieTypes) + 1;
                NSUInteger cookieType;
                do{
                    cookieType = arc4random_uniform(NumCookieTypes) + 1;
                }
                while ((column >=2 &&
                        _cookies[column -1][row].cookieType == cookieType &&
                        _cookies[column -2][row].cookieType == cookieType)
                        ||
                        (row >=2 &&
                        _cookies[column][row -1].cookieType == cookieType &&
                        _cookies[column][row -2].cookieType == cookieType));
                        //At here loop will do nothing and continue.
                RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                [set addObject:cookie];
            }
        }
        
    }
    return set;
}

-(NSDictionary *)loadJSON:(NSString *)filename{
    //NSBundle mainBundle pathForResource 中的文件可以在 Bulid Phases 中查看。
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if (path == nil) {
        NSLog(@"Could not find level file: %@",filename);
        return nil;
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];//? &?, how to use NSData.
    if (data == nil) {
        NSLog(@"Could not laod level file: %@, error: %@", filename, error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {//?nil NIL and null
        NSLog(@"Level file '%@' is not valid JOSN: %@",filename, error);
        return nil;
    }
    
    return dictionary;
}

-(instancetype)initWithFile:(NSString *)filename{
    self = [super init];
    
    if (self != nil) {
        NSDictionary *dictionary = [self loadJSON:filename];
        
        //loop through the rows
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop){
            
            //loop through the columns in current row
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                
                //NOTE: In SPrite Kit (0,0) is at the bottom of the screen, so we need to read this file upside down.
                NSInteger tileRow = NumRows - row -1;
                
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[RWTTile alloc] init];
                }
            }];
        }];
        
        //Score
        self.targetScore = [dictionary[@"targetScore"] unsignedIntegerValue];
        self.maximumMoves = [dictionary[@"moves"] unsignedIntegerValue];
    }
    return self;
}

-(RWTTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row{
    NSAssert1(column >=0 && column < NumColumns, @"Invalid column: %ld", (long)column);
    NSAssert1(row >=0 && row<NumRows, @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

-(void)performSwap:(RWTSwap *)swap{
    NSInteger columnA = swap.cookieA.column;
    NSInteger rowA = swap.cookieA.row;
    NSInteger columnB = swap.cookieB.column;
    NSInteger rowB = swap.cookieB.row;
    
    _cookies[columnA][rowA] = swap.cookieB;
    swap.cookieB.column = columnA;
    swap.cookieB.row = rowA;
    
    _cookies[columnB][rowB] = swap.cookieA;
    swap.cookieA.column = columnB;
    swap.cookieA.row = rowB;

}

-(BOOL)isPossibleSwap:(RWTSwap *)swap{
    return [self.possibleSwaps containsObject:swap];
}

- (NSSet *)detectHorizontalMatches {
    // 1
    /*You create a new set to hold the horizontal chains (RWTChain objects). Later, you’ll remove the cookies in these chains from the playing field.*/
    NSMutableSet *set = [NSMutableSet set];
    
    // 2
    /*You loop through the rows and columns. Note that you don’t need to look at the last two columns because these cookies can never begin a new chain. Also notice that the inner for loop does not increment its loop counter; the incrementing happens conditionally inside the loop body.*/
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns - 2; ) {
            
            // 3
            /*You skip over any gaps in the level design.*/
            if (_cookies[column][row] != nil) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                // 4
                /*You check whether the next two columns have the same cookie type. Normally you have to be careful not to step outside the bounds of the array when doing something like _cookies[column + 2][row], but here that can’t go wrong. That’s why the for loop only goes up to NumColumns - 2*/
                if (_cookies[column + 1][row].cookieType == matchType
                    && _cookies[column + 2][row].cookieType == matchType) {
                    // 5
                    /*At this point, there is a chain of at least three cookies but potentially there are more. This steps through all the matching cookies until it finds a cookie that breaks the chain or it reaches the end of the grid. Then it adds all the matching cookies to a new RWTChain object. You increment column for each match*/
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        column += 1;
                    }
                    while (column < NumColumns && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            
            // 6
            /*If the next two cookies don’t match the current one or if there is an empty tile, then there is no chain, so you skip over the cookie.*/
            column += 1;
        }
    }
    return set;
}

- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows - 2; ) {
            if (_cookies[column][row] != nil) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                if (_cookies[column][row + 1].cookieType == matchType
                    && _cookies[column][row + 2].cookieType == matchType) {
                    
                    RWTChain *chain = [[RWTChain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        row += 1;
                    }
                    while (row < NumRows && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            row += 1;
        }
    }
    return set;
}

- (NSSet *)removeMatches {
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    //NSLog(@"Horizontal matches: %@", horizontalChains);
    //NSLog(@"Vertical matches: %@", verticalChains);
    [self removeCookies:horizontalChains];
    [self removeCookies:verticalChains];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
    
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

- (void)removeCookies:(NSSet *)chains {
    for (RWTChain *chain in chains) {
        for (RWTCookie *cookie in chain.cookies) {
            _cookies[cookie.column][cookie.row] = nil;
        }
    }
}


/*Here is how it all works, step by step:
 1.You loop through the rows, from bottom to top.
 2.If there’s a tile at a position but no cookie, then there’s a hole. Remember that the _tiles array describes the shape of the level.
 3.You scan upward to find the cookie that sits directly above the hole. Note that the hole may be bigger than one square (for example, if this was a vertical chain) and that there may be holes in the grid shape, as well.
 4.If you find another cookie, move that cookie to the hole. This effectively moves the cookie down.
 5.You add the cookie to the array. Each column gets its own array and cookies that are lower on the screen are first in the array. It’s important to keep this order intact, so the animation code can apply the correct delay. The farther up the piece is, the bigger the delay before the animation starts.
 6.Once you’ve found a cookie, you don’t need to scan up any farther so you break out of the inner loop.*/

- (NSArray *)fillHoles {
    NSMutableArray *columns = [NSMutableArray array];
    
    // 1
    for (NSInteger column = 0; column < NumColumns; column++) {
        
        NSMutableArray *array;
        for (NSInteger row = 0; row < NumRows; row++) {
            
            // 2
            if (_tiles[column][row] != nil && _cookies[column][row] == nil) {
                
                // 3
                for (NSInteger lookup = row + 1; lookup < NumRows; lookup++) {
                    RWTCookie *cookie = _cookies[column][lookup];
                    if (cookie != nil) {
                        // 4
                        _cookies[column][lookup] = nil;
                        _cookies[column][row] = cookie;
                        cookie.row = row;
                        
                        // 5
                        if (array == nil) {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:cookie];
                        
                        // 6
                        break;
                    }
                }
            }
        }
    }
    return columns;
}

- (NSArray *)topUpCookies {
    NSMutableArray *columns = [NSMutableArray array];
    
    NSUInteger cookieType = 0;
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        
        NSMutableArray *array;
        
        // 1 You loop through the column from top to bottom. This for loop ends when _cookies[column][row] is not nil—that is, when it has found a cookie.
        for (NSInteger row = NumRows - 1; row >= 0 && _cookies[column][row] == nil; row--) {
            
            // 2 You ignore gaps in the level, because you only need to fill up grid squares that have a tile.
            if (_tiles[column][row] != nil) {
                
                // 3 You randomly create a new cookie type. It can’t be equal to the type of the last new cookie, to prevent too many “freebie” matches.
                NSUInteger newCookieType;
                do {
                    newCookieType = arc4random_uniform(NumCookieTypes) + 1;
                } while (newCookieType == cookieType);
                cookieType = newCookieType;
                
                // 4 You create the new RWTCookie object. This uses the createCookieAtColumn:row:withType: method that you added in Part One.
                RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                
                // 5 You add the cookie to the array for this column. You’re lazily creating the arrays, so the allocation only happens if a column has holes.
                if (array == nil) {
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                [array addObject:cookie];
            }
        }
    }
    return columns;
}

- (void)calculateScores:(NSSet *)chains {
    for (RWTChain *chain in chains) {
        chain.score = 60 * ([chain.cookies count] - 2) * self.comboMultiplier;
        self.comboMultiplier++;
    }
}

- (void)resetComboMultiplier {
    self.comboMultiplier = 1;
}

@end
