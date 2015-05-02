//
//  CarouselTestViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-05-01.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iCarousel.h"
@interface CarouselTestViewController : UIViewController<iCarouselDataSource, iCarouselDelegate>

@property (nonatomic, strong) IBOutlet iCarousel *carousel;

@end
