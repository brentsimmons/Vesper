//
//  QSAPIObject.m
//  Vesper
//
//  Created by Brent Simmons on 3/6/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSAPIObject.h"
#import "NSArray+QSKit.h"


@implementation QSAPIObject


+ (NSArray *)JSONArrayWithObjects:(NSArray *)objects {

	return [objects qs_map:^id(id<QSAPIObject> obj) {
		return [obj JSONRepresentation];
	}];
}

+ (NSArray *)objectsWithJSONArray:(NSArray *)JSONArray class:(Class<QSAPIObject>)class {

	return [JSONArray qs_map:^id(NSDictionary *oneJSONDictionary) {
		return [class objectWithJSONRepresentation:oneJSONDictionary];
	}];
}


+ (void)objectsWithJSONArray:(NSArray *)JSONArray class:(Class<QSAPIObject>)class resultsBlock:(QSFetchResultsBlock)resultsBlock {

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

		NSArray *objects = [self objectsWithJSONArray:JSONArray class:class];
		QSCallFetchResultsBlock(resultsBlock, objects);
	});
}


@end
