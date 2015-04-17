//
//  mapPinViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-04-12.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "mapPinViewController.h"
#import "myLocation.h"
#import "MBProgressHUD.h"
@interface mapPinViewController ()
#define METERS_PER_MILE 1609.344

@end

@implementation mapPinViewController
CLLocation *location;
BOOL shouldUpdateLocation = YES;
MBProgressHUD *HUD;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.mapView.delegate = self;
    
    // Create a gesture recognizer for long presses (for example in viewDidLoad)
    //UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    //lpgr.minimumPressDuration = 0.5; //user needs to press for half a second.
    //[self.mapView addGestureRecognizer:lpgr];
   
    
    //add a uiview to center of map
   /*
    CLLocationCoordinate2D center = self.mapView.centerCoordinate;
    location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
     MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = center;
    for (id annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    [self.mapView addAnnotation:point];
    */
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    CLLocationCoordinate2D center = self.mapView.centerCoordinate;
    location = [[CLLocation alloc] initWithLatitude:center.latitude longitude:center.longitude];
    
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = center;
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    for (id annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
        
    }
    
    point.title = @"userPoint";
    
    [self.mapView addAnnotation:point];

}
/*
- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = touchMapCoordinate;
    for (id annotation in self.mapView.annotations) {
        [self.mapView removeAnnotation:annotation];
    }
    [self.mapView addAnnotation:point];
}
*/
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
    if([self.priorLatitude length] >0)
        {
            shouldUpdateLocation = NO;
            self.mapView.showsUserLocation = NO;
            CLLocationCoordinate2D priorCoordinate;
            float priorLatitudeFloat = [self.priorLatitude floatValue];
            float priorLongitudeFloat = [self.priorLongitude floatValue];
            
            priorCoordinate.latitude = priorLatitudeFloat;
            priorCoordinate.longitude = priorLongitudeFloat;
            
            MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(priorCoordinate, 800, 800);
            [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
            
        }
    shouldUpdateLocation = YES;
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
   
    if(shouldUpdateLocation)
   {
       MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
       [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
       
       /*
       // Add an annotation
       MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
       point.coordinate = userLocation.coordinate;
       point.title = @"Where am I?";
       point.subtitle = @"I'm here!!!";
       
       [self.mapView addAnnotation:point];
    */
       shouldUpdateLocation = NO;
       self.mapView.showsUserLocation = NO;
       
   }
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MyLocation";
    if ([annotation isKindOfClass:[MyLocation class]]) {
        
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:@"arrest.png"];//here we use a nice image instead of the default pins
        } else {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    
    return nil;
}

-(void)setLocation:(id)sender
{
    //save the location that the annotation is set to
    
    HUD = [[MBProgressHUD alloc] init];
    HUD.labelText = @"Setting Location";
    [self.view addSubview:HUD];
    
    [HUD show:YES];
    
    float longitude = 0.0;
    float latitude = 0.0;
    
    for (MKPointAnnotation *annotation in self.mapView.annotations) {
        if((annotation.title = @"blah"))
        {
            
        
        NSLog(@"lon: %f, lat %f", ((MKPointAnnotation*)annotation).coordinate.longitude,((MKPointAnnotation*)annotation).coordinate.latitude);
        
        longitude =((MKPointAnnotation*)annotation).coordinate.longitude;
        latitude =((MKPointAnnotation*)annotation).coordinate.latitude;
        }
    }
    
    //send the longitude and latitude to the delegate
    [self.delegate setUserLocation:latitude withLongitude:longitude];
    
}

@end
