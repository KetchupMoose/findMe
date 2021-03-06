//
//  popupViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-01-26.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "MBProgressHUD.h"


@protocol UpdateCaseItemDelegate

//The popup sends back data to the CaseDetailsEmailViewController in these ways:
//1)The popup sends back an array of answers which are just indexes
//2)The popup sends back an array of answers, some indexes, some custom
//3)The popup sends back an array of answers and a new property
- (void)updateCaseItem:(NSString *)caseItemID AcceptableAnswersList:(NSArray *)Answers;
- (void)updateCaseItem:(NSString *)caseItemID AcceptableAnswersList:(NSArray *)Answers NewPropertyDescr:(NSString *) newPropDescr optionsList:(NSArray *) optionList;
- (void)reloadData:(PFObject *) myObject reloadMode:(NSString *)reloadModeString;

@end

@interface popupViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,MBProgressHUDDelegate>


@property (weak, nonatomic) IBOutlet UIView *testView;
@property (weak, nonatomic) IBOutlet UITableView *answersTableView;

@property (weak,nonatomic) IBOutlet UIButton *updateButton;

-(IBAction)closePopup:(id)sender;
-(IBAction)updateAnswers:(id)sender;


@property (weak,nonatomic) PFObject *popupitsMTLObject;
@property (weak,nonatomic) NSString *popupUserName;
@property (weak,nonatomic) NSNumber *selectedCase;
@property (weak,nonatomic) NSNumber *selectedCaseItem;
@property (weak,nonatomic) PFObject *selectedPropertyObject;
@property (weak,nonatomic) NSString *displayMode;
@property (strong,nonatomic) NSString *popupjsonDisplayMode;
@property (strong,nonatomic) NSMutableDictionary *popupjsonObject;
@property (weak,nonatomic) NSArray *sortedCaseItems;
@property (weak,nonatomic) NSArray *originalTemplateOptionsCounts;

@property (weak,nonatomic) IBOutlet UITextField *customAnswerTextField;

@property (weak,nonatomic) id<UpdateCaseItemDelegate> UCIdelegate;

@property (weak,nonatomic) NSString *locationRetrieved;
@property (weak,nonatomic) NSString *locationLatitude;
@property (weak,nonatomic) NSString *locationLongitude;
@property (weak,nonatomic) NSString *popupOrSlideout;

@property (strong,nonatomic) NSMutableArray *popupanswersDictionary;

@end
