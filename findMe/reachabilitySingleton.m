//
//  reachabilitySingleton.m
//  findMe
//
//  Created by Brian Allen on 2015-03-04.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "reachabilitySingleton.h"
#import "Reachability.h"

@implementation reachabilitySingleton
@synthesize reachabilityNetworkStatus;
@synthesize reacher;

#pragma mark Singleton Methods

+ (id)sharedReachability {
    static reachabilitySingleton *sharedReachabilitySingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReachabilitySingleton = [[self alloc] init];
    });
    return sharedReachabilitySingleton;
}

- (id)init {
    if (self = [super init]) {
        reachabilityNetworkStatus = @"Default Property Value";
        [self setupReachability];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

-(void)setupReachability
{
    // Allocate a reachability object
    reacher = [Reachability reachabilityWithHostname:@"api.parse.com"];
    
    // Set the blocks
    reacher.reachableBlock = ^(Reachability*reacher)
    {
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"REACHABLE!");
        });
    };
    
    reacher.unreachableBlock = ^(Reachability*reacher)
    {
        NSLog(@"UNREACHABLE!");
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reacher startNotifier];
}


@end
