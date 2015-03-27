//
//  findMeBaseViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-03-24.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "findMeBaseViewController.h"
#import "AppDelegate.h"
#import "JSQSystemSoundPlayer+JSQMessages.h"
#import "UIView+Animation.h"
#import "sharedUserDataSingleton.h"
#import "messageIdentifierButton.h"
#import "conversationJSQViewController.h"
#import "conversationModelData.h"
#import <Parse/Parse.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"

@interface findMeBaseViewController ()

@end

@implementation findMeBaseViewController
BOOL notifierLoaded;

@synthesize BaseViewControllerUserName;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //[self loadBaseViewControllerElements];
    }


-(void)loadBaseViewControllerElements
{
    //[self setPubNubConfigDetails];
    [self setUpNotificationChannels];
    notifierLoaded = YES;
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    [self setUpNotificationChannels];
    
}

-(void) viewDidDisappear:(BOOL)animated
{
    //remove notification channels
    [super viewDidDisappear:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PNMessage" object:nil];
    //notifierLoaded = NO;
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) setUserValueFromSingleton
{
    sharedUserDataSingleton *sharedU = [sharedUserDataSingleton sharedUserData];
    self.BaseViewControllerUserName = sharedU.activeMTLUser;
    
}

-(void) setUpNotificationChannels {
   //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"PNMessage" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivePNMessage:)
                                                 name:@"PNMessage"
                                               object:nil];
    
}

//remove observer self when view controller loses focus



-(void)receivePNMessage:(NSNotification *) notification
{
    
    [self setUserValueFromSingleton];
    
    NSString *message = [notification.userInfo objectForKey:@"pubMsgString"];
    PNDate *msgDate = [notification.userInfo objectForKey:@"pubMsgDate"];
    NSString *conversationObjID = [notification.userInfo objectForKey:@"pubChannel"];
    NSString *senderCaseID = [notification.userInfo objectForKey:@"pubMsgSender"];
    
    
    NSLog( @"%@", [NSString stringWithFormat:@"received on find me base: %@", message] );
    
    //add a new JSQMessage to the local messages array
    NSString *userNameString = self.BaseViewControllerUserName;
    
    if([senderCaseID containsString:userNameString])
    {
        //this is a message sent by this user, don't add it to the list of messages beacuse it has already been added
        NSLog(@"message received but is from the user");
        
    }
    else
    {
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        
        //show a UIView saying there is a message received
        [self displayMessageReceivedUIView:notification];
        
    }
    
}

-(void) displayMessageReceivedUIView:(NSNotification *) notification
{
    NSString *message = [notification.userInfo objectForKey:@"pubMsgString"];
    PNDate *msgDate = [notification.userInfo objectForKey:@"pubMsgDate"];
    NSString *conversationObjID = [notification.userInfo objectForKey:@"pubChannel"];
    NSString *senderCaseID = [notification.userInfo objectForKey:@"pubMsgSender"];
    
    //query for the user profile image and display name in background, then display the view information
    
    PFQuery *caseQuery = [PFQuery queryWithClassName:@"Cases"];
    [caseQuery whereKey:@"objectId" equalTo:senderCaseID];
   
    [caseQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //set up view information
        NSString *caseUserName = [object objectForKey:@"caseShowName"];
        NSString *caseProfileImgURL = [object objectForKey:@"caseImgURL"];
        
        if([caseUserName length] ==0)
        {
            caseUserName = @"DefaultUserName";
        }
        if([caseProfileImgURL length] ==0)
        {
            caseProfileImgURL = @"http://www.carascravings.com/wp-content/uploads/2012/07/profile-photo-220x183.jpg";
        }
        
        messageIdentifierButton *messageReceivedView = [[messageIdentifierButton alloc] initWithFrame:CGRectMake(0,50,200,95)];
        [messageReceivedView addTarget:self action:@selector(popMessageReceivedView:) forControlEvents:UIControlEventTouchUpInside];
        
        messageReceivedView.msgNotification = notification;
        
        messageReceivedView.backgroundColor = [UIColor whiteColor];
        
        messageReceivedView.layer.cornerRadius = 5.0f;
        
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(70,2,100,75)];
        
        
        messageLabel.text = message;
        messageLabel.numberOfLines = 5;
        
        messageLabel.font = [UIFont italicSystemFontOfSize:12];
        
        messageLabel.textAlignment = NSTextAlignmentCenter;
        //messageLabel.textAlignment = NSTextAlignmentJustified;
        
        [messageReceivedView addSubview:messageLabel];
        
        UIImageView *senderImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5,10,60,60)];
        senderImageView.layer.cornerRadius = senderImageView.frame.size.height /2;
        senderImageView.layer.masksToBounds = YES;
        senderImageView.layer.borderWidth = 0;
        //senderImageView.image = [UIImage imageNamed:@"carselfie1.jpg"];
        
        UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
        
        [senderImageView setImageWithURL:[NSURL URLWithString:caseProfileImgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
        
        [messageReceivedView addSubview:senderImageView];
        
        UILabel *senderNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(5,65,120,30)];
        senderNameLabel.text = caseUserName;
        senderNameLabel.minimumScaleFactor = 0.5;
        senderNameLabel.adjustsFontSizeToFitWidth = YES;
        
        [messageReceivedView addSubview:senderNameLabel];
        
        UIPanGestureRecognizer *msgButtonPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(msgButtonPanDetected:)];
        
        [messageReceivedView addGestureRecognizer:msgButtonPanRecognizer];
        
        [self.view SlideFromRightWithBounceBack:messageReceivedView containerView:self.view duration:0.3 option:UIViewAnimationOptionCurveEaseOut];
        
        
      
    }];
    
   
    
}


