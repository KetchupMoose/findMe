//
//  sharedUserDataSingleton.m
//  findMe
//
//  Created by Brian Allen on 2015-03-24.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "sharedUserDataSingleton.h"
#import "AppDelegate.h"

@implementation sharedUserDataSingleton
@synthesize activeMTLUser;
+ (id)sharedUserData {
    static sharedUserDataSingleton *sharedUserData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUserData = [[self alloc] init];
        
        
    });
    
    return sharedUserData;
}

- (id)initWithUserName:(NSString *)userName {
    if (self = [super init]) {
        activeMTLUser = userName;
        
    }
    return self;
}

-(void)setUserName:(NSString *)userName
{
    activeMTLUser = userName;
    
}





@end
