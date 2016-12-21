//
//  VSAPIResult.m
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSAPIResult.h"
#import "QSDateParser.h"


NSString *VSServerDateNotification = @"VSServerDateNotification";
NSString *VSServerDateKey = @"date";


@interface VSAPIResult ()

@property (nonatomic, readwrite) NSURLRequest *request;
@property (nonatomic, readwrite) NSURLResponse *response;
@property (nonatomic, readwrite) NSError *error;
@property (nonatomic, readwrite) id JSONObject;
@property (nonatomic, readwrite) NSError *JSONError;
@property (nonatomic, readwrite) NSDate *responseServerDate;
@property (nonatomic, assign, readwrite) NSInteger statusCode;
@property (nonatomic, readwrite) NSData *data;
@property (nonatomic, readwrite) NSString *resultString;

@end


@implementation VSAPIResult


#pragma mark - Class Methods

+ (VSAPIResult *)resultWithRequest:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data error:(NSError *)error {

	VSAPIResult *result = [VSAPIResult new];

	result.request = request;
	result.response = response;
	result.error = error;
	result.statusCode = [(NSHTTPURLResponse *)response statusCode];
	result.data = data;

	if (error == nil && result.statusCode < 400) {
		result.succeeded = YES;
	}

	if ([response respondsToSelector:@selector(allHeaderFields)]) {

		NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
		NSString *dateString = headers[@"Date"];

		if (dateString) {
			NSDate *serverDate = QSDateWithString(dateString);

			/*Sanity-check the date before sending notification.*/

			NSDateComponents *dateComponents = [[NSCalendar autoupdatingCurrentCalendar] components:NSCalendarUnitYear fromDate:serverDate];
			if ([dateComponents year] >= 2014 && [dateComponents year] < 2017) {
				[[NSNotificationCenter defaultCenter] postNotificationName:VSServerDateNotification object:nil userInfo:@{VSServerDateKey : serverDate}];
			}
		}
	}

	return result;
}


#pragma mark - Accessors

- (id)JSONObject {

	if (_JSONObject == nil) {
		
		if (!QSIsEmpty(self.data)) {
			NSError *error = nil;
			_JSONObject = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&error];
			self.JSONError = error;
		}
	}

	return _JSONObject;
}


- (NSString *)resultString {

	if (_resultString == nil) {
		_resultString = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
	}

	return _resultString;
}


- (NSString *)responseSyncToken {

	return [(NSHTTPURLResponse *)self.response allHeaderFields][@"x-vesper-synctoken"];
}

@end
