//
//  caseDetailsCarouselViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-04-06.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iCarousel.h"
#import "NewPropertyViewController.h"
#import <Parse/Parse.h>
#import "popupViewController.h"
#import "mapPinViewController.h"
#import "CaseTitleSetViewController.h"
#import "SWTableViewCell.h"
@interface caseDetailsCarouselViewController : findMeBaseViewController <iCarouselDataSource, iCarouselDelegate,UITableViewDataSource, UITableViewDelegate,MyDataDelegate,CLLocationManagerDelegate,mapPinViewControllerDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate,CaseTitleSetViewControllerDelegate,SWTableViewCellDelegate>

-(IBAction)doUpdate:(id)sender;
@property (weak,nonatomic) IBOutlet UIButton *submitAnswersButton;
@property (weak,nonatomic) IBOutlet UIButton *locationButton;
-(IBAction)showLocationPicker:(id)sender;

@property (nonatomic, strong) IBOutlet iCarousel *carousel;
@property (weak,nonatomic) NSNumber *selectedCaseIndex;
@property (strong,nonatomic) PFObject *itsMTLObject;
@property (weak,nonatomic) NSString *userName;
@property (strong, nonatomic) CLLocationManager *locationManager;
-(void)reloadData:(PFObject *) newITSMTLObject;
@property (strong,nonatomic) popupViewController *popupVC;
@property (strong,nonatomic) NSString *slideoutDisplayed;
@property (strong,nonatomic) NSString *jsonDisplayMode;
@property (strong,nonatomic) NSMutableDictionary *jsonObject;

@property (strong,nonatomic) IBOutlet UITableView *propertiesTableView;
@property (strong,nonatomic) IBOutlet UITableView *matchesTableView;

@property (strong,nonatomic) NSString *manualLocationPropertyNum;
@property (strong,nonatomic) NSArray *designationProperties;
@property (weak,nonatomic) IBOutlet UIButton *viewMatchesButton;
-(IBAction)viewMatches:(id)sender;
@property (strong,nonatomic) IBOutlet UITextField *customAnswerTextField;
-(IBAction)customAnswerSet:(id)sender;
@property (strong,nonatomic) IBOutlet UIButton *customAnswerButton;

@property (strong,nonatomic) IBOutlet UILabel *customAnswerLabel;
@property (strong,nonatomic) IBOutlet UIImageView *customAnswerCheckmark;
@property MKCoordinateRegion setRegion;

@property (strong,nonatomic) IBOutlet UIButton *addCaseItemButton;
-(IBAction)addCaseItem:(id)sender;


@property (strong,nonatomic) NSString *internalCaseName;
@property (strong,nonatomic) NSString *externalCaseName;
@property (strong,nonatomic) UIImage *caseImage;

-(IBAction)updateCaseProfile;


@end
