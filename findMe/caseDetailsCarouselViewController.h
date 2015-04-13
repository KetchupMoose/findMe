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

@interface caseDetailsCarouselViewController : UIViewController <iCarouselDataSource, iCarouselDelegate,UITableViewDataSource, UITableViewDelegate,MyDataDelegate>

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


@end
