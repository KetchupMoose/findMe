//
//  CaseDetailsEmailViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-01-26.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>
#import "NewPropertyViewController.h"
#import <Parse/Parse.h>
#import "popupViewController.h"
#import "SWTableViewCell.h"
#import "findMeBaseViewController.h"

@interface CaseDetailsEmailViewController : findMeBaseViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,MBProgressHUDDelegate,UIAlertViewDelegate,CLLocationManagerDelegate,UpdateCaseItemDelegate,MyDataDelegate,SWTableViewCellDelegate>

@property (weak,nonatomic) IBOutlet UITableView *caseDetailsEmailTableView;

-(IBAction)doUpdate:(id)sender;

@property (weak,nonatomic) IBOutlet UIButton *submitAnswersButton;
@property (weak,nonatomic) NSNumber *selectedCaseIndex;
@property (strong,nonatomic) PFObject *itsMTLObject;
@property (weak,nonatomic) NSString *userName;
@property (strong, nonatomic) CLLocationManager *locationManager;
-(void)reloadData:(PFObject *) newITSMTLObject;
@property (strong,nonatomic) popupViewController *popupVC;
@property (strong,nonatomic) NSString *slideoutDisplayed;
@property (strong,nonatomic) NSString *jsonDisplayMode;
@property (strong,nonatomic) NSMutableDictionary *jsonObject;

@end
