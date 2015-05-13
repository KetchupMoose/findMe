//
//  CaseTitleSetViewController.h
//  findMe
//
//  Created by Brian Allen on 2015-05-13.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GKImagePicker.h"


@protocol CaseTitleSetViewControllerDelegate
-(void)dismissCaseTitleSetViewController:(NSString *)internalCaseName withExt:(NSString *)externalCaseName withImg:(UIImage *)caseImage;

@end

@interface CaseTitleSetViewController : UIViewController <UITextFieldDelegate,GKImagePickerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *internalCaseNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *externalCaseNameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *caseImageView;
@property (strong) GKImagePicker *imagePicker;
-(IBAction)MakeCase:(id)sender;
@property (weak,nonatomic) id<CaseTitleSetViewControllerDelegate> delegate;
-(IBAction)setPhoto:(id)sender;
+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;


@end
