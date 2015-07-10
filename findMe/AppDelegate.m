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
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "PNImports.h"
#import "JSQMessagesViewController.h"
#import "conversationModelData.h"
#import "conversationJSQViewController.h"
#import "HomePageViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Fabric/Fabric.h>
#import <DigitsKit/DigitsKit.h>


//uncommented this "quick fix" someone had posted previously, seems the issue is resolved by making sure the project references the correct bolts SDK
//NSString *const BFTaskMultipleExceptionsException = @"BFMultipleExceptionsException";
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
   
    [Parse setApplicationId:@"XaleNqb8plMKReJIkuAwbokajOkcKo1RkOGdPUcN" clientKey:@"EqxiSF75OYaPQcOMYRR3K8yJursh6sbyHSLpldTT"];
    
    //[PFUser enableAutomaticUser];
    
    
    PFACL *defaultACL = [PFACL ACL];
    
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    [Fabric with:@[DigitsKit]];

    
    //PFUser *currentUser = [PFUser currentUser];
    //currentUser save];
    
    //setup singleton for checking internet status
    [reachabilitySingleton sharedReachability];
    
    /* Instantiate PubNub */
    [PubNub setDelegate:self];
    
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:nil];
    
    
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
    
    if (launchOptions != nil)
    
    {
        NSLog(@"Brian view on device log--launched from a push notification");
              
        
        // Launched from push notification
        NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        NSString *messageType = [userInfo objectForKey:@"messageType"];
              
        //handle responding to different kinds of notifications and showing different kinds of data
        
        if([messageType isEqualToString:@"message"])
        {
           
             NSLog(@"got message type");
            //get the conversation object
            NSString *conversationObj = [userInfo objectForKey:@"Conversation"];
            
            //open the chat view controller above the home screen view controller directly to this conversation object
            PFObject *conversationObject = [PFObject objectWithClassName:@"Conversations"];
            conversationObject.objectId = conversationObj;
            
            [conversationObject fetch];
               NSLog(@"fetched conversation object");
                UINavigationController *rootNC = (UINavigationController *)self.window.rootViewController;
                
            
                NSArray *conversationMembers = [conversationObject objectForKey:@"Members"];
                
              conversationModelData *cmData = [[conversationModelData alloc] initWithConversationObject:conversationObject arrayOfCaseUsers:conversationMembers];
            HomePageViewController *hmpgvc = rootNC.childViewControllers[0];
            hmpgvc.conversationData = cmData;
            
            conversationJSQViewController *cJSQvc = [rootNC.storyboard instantiateViewControllerWithIdentifier:@"convojsq"];
            
                cJSQvc.conversationData = cmData;
                [rootNC pushViewController:cJSQvc animated:YES];

           
        }
        else
        {
            //respond to some other kind of NSNotification
        }
    }
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //[PFPush handlePush:userInfo];
    
    if ( application.applicationState == UIApplicationStateActive )
    {
         // app was already in the foreground
        NSString *messageType = [userInfo objectForKey:@"messageType"];
        
        if([messageType isEqualToString:@"newMatch"])
        {
            //show new match popup
        }
        if([messageType isEqualToString:@"message"])
        {
            //do nothing, pubnub already handling
        }
        application.applicationIconBadgeNumber = 0;
    }
   
    else
    {
        // app was just brought from background to foreground
        [PFPush handlePush:userInfo];
        application.applicationIconBadgeNumber = 0;
    }
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
    
    [FBSDKAppEvents activateApp];
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
    NSString *thisChannel = [msgIncomingDict objectForKey:@"channel"];
    NSString *msgSenderCaseID = [msgIncomingDict objectForKey:@"msgSenderCaseID"];
    
    
    NSDate *msgDate = (NSDate *)message.receiveDate.date;
    
    [pubMsgDict setObject:msgStringVal forKey:@"pubMsgString"];
    [pubMsgDict setObject:msgDate forKey:@"pubMsgDate"];
    [pubMsgDict setObject:thisChannel forKey:@"pubChannel"];
    [pubMsgDict setObject:msgSenderCaseID forKey:@"pubMsgSender"];
    
    //trigger an NSNotificationCenter notification that the other view controllers subscribe to with the message details
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PNMessage" object:self userInfo:[pubMsgDict copy]];
    
}

- (void)pubnubClient:(PubNub *)client didConnectToOrigin:(NSString *)origin {
    NSLog(@"DELEGATE: Connected to  origin: %@", origin);
    NSLog(@"brianconnected");
    
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}




@end
