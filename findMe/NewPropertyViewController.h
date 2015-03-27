//
//  NewPropertyViewController.h
//  findMe
//
//  Created by Brian Allen on 2014-10-11.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "findMeBaseViewController.h"
@protocol MyDataDelegate

- (void)recieveData:(NSString *)OptionsList AcceptableAnswersList:(NSArray *)Answers QuestionText:(NSString *) question;

@end

@interface NewPropertyViewController : findMeBaseViewController <UITextFieldDelegate,UITableViewDataSource, UITableViewDelegate>

-(IBAction)addAnswerToList:(id)sender;
-(IBAction)addNewProperty:(id)sender;
@property (weak,nonatomic) IBOutlet UIButton *addNewPropertyButton;

@property (weak,nonatomic) IBOutlet UITableView *answersListTableView;

@property (weak,nonatomic) IBOutlet UITextField *answerTextField;

@property (weak,nonatomic) IBOutlet UITextField *questionTextField;

@property (weak,nonatomic) IBOutlet UIImageView *checkMark1;
@property (weak,nonatomic) IBOutlet UIImageView *checkMark2;
@property (weak,nonatomic) IBOutlet UIImageView *checkMark3;

@property (weak,nonatomic) NSString *userName;
@property (strong,nonatomic) NSString *newpropjsonObjectMode;
@property (strong,nonatomic) NSMutableDictionary *newpropjsonObject;
@property (nonatomic, weak) id<MyDataDelegate> delegate;

@end
