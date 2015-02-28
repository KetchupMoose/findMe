//
//  conversationsViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-02-27.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface conversationsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (strong,nonatomic) PFObject *conversationObject;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;
- (IBAction)sendChat:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *chatTextField;
@property (weak,nonatomic) IBOutlet UITableView *chatTableView;

@end
