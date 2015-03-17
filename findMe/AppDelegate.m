//
//  AppDelegate.m
//  findMe
//
//  Created by Brian Allen on 2014-09-21.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "reachabilitySingleton.h"
#import <Parse/Parse.h>
#import "PNImports.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
   
    [Parse setApplicationId:@"XaleNqb8plMKReJIkuAwbokajOkcKo1RkOGdPUcN" clientKey:@"EqxiSF75OYaPQcOMYRR3K8yJursh6sbyHSLpldTT"];
    
    [PFUser enableAutomaticUser];
    
    
    PFACL *defaultACL = [PFACL ACL];
    
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    PFUser *currentUser = [PFUser currentUser];
    [currentUser save];
    
    //setup singleton for checking internet status
    [reachabilitySingleton sharedReachability];
    
    /* Instantiate PubNub */
    [PubNub setDelegate:self];
    
   
    
    
    //-- Set Notification
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        // iOS 8 Notifications
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        
        [application registerForRemoteNotifications];
    }
    else
    {
        // iOS < 8 Notifications
        [application registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
   
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    // Store the deviceToken in the current installation and save it to Parse.
    
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveInBackground];
    
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark pubnub delegate methods
//(In AppDelegate.m, define didReceiveMessage delegate method:)
- (void)pubnubClient:(PubNub *)client didReceiveMessage:(PNMessage *)message {
    NSLog( @"%@", [NSString stringWithFormat:@"received: %@", message.message] );
    NSLog(@"this fired from the app delegate zoinks");
    
    //check to see what view controller this is originating from
    
    NSMutableDictionary *pubMsgDict = [[NSMutableDictionary alloc] init];
    NSDictionary *msgIncomingDict = message.message;
    NSString *msgStringVal = [msgIncomingDict objectForKey:@"text"];
    
    
    NSDate *msgDate = (NSDate *)message.receiveDate.date;
    
    [pubMsgDict setObject:msgStringVal forKey:@"pubMsgString"];
    [pubMsgDict setObject:msgDate forKey:@"pubMsgDate"];
    
    //trigger an NSNotificationCenter notification that the other view controllers subscribe to with the message details
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PNMessage" object:self userInfo:[pubMsgDict copy]];
    
}

- (void)pubnubClient:(PubNub *)client didConnectToOrigin:(NSString *)origin {
    NSLog(@"DELEGATE: Connected to  origin: %@", origin);
    NSLog(@"brianconnected");
    
}

@end
