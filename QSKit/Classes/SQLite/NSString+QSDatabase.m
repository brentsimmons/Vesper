//
//  NSString+QSDatabase.m
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/23/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "NSString+QSDatabase.h"


@implementation NSString (QSDatabase)


+ (NSString *)qs_SQLValueListWithPlaceholders:(NSUInteger)numberOfValues {

	/*@"(?, ?, ?)"*/

	NSParameterAssert(numberOfValues > 0);
	if (numberOfValues < 1) {
		return nil;
	}

	NSMutableString *s = [[NSMutableString alloc] initWithString:@"("];
	NSUInteger i = 0;

	for (i = 0; i < numberOfValues; i++) {

		[s appendString:@"?"];
		BOOL isLast = (i == (numberOfValues - 1));
		if (!isLast) {
			[s appendString:@", "];
		}
	}

	[s appendString:@")"];
	
	return [s copy];
}


+ (NSString *)qs_SQLKeysListWithArray:(NSArray *)keys {

	NSParameterAssert([keys count] > 0);

	NSMutableString *s = [[NSMutableString alloc] initWithString:@"("];
	NSUInteger i = 0;
	NSUInteger numberOfKeys = [keys count];

	for (i = 0; i < numberOfKeys; i++) {

		NSString *oneKey = keys[i];
		[s appendString:oneKey];
		BOOL isLast = (i == (numberOfKeys - 1));
		if (!isLast) {
			[s appendString:@", "];
		}
	}

	[s appendString:@")"];

	return [s copy];
}


+ (NSString *)qs_SQLKeyPlaceholderPairsWithKeys:(NSArray *)keys {

	/*key1=?, key2=?*/

	NSParameterAssert([keys count] > 0);

	NSMutableString *s = [NSMutableString stringWithString:@""];

	NSUInteger i = 0;
	NSUInteger numberOfKeys = [keys count];

	for (i = 0; i < numberOfKeys; i++) {

		NSString *oneKey = keys[i];
		[s appendString:oneKey];
		[s appendString:@"=?"];
		BOOL isLast = (i == (numberOfKeys - 1));
		if (!isLast) {
			[s appendString:@", "];
		}
	}

	return [s copy];
}


@end
