//
//  newCaseViewControllerv2.m
//  findMe
//
//  Created by Brian Allen on 2015-06-29.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "newCaseViewControllerv2.h"
#import <Parse/Parse.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImageView+UIActivityIndicatorForSDWebImage.h"
#import "UIImageView+Scaling.h"
#import "UIView+Animation.h"
#import "XMLWriter.h"
#import "MBProgressHUD.h"
#import "CaseDetailsViewController.h"
#import "CaseDetailsEmailViewController.h"
#import "BaseCaseDetailsSlidingViewController.h"
#import "caseDetailsCarouselViewController.h"
#import "caseTitleSetViewController.h"

@interface newCaseViewControllerv2 ()

@end

@implementation newCaseViewControllerv2
NSArray *CaseOptionImages;
NSArray *templatePickerChoices;
NSMutableArray *templatePickerParentChoicesMostPopular;
NSMutableArray *templatePickerParentChoicesSecondTier;

NSMutableArray *templatePickerActiveChoices;
int pickedParentTemplateIndex;

NSString *selectedTemplate1;
NSString *selectedTemplate2;

NSNumber *previousTemplateTimestamp;
PFObject *queryReturnPFObject;


MBProgressHUD *HUD;

//location manager variables

CLGeocoder *geocoder;
CLPlacemark *placemark;
NSString *locationRetrieved;
NSString *locationLatitude;
NSString *locationLongitude;

@synthesize CaseOptionsCollectionView;
@synthesize TemplateSecondLevelTableView;
@synthesize itsMTLObject;
@synthesize locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //location manager instance variable allocs
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
    locationManager.delegate = self;
    
    //populate the URL's of images from parse.
    [self queryForTemplates];
    
    CaseOptionsCollectionView.dataSource = self;
    CaseOptionsCollectionView.delegate = self;
    
    self.secondCaseOptionsCollectionView.dataSource = self;
    self.secondCaseOptionsCollectionView.delegate = self;
    
    self.navigationItem.title = @"New Case";
    
    [CaseOptionsCollectionView reloadData];
    [self.secondCaseOptionsCollectionView reloadData];
    
    [self getLocation:self];
    
    /*
     NSString *filePath = [[NSBundle mainBundle] pathForResource:@"womangif2" ofType:@"gif"];
     NSData *gif = [NSData dataWithContentsOfFile:filePath];
     
     [self.gifView loadData:gif MIMEType:@"image/gif" textEncodingName:nil baseURL:nil];
     self.gifView.userInteractionEnabled = NO;
     */
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void) queryForTemplates
{
    //retrieve the five parent templatePickerChoices from Parse
    //templatePickerChoices =
    PFQuery *templateQuery = [PFQuery queryWithClassName:@"Templates"];
    //[templateQuery selectKeys:@[@"parenttemplateid"]];
    
    
    [templateQuery whereKey:@"laiso" equalTo:@"EN"];
    
    templatePickerChoices = [templateQuery findObjects];
    
    templatePickerParentChoicesMostPopular = [[NSMutableArray alloc] init];
      templatePickerParentChoicesSecondTier = [[NSMutableArray alloc] init];
    templatePickerActiveChoices = [[NSMutableArray alloc] init];
    
    for(PFObject *templateObject in templatePickerChoices)
    {
        NSLog(@"numberofKeys");
        NSLog(@"%lu",(unsigned long)templateObject.allKeys.count);
        
        PFObject *theParentObj = [templateObject objectForKey:@"parenttemplateid"];
        
        /*
         NSString *objID = [templateObject valueForKey:@"parentemplateid"];
         
         if(objID==Nil)
         {
         objID = @"no";
         
         }
         else
         {
         objID = @"yes";
         
         }
         */
        
        if([theParentObj isEqual:[NSNull null]])
        {
            //check the designation
            NSString *category = [templateObject objectForKey:@"category"];
            if([category isEqualToString:@"Most Popular"])
            {
                 [templatePickerParentChoicesMostPopular addObject:templateObject];
            }
            else
            {
                [templatePickerParentChoicesSecondTier addObject:templateObject];
                
            }
            
        }
    }
    
}


- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    if(collectionView.tag==1)
    {
        return templatePickerParentChoicesMostPopular.count;
    }
    else
    {
        return templatePickerParentChoicesSecondTier.count;
    }
    
    
}



- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"newCaseCell";
    NSArray *sourceArray;
    if(collectionView.tag==1)
    {
        sourceArray = templatePickerParentChoicesMostPopular;
    }
    if(collectionView.tag==2)
    {
        sourceArray = templatePickerParentChoicesSecondTier;
        
    }
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *caseImageView= (UIImageView *)[cell viewWithTag:1];
    
    //check to see if a button is already created, if not, create a button overlayed on top of the UIImageView.  This button when tapped will activate the next step for the index of its displayed template.
    
    PFObject *templateObject = [sourceArray objectAtIndex:indexPath.row];
    
    NSString *imgURL = [templateObject objectForKey:@"imageURL"];
    UIActivityIndicatorViewStyle activityStyle = UIActivityIndicatorViewStyleGray;
    
    
    [caseImageView setImageWithURL:[NSURL URLWithString:imgURL] usingActivityIndicatorStyle:(UIActivityIndicatorViewStyle)activityStyle];
    
    UILabel *descrLabel = (UILabel *) [cell viewWithTag:2];
    
    descrLabel.text = [templateObject objectForKey:@"description"];
    
    descrLabel.font = [UIFont fontWithName:@"Futura-Medium" size:12];
    
    
    //caseImageView.image = [UIImage imageNamed:[recipeImages objectAtIndex:indexPath.row]];
    
    return cell;
}
-(void)getLocation:(id)sender
{
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    //show progress HUD
    /*
     HUD.mode = MBProgressHUDModeDeterminate;
     HUD.delegate = self;
     HUD.labelText = @"Retrieving Location Data";
     [HUD show:YES];
     */
    
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    
    [locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        //longitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        //latitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
        
        
        locationLongitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        locationLatitude =[NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
    
    // Stop Location Manager
    [locationManager stopUpdatingLocation];
    
    // Reverse Geocoding
    NSLog(@"Resolving the Address");
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        // NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            
            NSString *locationText =[NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                     placemark.subThoroughfare, placemark.thoroughfare,
                                     placemark.postalCode, placemark.locality,
                                     placemark.administrativeArea,
                                     placemark.country];
            locationRetrieved = placemark.locality;
            
            //[HUD hide:YES];
        } else {
            NSLog(@"%@", error.debugDescription);
            
            //[HUD hide:YES];
        }
    } ];
    
}


@end
