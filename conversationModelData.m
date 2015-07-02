//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "conversationModelData.h"
#import "AppDelegate.h"
//#import "NSUserDefaults+DemoSettings.h"


@implementation conversationModelData

NSArray *conversationMessagesArray;
NSArray *conversationMembersArray;

- (instancetype)init:(PFObject *) conversationObject
{
    self = [super init];
    if (self) {
        
            [self QueryForMessages];
            [self loadAvatars];
        
            [self loadMessages];
        
        /**
         *  Create message bubble images objects.
         *
         *  Be sure to create your bubble images one time and reuse them for good performance.
         *
         */
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    }
    
    return self;
}

-(conversationModelData*)initWithConversationObject:(PFObject*)conversationObj userName:(NSString*)convoUserName
{
    NSLog(@"doing init");
    //NSLog(convoUserName);
    
    self = [super init];
    self.conversationObject = conversationObj;
    self.conversationCaseUserName = convoUserName;
    
    [self QueryForMessages];
    [self loadAvatars];
    
    [self loadMessages];
    
    /**
     *  Create message bubble images objects.
     *
     *  Be sure to create your bubble images one time and reuse them for good performance.
     *
     */
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    return self;
    
}

-(conversationModelData*)initWithConversationObject:(PFObject*)conversationObj arrayOfCaseUsers:(NSArray*)caseUserArray
{
     self = [super init];
    
    
    
    NSLog(@"doing init with array of users");
    NSLog(@"%lu",(unsigned long)caseUserArray.count);
    
   
    //need to query for the caseObjects within the message's caseUserArray and then query up to their parse users to find the matching caseID
    PFQuery *query = [PFQuery queryWithClassName:@"Cases"];
    [query whereKey:@"objectId" containedIn:caseUserArray];
    [query includeKey:@"ownerObjectid.ParseUser"];
    
    conversationMembersArray =  [query findObjects];
        NSLog(@"object count:@%lu",(unsigned long)conversationMembersArray.count);
        for(PFObject *caseObj in conversationMembersArray)
        {
            PFObject *mtlObj = [caseObj objectForKey:@"ownerObjectid"];
            PFUser *parentUser = [mtlObj objectForKey:@"ParseUser"];
            PFUser *ownUser = [PFUser currentUser];
            //NSLog(parentUser.objectId);
           // NSLog(ownUser.objectId);
            
             if([parentUser.objectId isEqualToString:ownUser.objectId])
             {
             self.conversationCaseUserName = caseObj.objectId;
                 NSLog(@"got a match");
                 
             }
            else
            {
                NSLog(@"did  not match");
            }
             
        }
        //self.conversationCaseUserName = @"fIcrScUrxq";
        self.conversationObject = conversationObj;
         
         
         [self QueryForMessages];
         [self loadAvatars];
         
         [self loadMessages];
         
         /**
          *  Create message bubble images objects.
          *
          *  Be sure to create your bubble images one time and reuse them for good performance.
          *
          */
         JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
         
         self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
         self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    
    return self;
    
}

-(void)QueryForMessages
{
    conversationMessagesArray = [[NSArray alloc] init];
    
    PFQuery *query = [PFQuery queryWithClassName:@"conversationMessages"];
    [query whereKey:@"Conversation" equalTo:self.conversationObject];
    [query orderByDescending:@"updatedAt"];
    
    conversationMessagesArray = [query findObjects];
    
}

