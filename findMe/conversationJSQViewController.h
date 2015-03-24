//
//  conversationJSQViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-03-05.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import "JSQMessagesViewController/JSQMessages.h"
#import "conversationModelData.h"

@class conversationJSQViewController;

@protocol conversationJSQViewControllerDelegate <NSObject>

- (void)didDismissJSQDemoViewController:(conversationJSQViewController *)vc;

@end




@interface conversationJSQViewController : JSQMessagesViewController<UIActionSheetDelegate>

@property (strong, atomic) conversationModelData *conversationData;
@property (weak, nonatomic) id<conversationJSQViewControllerDelegate> delegateModal;

- (void)receiveMessagePressed:(UIBarButtonItem *)sender;

- (void)closePressed:(UIBarButtonItem *)sender;
@end
