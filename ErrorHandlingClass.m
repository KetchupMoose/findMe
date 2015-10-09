//
//  ErrorHandlingClass.m
//  findMe
//
//  Created by Brian Allen on 10/6/15.
//  Copyright © 2015 Avial Ltd. All rights reserved.
//

#import "ErrorHandlingClass.h"

@implementation ErrorHandlingClass

+(BOOL) checkForErrors:(NSString *) returnedString errorCode:(NSString *)customErrorCode returnedError:(NSError *)error ParseUser:(PFUser *) parseUser MTLOBJ:(PFObject *) mtlObj;
{
    //[HUD hide:NO];
    
    NSString *parseUserID;
    NSString *mtlObjID;
    if(parseUser != nil)
    {
        parseUserID = parseUser.objectId;
    }
    else
    {
        parseUserID = @"NotAvailable";
    }
    if(mtlObj !=nil)
    {
        mtlObjID = mtlObj.objectId;
        
    }
    else
    {
        mtlObjID = @"NotAvailable";
    }

    
    if(error)
    {
        NSString *errorString = error.localizedDescription;
        NSLog(errorString);
        
        NSString *customErrorString = [@"Parse Error,Error Code: " stringByAppendingString:customErrorCode];
        
        
        
        customErrorString = [[[[customErrorString stringByAppendingString:@" WithParseUser: "] stringByAppendingString:parseUserID] stringByAppendingString:@" With MTLObject:"] stringByAppendingString:mtlObjID];
        
        
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Parse Error", nil) message:customErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        errorView.tag = 101;
        [errorView show];
        
        return NO;
    }
    if([returnedString containsString:@"BROADCAST"])
    {
        //show a ui alertview with the response text
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        [[[[specificErrorString stringByAppendingString:@" WithParseUser: "] stringByAppendingString:parseUserID] stringByAppendingString:@" With MTLObject:"] stringByAppendingString:mtlObjID];
        
        UIAlertView *b1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Broadcast Error", nil) message:specificErrorString delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        
        [b1 show];
        return NO;
    }
    
    if([returnedString containsString:@"ERROR"])
    {
        NSString *specificErrorString = [[returnedString stringByAppendingString:@"Backend Error, Error Source: "] stringByAppendingString:customErrorCode];
        [[[[specificErrorString stringByAppendingString:@" WithParseUser: "] stringByAppendingString:parseUserID] stringByAppendingString:@" With MTLObject:"] stringByAppendingString:mtlObjID];
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
