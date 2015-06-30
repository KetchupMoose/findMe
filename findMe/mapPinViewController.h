//
//  mapPinViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-04-12.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol mapPinViewControllerDelegate

- (void)setUserLocation:(float) latitude withLongitude:(float)longitude andRegion:(MKCoordinateRegion) region;

@end

@interface mapPinViewController : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate>

@property (weak,nonatomic) IBOutlet MKMapView *mapView;
@property (weak,nonatomic) IBOutlet UIButton *setLocation;
-(IBAction)setLocation:(id)sender;
@property (nonatomic, weak) id<mapPinViewControllerDelegate> delegate;
@property (strong,nonatomic) NSNumber *priorLatitude;
@property (strong,nonatomic) NSNumber *priorLongitude;
@property MKCoordinateRegion myRegion;
@property (strong,nonatomic) NSString *regionSet;

@property (strong,nonatomic) UIImageView *pinImageView;
@end
