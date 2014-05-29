//
//  RWTLevel.h
//  CookieCrunch
//
//  Created by Windy on 14-5-28.
//  Copyright (c) 2014年 Razeware LLC. All rights reserved.
//

#import "RWTCookie.h"
#import "RWTTile.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface RWTLevel : NSObject
-(NSSet *)shuffle;
-(RWTCookie *) cookieAtColumn:(NSInteger)column row:(NSInteger)row;
-(instancetype)initWithFile:(NSString *)filename;
-(RWTTile *)tileAtColumn:(NSInteger)column row:(NSInteger)row;
@end
