//
//  stanHomeViewController.h
//  findMe
//
//  Created by Brian Allen on 10/15/15.
//  Copyright © 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "findMeBottomTab.h"
#import <Parse/Parse.h>
#import "internetOfflineViewController.h"
#import "conversationModelData.h"
#import "MBProgressHUD.h"

@interface stanHomeViewController : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate,findMeBottomTabDelegate, MBProgressHUDDelegate>

@property (weak,nonatomic) IBOutlet MKMapView *mapView;
@property (weak,nonatomic) IBOutlet UIView *bottomBarContainer;
@property (weak,nonatomic) IBOutlet UIScrollView *templatesScrollView;

@property (strong,nonatomic) PFObject *HomePageITSMTLObject;
@property (strong,nonatomic) NSString *HomePageuserName;
@property (strong,nonatomic) PFUser *HomePageUser;


@property (strong,nonatomic) NSString *testUserString;
@property (strong,nonatomic ) NSArray *homePageCases;
@property (strong, atomic) conversationModelData *conversationData;
@property (weak, nonatomic) IBOutlet UILabel *connectedMTLLabel;
@property (strong,nonatomic) IBOutlet UIWebView *gifBG;
@property (strong,nonatomic) NSArray *designationProperties;
-(IBAction)showPrivatelyView:(id)sender;
@property CLLocationManager *locManager;
@property (strong,nonatomic) NSString *locationLatitude;
@property (strong,nonatomic) NSString *locationLongitude;

//properties dealing with retrieving HomePageTemplates
@property (strong,nonatomic) NSArray *allTemplates;
@property (strong,nonatomic) NSMutableArray *totalSetsOfParentTemplates;
@property (strong,nonatomic) NSMutableArray *parentTemplateCategories;
@property (strong,nonatomic) NSMutableArray *templatePickerActiveChoices;

@end
