//
//  ErrorHandlingClass.h
//  findMe
//
//  Created by Brian Allen on 10/6/15.
//  Copyright © 2015 Avial Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
@interface ErrorHandlingClass : NSObject

+(BOOL) checkForErrors:(NSString *) returnedString errorCode:(NSString *)customErrorCode returnedError:(NSError *)error ParseUser:(PFUser *) parseUser MTLOBJ:(PFObject *) mtlObj;

@end
