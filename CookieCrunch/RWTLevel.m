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
    return [self createInitialCookies];
}

-(NSSet *)createInitialCookies{
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row=0; row < NumRows; row++) {
        
        for (NSInteger column = 0; column < NumColumns; column++) {
            
            /*NSInteger cookieType = arc4random_uniform(NumCookieTypes) + 1;
            
            RWTCookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
            
            [set addObject:cookie];*/
            if (_tiles[column][row] != nil) {
                NSInteger cookieType = arc4random_uniform(NumCookieTypes) + 1;
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

@end