-(void)popMessageReceivedView:(id)sender
{
    messageIdentifierButton *messageReceivedView = (messageIdentifierButton *) sender;
    UIView *parentView = messageReceivedView.superview;
    
    //get the conversation object from the notification and bring up that conversation object
    NSString *message = [messageReceivedView.msgNotification.userInfo objectForKey:@"pubMsgString"];
    PNDate *msgDate = [messageReceivedView.msgNotification.userInfo objectForKey:@"pubMsgDate"];
    NSString *conversationObjID = [messageReceivedView.msgNotification.userInfo objectForKey:@"pubChannel"];
    NSString *senderCaseID = [messageReceivedView.msgNotification.userInfo objectForKey:@"pubMsgSender"];
    
    //fetch the conversation object
   
    PFQuery *getSingleConversationObjQuery = [PFQuery queryWithClassName:@"Conversations"];
    
    [getSingleConversationObjQuery whereKey:@"objectId" equalTo:conversationObjID];
    PFObject *conversationObj = [getSingleConversationObjQuery getFirstObject];
    
    //get the members of the object
    [messageReceivedView removeFromSuperview];
        
    NSArray *conversationMembers = [conversationObj objectForKey:@"Members"];
    conversationJSQViewController *cJSQvc = [self.storyboard instantiateViewControllerWithIdentifier:@"convojsq"];
    conversationModelData *cmData = [[conversationModelData alloc] initWithConversationObject:conversationObj arrayOfCaseUsers:conversationMembers];
    cJSQvc.conversationData = cmData;
    [self.navigationController pushViewController:cJSQvc animated:YES];
    
}

- (void)msgButtonPanDetected:(UIPanGestureRecognizer *)panRecognizer
{

    CGPoint translation = [panRecognizer translationInView:self.view];
    //CGPoint labelViewPosition = self.msgButton.center;
    
    messageIdentifierButton *msgButton = (messageIdentifierButton *)panRecognizer.view;
    
    CGPoint originalOrigin= msgButton.frame.origin;
   
    
    CGRect newLabelFrame =  CGRectMake(msgButton.frame.origin.x +translation.x,msgButton.frame.origin.y,msgButton.frame.size.width,msgButton.frame.size.height);
    
    msgButton.frame = newLabelFrame;
    
    [panRecognizer setTranslation:CGPointZero inView:self.view];
    
    //if the difference is less than 50 pixels from the original x position of the view, play an animation to "snap it back" to its original position.
    
    if(translation.x<=15)
    {
        [msgButton moveTo:originalOrigin duration:0.2 option:UIViewAnimationOptionCurveEaseInOut];
        
        
    }
    else
    {
       //remove by sliding off to right
        [msgButton SlideOffRight:msgButton duration:0.3];
        
        //[msgButton removeFromSuperview];
        
        
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