-(void) loadAvatars
{
    //get the images for the avatars
    
    /*NSMutableArray *userNamesInConversation = [[NSMutableArray alloc] init];
    
    for(PFObject *msgObject in conversationMessagesArray)
    {
        //get mtlID
        NSString *msgSenderID = [msgObject objectForKey:@"messageCaseUserID"];
        
        //if array doesn't include this already, add it.
        if(![userNamesInConversation containsObject:msgSenderID])
        {
            [userNamesInConversation addObject:msgSenderID];
        }
    }
    
    if([userNamesInConversation count] ==0)
    {
        //nothing to add yet for avatar images or avatar user names
        return;
    }
     */
    NSMutableArray *userNamesInConversation = [[NSMutableArray alloc] init];
    
    for(PFObject *object in conversationMembersArray)
    {
        NSString *convoMemberID = object.objectId;
        if(![userNamesInConversation containsObject:convoMemberID])
        {
            [userNamesInConversation addObject:convoMemberID];
        }
    }
    //query for the itsMTLObjects of these users to get their pictures
    PFQuery *query = [PFQuery queryWithClassName:@"Cases"];
    [query whereKey:@"objectId" containedIn:userNamesInConversation];
    
    NSArray *objects =  [query findObjects];
        //set the profile picture data
        
        NSMutableArray *avatarImages = [[NSMutableArray alloc] init];
        NSMutableArray *avatarUserIDs = [[NSMutableArray alloc] init];
        NSMutableArray *avatarNames = [[NSMutableArray alloc] init];
        for(PFObject *caseObject in objects)
        {
            //get the image
            NSString *imgURL = [caseObject objectForKey:@"caseImgURL"];
            NSString *caseID = caseObject.objectId;
            NSString *avatarName = [caseObject objectForKey:@"caseShowName"];
            
            if([avatarName length ]==0)
            {
                avatarName = @"Default Name";
            }
            
            if([imgURL length] ==0)
            {
                imgURL = @"http://icons.iconarchive.com/icons/hopstarter/face-avatars/256/Male-Face-M4-icon.png";
            }
            NSURL *imageURL = [NSURL URLWithString:imgURL];
            
            NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
            
            UIImage *avatarImage = [UIImage imageWithData:imageData];
                  
            JSQMessagesAvatarImage *userImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:avatarImage
                                                                                                   diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
            [avatarImages addObject:userImage];
            [avatarUserIDs addObject:caseID];
            [avatarNames addObject:avatarName];
                    
           }
            //
            self.avatars =[NSDictionary dictionaryWithObjects:avatarImages
                                                 forKeys:avatarUserIDs];
            
            self.users = [NSDictionary dictionaryWithObjects:avatarNames
                                                  forKeys:avatarUserIDs];
        
        
        
        /*
        self.avatars = @{ kJSQDemoAvatarIdSquires : jsqImage,
                          kJSQDemoAvatarIdCook : cookImage,
                          kJSQDemoAvatarIdJobs : jobsImage,
                          kJSQDemoAvatarIdWoz : wozImage };
        
        
        self.users = @{ kJSQDemoAvatarIdJobs : kJSQDemoAvatarDisplayNameJobs,
                        kJSQDemoAvatarIdCook : kJSQDemoAvatarDisplayNameCook,
                        kJSQDemoAvatarIdWoz : kJSQDemoAvatarDisplayNameWoz,
                        kJSQDemoAvatarIdSquires : kJSQDemoAvatarDisplayNameSquires };
         */
   

    
}

- (void)loadMessages
{
    /**
     *  Load some fake messages for demo.
     *
     *  You should have a mutable array or orderedSet, or something.
     */
    
    NSMutableArray *JSQMessages = [[NSMutableArray alloc] init];
    int j = 0;
    
    if([conversationMessagesArray count]==0)
    {
        JSQMessage *jsqMsgObject = [[JSQMessage alloc] initWithSenderId:@"FindMe"
                                                      senderDisplayName:@"FindMeApp"
                                                                   date:[NSDate date]
                                                                   text:@"Message Your Match Here!"];
        [JSQMessages addObject:jsqMsgObject];

    }
    else
    {
        NSSortDescriptor* sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:YES];
        
        NSMutableArray *sortedConversationMessages = [[NSMutableArray alloc] init];
        sortedConversationMessages = [conversationMessagesArray mutableCopy];
        
       [sortedConversationMessages sortUsingDescriptors:[NSArray arrayWithObject:sortByDate]];
    
    for(PFObject *msgObject in sortedConversationMessages)
                                   {
                                       NSString *msgSenderID = [msgObject objectForKey:@"messageCaseUserID"];
                                       NSLog(@"checking sender id");
                                       
                                       //NSLog(msgSenderID);
                                       
                                       NSString *msgText = [msgObject objectForKey:@"MessageString"];
                                       NSDate *msgDate = msgObject.updatedAt;
                                       
                                       NSString *showName = [self.users objectForKey:msgSenderID];
                                       
                                       JSQMessage *jsqMsgObject = [[JSQMessage alloc] initWithSenderId:msgSenderID
                                                          senderDisplayName:showName
                                                                       date:msgDate
                                                                       text:msgText];
                                       [JSQMessages addObject:jsqMsgObject];
                                       
                                       j = j+1;
                                   }
        }
    self.messages = JSQMessages;
    
    //adding one add photo media message as an example
    //[self addPhotoMediaMessage];
    
}

- (void)addPhotoMediaMessage
{
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"stockphotowoman1.jpg"]];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                   displayName:kJSQDemoAvatarDisplayNameSquires
                                                         media:photoItem];
    [self.messages addObject:photoMessage];
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
    
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
    
    JSQMessage *locationMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                      displayName:kJSQDemoAvatarDisplayNameSquires
                                                            media:locationItem];
    [self.messages addObject:locationMessage];
}

- (void)addVideoMediaMessage
{
    // don't have a real video, just pretending
    NSURL *videoURL = [NSURL URLWithString:@"file://"];
    
    JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
    JSQMessage *videoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                   displayName:kJSQDemoAvatarDisplayNameSquires
                                                         media:videoItem];
    [self.messages addObject:videoMessage];
}

@end
