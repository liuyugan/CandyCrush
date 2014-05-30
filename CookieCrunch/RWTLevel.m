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
    for (NSInteger i = row +1; i < NumRows && _cookies[i][row].cookieType == cookieType; i++,vertLength++) ;
    
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
        
        //loop thriugh the rows
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop){
            
            //loop through the columns in current row
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                
                //NOTE: In SPrite Kit (0,0) is at the bottom of the screen, so we need to read thjis file upside down.
                NSInteger tileRow = NumRows - row -1;
                
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[RWTTile alloc] init];
                }
            }];
        }];
         
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

@end
