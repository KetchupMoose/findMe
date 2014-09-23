//
//  ParseJSONCommunicatorDelegate.h
//  findMe
//
//  Created by Brian Allen on 2014-09-22.
//  Copyright (c) 2014 Avial Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ParseJSONCommunicatorDelegate <NSObject>
- (void)receivedParseJSON:(NSData *)objectNotation;
- (void)fetchingParseJSONFailedWithError:(NSError *)error;
@end
