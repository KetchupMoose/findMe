//
//  reachabilitySingleton.h
//  findMe
//
//  Created by Brian Allen on 2015-03-04.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

@interface reachabilitySingleton : NSObject
{
    NSString *reachabilityNetworkStatus;
    Reachability *reacher;
}

@property (nonatomic, retain) NSString *reachabilityNetworkStatus;
@property (nonatomic, retain) Reachability *reacher;
+ (id)sharedReachability;

@end
