//
//  privatelyViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-06-17.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface privatelyViewController : UIViewController<MKMapViewDelegate,CLLocationManagerDelegate>


@property (strong,nonatomic)  MKMapView *mapView;
@property MKCoordinateRegion myRegion;

@end
