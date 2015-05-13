//
//  CaseTitleSetViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-05-13.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "CaseTitleSetViewController.h"

@interface CaseTitleSetViewController ()

@end

@implementation CaseTitleSetViewController
NSString *internalNameString;
NSString *externalNameString;
UIImage *selectedCaseImage;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

-(IBAction)MakeCase:(id)sender
{
    //save the case data and pass it on to the caseDetailsCarouselViewController
   // self.cdcvc.caseImage = selectedCaseImage;
   // self.cdcvc.externalCaseName = externalNameString;
    //self.cdcvc.internalCaseName = internalNameString;
    
    //remove this view controller
    [self.delegate dismissCaseTitleSetViewController:internalNameString withExt:externalNameString withImg:selectedCaseImage];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    int animatedDistance;
    int moveUpValue = textField.frame.origin.y+ textField.frame.size.height;
    UIInterfaceOrientation orientation =
    [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        
        animatedDistance = 216-(460-moveUpValue-5);
    }
    else
    {
        animatedDistance = 162-(320-moveUpValue-5);
    }
    
    if(animatedDistance>0)
    {
        const int movementDistance = animatedDistance;
        const float movementDuration = 0.3f;
        int movement = (up ? -movementDistance : movementDistance);
        [UIView beginAnimations: nil context: nil];
        [UIView setAnimationBeginsFromCurrentState: YES];
        [UIView setAnimationDuration: movementDuration];
        self.view.frame = CGRectOffset(self.view.frame, 0, movement);
        [UIView commitAnimations];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //put the string of the text field onto a label now in the same cell
    //put -100 so it doesn't interfere with the uilabel tag of 3 in every cell
    if(textField.tag == 8)
    {
        internalNameString = textField.text;
    }
    else
    if(textField.tag ==9)
    {
        externalNameString = textField.text;
        
    }
    
    [textField resignFirstResponder];
    
    return YES;
}

-(void)dismissKeyboard {
    
    [self.view endEditing:YES];
}

-(IBAction)setPhoto:(id)sender
{
    self.imagePicker = [[GKImagePicker alloc] init];
    self.imagePicker.cropSize = CGSizeMake(300, 300);
    
    [self.imagePicker.imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    self.imagePicker.delegate = self;
    
    [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
}
+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image
{
    //UIImage *scaledImage = [self imageWithImage:image scaledToSize:CGSizeMake(150, 150)];
    self.caseImageView.image = image;
    
    //NSLog(@"view %f %f, image %f %f", self.currentCardView.cardImage.frame.size.width, self.currentCardView.cardImage.frame.size.height, image.size.width, image.size.height);
    
    /*[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         imageUploadView.alpha = 0;
                     }
                     completion:^(BOOL completed){
                         [imageUploadView removeFromSuperview];
                     }];
     */
    
    //[self.imageView setImage:image];
    //[self dismissViewControllerAnimated:YES completion:nil];
    [imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}


@end
