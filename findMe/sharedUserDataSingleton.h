//
//  sharedUserDataSingleton.h
//  findMe
//
//  Created by Brian Allen on 2015-03-24.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface sharedUserDataSingleton : NSObject

@property (strong,nonatomic) NSString* activeMTLUser;

+ (id)sharedUserData;
-(void)setUserName:(NSString *)userName;
@end
