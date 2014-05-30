//
//  RWTSwap.m
//  CookieCrunch
//
//  Created by Windy on 14-5-29.
//  Copyright (c) 2014年 Razeware LLC. All rights reserved.
//

#import "RWTSwap.h"
#import "RWTCookie.h"

@implementation RWTSwap
-(NSString *) description{
    return [NSString stringWithFormat:@"%@ swap %@ with %@",[super description],self.cookieA, self.cookieB];
}
-(BOOL)isEqual:(id)object{
    if (![object isKindOfClass:[RWTSwap class]]) {
        return NO;
    }
    
    RWTSwap *other = (RWTSwap *)object;
    return (other.cookieA == self.cookieA && other.cookieB == self.cookieB) ||
    (other.cookieB == self.cookieA && other.cookieA == self.cookieB);
}

-(NSUInteger)hash{
    return [self.cookieA hash] ^ [self.cookieB hash];//must import "RWTCookie.h"
}

@end
