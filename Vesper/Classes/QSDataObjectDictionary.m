//
//  QSDataObjectDictionary.m
//  Vesper
//
//  Created by Brent Simmons on 3/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSDataObjectDictionary.h"
#import "QSDataModel.h"


@implementation QSDataObjectDictionary


+ (NSDictionary *)objectDictionaryForObject:(id<VSDatabaseObject>)obj objectModel:(QSObjectModel *)objectModel {

	NSMutableDictionary *d = [NSMutableDictionary new];

	for (NSString *onePropertyKey in objectModel.propertiesModel) {

		id oneValue = [(id)obj valueForKey:onePropertyKey];
		if (!oneValue) {
			continue;
		}

		if ([onePropertyKey isEqualToString:@"plist"]) {

			NSError *error = nil;
			NSData *data = [NSPropertyListSerialization dataWithPropertyList:oneValue format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
			oneValue = data;
		}

		d[onePropertyKey] = oneValue;
	}

	return [d copy];
}


+ (NSArray *)objectDictionariesForObjects:(NSArray *)databaseObjects objectModel:(QSObjectModel *)objectModel {

	NSMutableArray *objectDictionaries = [NSMutableArray new];

	for (id<VSDatabaseObject>oneObject in databaseObjects) {
		NSDictionary *oneObjectDictionary = [self objectDictionaryForObject:oneObject objectModel:objectModel];
		[objectDictionaries addObject:oneObjectDictionary];
	}

	return [objectDictionaries copy];
}


@end
