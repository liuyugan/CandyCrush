//
//  RWTChain.h
//  CookieCrunch
//
//  Created by windy on 14-6-8.
//  Copyright (c) 2014年 Razeware LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RWTCookie;

typedef NS_ENUM(NSUInteger, ChainType) {
ChainTypeHorizontal,
ChainTypeVertical
};

@interface RWTChain : NSObject

@property(strong, nonatomic, readonly)NSArray *cookies;
@property(assign, nonatomic) ChainType chainType;
//score
@property (assign, nonatomic) NSUInteger score;

-(void)addCookie:(RWTCookie *)cookie;

@end
