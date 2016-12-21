//
//  QSDataRowFetcher.m
//  Vesper
//
//  Created by Brent Simmons on 3/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSDataRowFetcher.h"
#import "FMDatabase.h"
#import "QSDataModel.h"
#import "QSDataObjectCache.h"


@interface QSDataRowFetcher ()

@property (nonatomic, readonly) QSDataObjectCache *objectCache;
@property (nonatomic, readonly) NSLock *objectCacheLock;

@end


@implementation QSDataRowFetcher


#pragma mark - Init

- (instancetype)initWithObjectCache:(QSDataObjectCache *)objectCache objectCacheLock:(NSLock *)objectCacheLock {

	self = [super init];
	if (!self) {
		return nil;
	}

	_objectCache = objectCache;
	_objectCacheLock = objectCacheLock;

	return self;
}


#pragma mark - API

- (NSArray *)objectsWithResultSet:(FMResultSet *)resultSet objectModel:(QSObjectModel *)objectModel {

	NSMutableArray *objects = [NSMutableArray new];

	while ([resultSet next]) {
		[objects addObject:[self objectWithRow:resultSet objectModel:objectModel]];
	}

	return [objects copy];
}


- (NSArray *)dictionariesWithResultSet:(FMResultSet *)rs objectModel:(QSObjectModel *)objectModel {

	NSMutableArray *dictionaries = [NSMutableArray new];

	while ([rs next]) {
		NSDictionary *oneDictionary = [self dictionaryWithRow:rs objectModel:objectModel];
		[dictionaries addObject:oneDictionary];
	}

	return [dictionaries copy];
}


#pragma mark - Utilities


- (id<VSDatabaseObject>)objectWithRow:(FMResultSet *)rs objectModel:(QSObjectModel *)objectModel {

	NSDictionary *propertiesModel = objectModel.propertiesModel;

	/*If object is already cached, we can avoid pulling values from database.
	 It's okay to reference the object outside the main thread, since none of the
	 object's state is touched.*/

	id uniqueID = [self objectValueForKey:rs key:QSUniqueIDKey propertiesModel:propertiesModel];

	[self.objectCacheLock lock];
	id<VSDatabaseObject> databaseObject = [self.objectCache cachedObjectForUniqueID:uniqueID className:objectModel.className];
	[self.objectCacheLock unlock];

	if (databaseObject) {
		return databaseObject;
	}

	databaseObject = [NSClassFromString(objectModel.className) new];
	[(id)databaseObject setValue:uniqueID forKey:QSUniqueIDKey];

	for (NSString *oneKey in [propertiesModel allKeys]) {

		if ([oneKey isEqualToString:QSUniqueIDKey]) {
			continue;
		}

		id oneObjectValue = [self objectValueForKey:rs key:oneKey propertiesModel:propertiesModel];
		if (oneObjectValue != nil) {
			[(id)databaseObject setValue:oneObjectValue forKey:oneKey];
		}
	}

	return databaseObject;
}


- (id)objectValueForKey:(FMResultSet *)rs key:(NSString *)key propertiesModel:(NSDictionary *)propertiesModel {

	/*Returns nil instead of [NSNull null] for empty values.*/

	NSString *type = propertiesModel[key];

	if ([type isEqualToString:@"string"]) {
		return [rs stringForColumn:key];
	}

	else if ([type isEqualToString:@"int64"]) {
		int64_t n = [rs longLongIntForColumn:key];
		return [NSNumber numberWithLongLong:n];
	}

	else if ([type isEqualToString:@"date"]) {
		return [rs dateForColumn:key];
	}

	else if ([type isEqualToString:@"boolean"]) {
		BOOL flag = [rs boolForColumn:key];
		return [NSNumber numberWithBool:flag];
	}

	else if ([type isEqualToString:@"data"]) {
		return [rs dataForColumn:key];
	}

	else if ([type isEqualToString:@"plist"]) {

		NSData *d = [rs dataForColumn:key];
		if (!d) {
			return nil;
		}

		NSError *error = nil;
		id propertyList = [NSPropertyListSerialization propertyListWithData:d options:NSPropertyListImmutable format:nil error:&error];
		return propertyList;
	}

	else if ([type isEqualToString:@"archive"]) {

		NSData *d = [rs dataForColumn:key];
		if (!d) {
			return nil;
		}

		return [NSKeyedUnarchiver unarchiveObjectWithData:d];
	}

	/*Shouldn't get here.*/

	NSAssert(false, nil);
	return nil;
}




- (NSDictionary *)dictionaryWithRow:(FMResultSet *)rs objectModel:(QSObjectModel *)objectModel {

	NSMutableDictionary *d = [NSMutableDictionary new];
	NSDictionary *propertiesModel = objectModel.propertiesModel;

	for (NSString *oneKey in [propertiesModel allKeys]) {

		id oneValue = [self objectValueForKey:rs key:oneKey propertiesModel:propertiesModel];
		if (oneValue != nil) {
			d[oneKey] = oneValue;
		}
	}

	return [d copy];
}




@end
