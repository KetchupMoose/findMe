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

@interface NewPropertyViewController : findMeBaseViewController <UITextFieldDelegate,UITableViewDataSource, UITableViewDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UITextViewDelegate>

-(IBAction)addAnswerToList:(id)sender;
-(IBAction)addNewProperty:(id)sender;

@property (strong,nonatomic) UITextView *questionTextView;


@property (weak,nonatomic) IBOutlet UITableView *answersListTableView;

@property (weak,nonatomic) IBOutlet UITextField *answerTextField;

@property (weak,nonatomic) IBOutlet UITextField *questionTextField;

@property (weak,nonatomic) IBOutlet UIImageView *checkMark1;
@property (weak,nonatomic) IBOutlet UIImageView *checkMark2;
@property (weak,nonatomic) IBOutlet UIImageView *checkMark3;
@property (weak,nonatomic) IBOutlet UILabel *step1Label;
@property (weak,nonatomic) IBOutlet UILabel *step2Label;
@property (weak,nonatomic) IBOutlet UILabel *step3Label;

@property (weak,nonatomic) NSString *userName;
@property (strong,nonatomic) NSString *newpropjsonObjectMode;
@property (strong,nonatomic) NSMutableDictionary *newpropjsonObject;
@property (nonatomic, weak) id<MyDataDelegate> delegate;
@property (strong,nonatomic) IBOutlet UICollectionView *recentQuestionsCollectionView;
@property (strong,nonatomic) NSArray *recentQuestions;

@property (strong,nonatomic) IBOutlet UIButton *confirmQuestionButton;
-(IBAction)confirmQuestion;

//label controls for the first step
@property (strong,nonatomic) UILabel *createQuestionLabel;
@property (strong,nonatomic) UILabel *recentQuestionsTitle;
@property (strong,nonatomic) NSMutableArray *hashtagButtons;

//label controls for second step
@property (strong,nonatomic) UILabel *addAnswersLabel;
@property (strong,nonatomic) UIButton *addAnswerButton;
@property (weak,nonatomic) IBOutlet UIButton *addNewAnswerButton;
@property (strong,nonatomic) IBOutlet UIButton *confirmAnswersButton;
-(IBAction)confirmAnswers:(id)sender;

//label controls for third step
@property (strong,nonatomic) UILabel *confirmAnswersLabel;
@property (weak,nonatomic) IBOutlet UIButton *addNewPropertyButton;


@property (strong,nonatomic) UILabel *firstStepLabel;
@property (strong,nonatomic) UILabel *secondStepLabel;
@property (strong,nonatomic) UILabel *thirdStepLabel;

@property (strong,nonatomic) UILabel *step1SideLabel;
@property (strong,nonatomic) UILabel *step2SideLabel;
@property (strong,nonatomic) UILabel *step3SideLabel;

@property (strong,nonatomic) NSString *editingMode;
@property (strong,nonatomic) NSNumber *editingCellNumber;
@property (strong,nonatomic) IBOutlet UIButton *editButton;
-(IBAction) editButton:(id)sender;



@end
