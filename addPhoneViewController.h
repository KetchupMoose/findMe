//
//  addPhoneViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-09-02.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol addPhoneDelegate

-(void)confirmPhoneNumber:(id)sender;
@end


@interface addPhoneViewController : UIViewController

@property IBOutlet UIImageView *handHoldingPhoneImageView;
@property IBOutlet UIView *purpleBGView;
@property IBOutlet UIButton *addPhoneButton;
@property IBOutlet UIButton *skipButton;
@property IBOutlet UIButton *readThisButton;
@property IBOutlet UILabel *privacyExplanationLabel;
@property IBOutlet UILabel *moreInfoLabel;


-(IBAction)addPhone:(id)sender;
-(IBAction)skipButton:(id)sender;
-(IBAction)readThisButton:(id)sender;


@property (strong) NSString *phoneNumber;
@property (nonatomic, weak) id<addPhoneDelegate> delegate;

@property (strong) NSString *itsMTLID;

@end
