//
//  addPhoneViewController.m
//  findMe
//
//  Created by Brian Allen on 2015-09-02.
//  Copyright (c) 2015 Avial Ltd. All rights reserved.
//

#import "addPhoneViewController.h"
#import <DigitsKit/DigitsKit.h>
#import "XMLWriter.h"
#import "MBProgressHUD.h"
#import "Parse/Parse.h"

@interface addPhoneViewController ()

@end

@implementation addPhoneViewController
MBProgressHUD *HUD;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //set fonts on labels
   self.privacyExplanationLabel.font = [UIFont fontWithName:@"ProximaNova-Light" size:27];
    
    self.skipButton.titleLabel.font = [UIFont fontWithName:@"ProximaNova-Bold" size:18];
    self.addPhoneButton.titleLabel.font =[UIFont fontWithName:@"ProximaNova-Bold" size:18];
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

-(IBAction)addPhone:(id)sender
{
    //show twitter fabric SDK
    [[Digits sharedInstance] authenticateWithCompletion:^
     (DGTSession* session, NSError *error) {
         if (session) {
             // Inspect session/error objects
             self.phoneNumber = session.phoneNumber;
             
             //upload the phone number to the server
             NSString *xmlForPhoneNumber = [self phoneUpdateXMLFunction:self.itsMTLID chosenPhoneNumber:self.phoneNumber];
             
             HUD = [[MBProgressHUD alloc] initWithView:self.view];
             [self.view addSubview:HUD];
             
             // Set determinate mode
             HUD.mode = MBProgressHUDModeDeterminate;
             HUD.delegate = self;
             HUD.labelText = @"Sending XML to Update Phone Number";
             [HUD show:YES];
             
             //use parse cloud code function to update with appropriate XML
             [PFCloud callFunctionInBackground:@"submitXML"
                                withParameters:@{@"payload": xmlForPhoneNumber}
                                         block:^(NSString *responseString, NSError *error) {
                                             
                                             BOOL errorCheck = [self checkForErrors:responseString errorCode:@"a2" returnedError:error];
                                             
                                             if(errorCheck)
                                             {
                                                [self.delegate confirmPhoneNumber:self];
                                             }
            }];
             
         }
         else
         {
             [self checkForErrors:@"" errorCode:@"a1" returnedError:error];
         }
     }];

}
-(IBAction)skipButton:(id)sender
{
    //dismiss the view controller, show something else
    [self.delegate confirmPhoneNumber:self];
    
    
    
}
-(IBAction)readThisButton:(id)sender
{
    //show something
    
}



-(NSString *)phoneUpdateXMLFunction:(NSString *)userName chosenPhoneNumber:(NSString *)phoneNumber
{
    //get the selected property from the chooser element.
    // allocate serializer
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    
    // add root element
    [xmlWriter writeStartElement:@"PAYLOAD"];
    
    // add element with an attribute and some some text
    [xmlWriter writeStartElement:@"USEROBJECTID"];
    [xmlWriter writeCharacters:userName];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"LAISO"];
    [xmlWriter writeCharacters:@"EN"];
    [xmlWriter writeEndElement];
    
    [xmlWriter writeStartElement:@"PREFERENCES"];
    
    [xmlWriter writeStartElement:@"CELLNUMBER"];
    [xmlWriter writeCharacters:phoneNumber];
    [xmlWriter writeEndElement];
    
    //close preferences element
    [xmlWriter writeEndElement];
    
    // close payload element
    [xmlWriter writeEndElement];
    
    // end document
    [xmlWriter writeEndDocument];
    
    NSString* xml = [xmlWriter toString];
    
    return xml;
    
}

//brian Sep5
-(BOOL) checkForErrors:(NSString *) returnedString errorCode:(NSString *)customErrorCode returnedError:(NSError *)error;
{

    if(error)
    {
        NSString *errorString = error.localizedDescription;
        NSLog(errorString);
        
        NSString *customErrorString = [@"Parse Error,Error Code: " stringByAppendingString:customErrorCode];
        
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Error", nil) message:customErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        errorView.tag = 101;
        [errorView show];
        
        return NO;
    }
    if([returnedString containsString:@"BROADCAST"])
    {
        //show a ui alertview with the response text
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        
        UIAlertView *b1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Broadcast Error", nil) message:specificErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [b1 show];
        return NO;
    }
    
    if([returnedString containsString:@"ERROR"])
    {
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        
        UIAlertView *b1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wait for Sync Error", nil) message:specificErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [b1 show];
        return NO;
        
        
    }
    else
    {
        return YES;
    }
    
}

@end
