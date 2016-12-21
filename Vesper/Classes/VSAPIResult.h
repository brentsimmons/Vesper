//
//  VSAPIResult.h
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


extern NSString *VSServerDateNotification;
extern NSString *VSServerDateKey;


@interface VSAPIResult : NSObject


@property (nonatomic, readonly) NSURLRequest *request;
@property (nonatomic, readonly) NSURLResponse *response;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) id JSONObject;
@property (nonatomic, readonly) NSError *JSONError; /*Error creating JSON from returned data.*/
@property (nonatomic, readonly) NSString *responseSyncToken;
@property (nonatomic, readonly) NSDate *responseServerDate;
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) NSString *resultString;

@property (nonatomic) id parsedObject;
@property (nonatomic, assign) BOOL succeeded;


+ (VSAPIResult *)resultWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error;


@end
