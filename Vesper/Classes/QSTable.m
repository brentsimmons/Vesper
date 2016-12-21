//
//  QSTable.m
//  Vesper
//
//  Created by Brent Simmons on 3/10/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSTable.h"
#import "QSDataModel.h"
#import "QSDatabaseQueue.h"
#import "QSAPIObject.h"
#import "QSLookupTable.h"
#import "FMDatabase+QSKit.h"
#import "NSString+QSDatabase.h"


@interface QSTable ()

@property (nonatomic, readonly) QSObjectModel *objectModel;
@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, readonly) NSMapTable *mapTable;
@property (nonatomic, readonly) NSLock *mapTableLock;

@end


@implementation QSTable


#pragma mark - Init

- (instancetype)initWithObjectModel:(QSObjectModel *)objectModel queue:(QSDatabaseQueue *)queue {

	self = [super init];
	if (!self) {
		return nil;
	}

	_tableName = objectModel.tableName;
	_objectModel = objectModel;
	_queue = queue;

	if (objectModel.uniqued) {
		_mapTable = [NSMapTable strongToWeakObjectsMapTable];
		_mapTableLock = [NSLock new];
	}

	return self;
}


#pragma mark - Uniqued Objects

- (id)cachedObjectForUniqueID:(id)uniqueID {

	return [[self cachedObjectsForUniqueIDs:@[uniqueID]] firstObject];
}


- (NSArray *)cachedObjectsForUniqueIDs:(NSArray *)uniqueIDs {

	NSMutableArray *objects = [NSMutableArray new];

	[self.mapTableLock lock];

	for (id oneUniqueID in uniqueIDs) {

		id oneObject = [self.mapTable objectForKey:oneUniqueID];
		if (!oneObject || oneObject == [NSNull null]) {
			continue;
		}

		[objects addObject:oneObject];
	}

	[self.mapTableLock unlock];

	return [objects copy];
}


- (void)cacheObject:(id)obj {

	[self cacheObjects:@[obj]];
}


- (void)cacheObjects:(NSArray *)objects {

	[self.mapTableLock lock];

	for (id oneObject in objects) {

		id oneUniqueID = [oneObject valueForKey:QSUniqueIDKey];

		id existingObject = [self.mapTable objectForKey:oneUniqueID];
		if (!existingObject || existingObject == [NSNull null]) {
			[self.mapTable setObject:oneObject forKey:oneUniqueID];
		}
	}

	[self.mapTableLock unlock];
}


#pragma mark - Fetching

static NSString *QSTableStringType = @"string";
static NSString *QSTableInt64Type = @"int64";
static NSString *QSTableDateType = @"date";
static NSString *QSTableBoolType = @"boolean";
static NSString *QSTableDataType = @"data";
static NSString *QSTablePlistType = @"plist";
static NSString *QSTableArchiveType = @"archive";

- (id)objectValueForKey:(FMResultSet *)rs key:(NSString *)key {

	/*Returns nil instead of [NSNull null] for empty values.*/

	NSString *type = self.objectModel.propertiesModel[key];

	if ([type isEqualToString:QSTableStringType]) {
		return [rs stringForColumn:key];
	}

	else if ([type isEqualToString:QSTableInt64Type]) {
		int64_t n = [rs longLongIntForColumn:key];
		return [NSNumber numberWithLongLong:n];
	}

	else if ([type isEqualToString:QSTableDateType]) {
		return [rs dateForColumn:key];
	}

	else if ([type isEqualToString:QSTableBoolType]) {
		BOOL flag = [rs boolForColumn:key];
		return [NSNumber numberWithBool:flag];
	}

	else if ([type isEqualToString:QSTableDataType]) {
		return [rs dataForColumn:key];
	}

	else if ([type isEqualToString:QSTablePlistType]) {

		NSData *d = [rs dataForColumn:key];
		if (!d) {
			return nil;
		}

		NSError *error = nil;
		id propertyList = [NSPropertyListSerialization propertyListWithData:d options:NSPropertyListImmutable format:nil error:&error];
		return propertyList;
	}

	else if ([type isEqualToString:QSTableArchiveType]) {

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


- (id)objectWithRow:(FMResultSet *)row {

	id uniqueID = [self objectValueForKey:row key:QSUniqueIDKey];

	if (self.objectModel.uniqued) {

		id cachedObject = [self cachedObjectForUniqueID:uniqueID];
		if (cachedObject) {
			return cachedObject;
		}
	}

	id obj = [NSClassFromString(self.objectModel.className) new];

	[obj setValue:uniqueID forKey:QSUniqueIDKey];

	for (NSString *oneKey in [self.objectModel.propertiesModel allKeys]) {

		if ([oneKey isEqualToString:QSUniqueIDKey]) {
			continue;
		}

		id oneObjectValue = [self objectValueForKey:row key:oneKey];
		if (oneObjectValue) {
			[(id)obj setValue:oneObjectValue forKey:oneKey];
		}
	}

	if (self.objectModel.uniqued) {

		[self cacheObject:obj];
	}

	return obj;
}


- (NSArray *)objectsWithResultSet:(FMResultSet *)rs {

	NSMutableArray *objects = [NSMutableArray new];

	while ([rs next]) {
		id oneObject = [self objectWithRow:rs];
		[objects addObject:oneObject];
	}

	return [objects copy];
}


- (NSArray *)fetchObjects:(FMDatabase *)database resultSetBlock:(QSDatabaseResultSetBlock)resultSetBlock {

	FMResultSet *rs = resultSetBlock(database);
	NSArray *objects = [self objectsWithResultSet:rs];

	[self fetchAndAttachRelationships:objects database:database];

	return objects;
}


- (NSArray *)fetchAllObjects:(FMDatabase *)database {

	return [self fetchObjects:database resultSetBlock:^FMResultSet *(FMDatabase *database2) {

		return [database2 qs_selectAllRows:self.tableName];
	}];
}


- (NSArray *)fetchObjectsWithUniqueIDs:(NSArray *)uniqueIDs database:(FMDatabase *)database {

	return [self fetchObjects:database resultSetBlock:^FMResultSet *(FMDatabase *database2) {

		return [database2 qs_selectRowsWhereKey:QSUniqueIDKey inValues:uniqueIDs tableName:self.tableName];
	}];
}


- (id)fetchObjectWithUniqueID:(id)uniqueID database:(FMDatabase *)database {

	NSArray *objects = [self fetchObjects:database resultSetBlock:^FMResultSet *(FMDatabase *database2) {

		return [database2 qs_selectSingleRowWhereKey:QSUniqueIDKey equalsValue:uniqueID tableName:self.tableName];
	}];

	return [objects firstObject];
}


- (NSArray *)fetchAllUniqueIDs:(FMDatabase *)database {

	FMResultSet *rs = [database qs_selectColumnWithKey:QSUniqueIDKey tableName:self.tableName];
	return [rs qs_arrayForSingleColumnResultSet];
}


- (NSDictionary *)objectsWithUniqueIDs:(NSArray *)uniqueIDs database:(FMDatabase *)database {

	NSArray *objects = [self fetchObjects:database resultSetBlock:^FMResultSet *(FMDatabase *database2) {
		return [database2 qs_selectRowsWhereKey:QSUniqueIDKey inValues:uniqueIDs tableName:self.tableName];
	}];

	NSDictionary *objectsDictionary = [objects qs_dictionaryUsingKey:QSUniqueIDKey];
	return objectsDictionary;
}


#pragma mark - Relationships

- (void)fetchAndAttachRelationships:(NSArray *)objects database:(FMDatabase *)database {

	for (QSRelationshipModel *oneRelationshipModel in self.objectModel.relationshipModels
		 ) {
		[self fetchAndAttachRelationshipWithModel:oneRelationshipModel objects:objects database:database];
	}
}


- (void)fetchAndAttachRelationshipWithModel:(QSRelationshipModel *)relationshipModel objects:(NSArray *)objects database:(FMDatabase *)database {

	NSArray *parentUniqueIDs = [objects valueForKeyPath:QSUniqueIDKey];
	NSArray *relationships = [relationshipModel.lookupTable relationshipsForObjectIDs:parentUniqueIDs database:database];
	if ([relationships count] < 1) {
		return;
	}

	NSArray *childUniqueIDs = [relationshipModel.lookupTable distinctChildUniqueIDsInRelationships:relationships];
	NSDictionary *childObjects = [relationshipModel.childTable objectsWithUniqueIDs:childUniqueIDs database:database];

	id currentObject = nil;
	NSMutableArray *currentRelationshipArray = nil;

	NSString *relationshipName = relationshipModel.relationshipName;

	/*Relationships are sorted by parentID, ix, so we can step through linearly.*/

	for (NSDictionary *oneRelationship in relationships) {

		id oneRelationshipParentID = oneRelationship[QSParentIDKey];

		if (!currentObject || ![[currentObject valueForKey:QSUniqueIDKey] isEqual:oneRelationshipParentID]) {

			[currentObject setValue:[currentRelationshipArray copy] forKey:relationshipName];
			currentObject = [objects qs_firstObjectWhereValueForKey:QSUniqueIDKey equalsValue:oneRelationshipParentID];
			currentRelationshipArray = [NSMutableArray new];
		}

		id oneRelationshipChildID = oneRelationship[QSChildIDKey];
		id oneChildObject = childObjects[oneRelationshipChildID];

		if (oneChildObject) {
			[currentRelationshipArray addObject:oneChildObject];
		}
	}

	if (currentObject) {
		[currentObject setValue:[currentRelationshipArray copy] forKey:relationshipName];
	}
}


#pragma mark - Queued Requests

- (void)allObjects:(QSFetchResultsBlock)fetchResultsBlock {

	[self.queue fetch:^(FMDatabase *database) {

		NSArray *objects = [self fetchObjects:database resultSetBlock:^FMResultSet *(FMDatabase *database2) {
			return [database qs_selectAllRows:self.tableName];
		}];

		QSCallFetchResultsBlock(fetchResultsBlock, objects);
	}];
}


- (void)allUniqueIDs:(QSFetchResultsBlock)fetchResultsBlock {

	[self.queue fetch:^(FMDatabase *database) {

		FMResultSet *rs = [database qs_selectColumnWithKey:QSUniqueIDKey tableName:self.tableName];
		NSArray *uniqueIDs = [rs qs_arrayForSingleColumnResultSet];
		QSCallFetchResultsBlock(fetchResultsBlock, uniqueIDs);
	}];
}


- (void)objectsWithUniqueIDs:(NSArray *)uniqueIDs fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {

	if (self.objectModel.uniqued) {

		NSArray *cachedObjects = [self cachedObjectsForUniqueIDs:uniqueIDs];

		if ([cachedObjects count] == [uniqueIDs count]) {
			QSCallFetchResultsBlock(fetchResultsBlock, cachedObjects);
			return;
		}
	}

	[self.queue fetch:^(FMDatabase *database) {

		NSArray *objects = [self fetchObjectsWithUniqueIDs:uniqueIDs database:database];
		QSCallFetchResultsBlock(fetchResultsBlock, objects);
	}];
}


- (void)objects:(QSDatabaseResultSetBlock)resultSetBlock fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {

	[self.queue fetch:^(FMDatabase *database) {

		NSArray *objects = [self fetchObjects:database resultSetBlock:resultSetBlock];
		QSCallFetchResultsBlock(fetchResultsBlock, objects);
	}];
}


- (BOOL)isEmpty:(FMDatabase *)database {

	return [database qs_tableIsEmpty:self.tableName];
}


- (void)JSONObjects:(QSDatabaseResultSetBlock)resultSetBlock fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {

	[self.queue fetch:^(FMDatabase *database) {

		NSArray *objects = [self fetchObjects:database resultSetBlock:resultSetBlock];
		NSArray *JSONObjects = [QSAPIObject JSONArrayWithObjects:objects];

		QSCallFetchResultsBlock(fetchResultsBlock, JSONObjects);
	}];
}


#pragma mark - Saving

- (id)databaseValueForKey:(NSString *)key object:(id)obj {

	/*Returns nil instead of [NSNull null] for empty values.*/

	NSString *type = self.objectModel.propertiesModel[key];

	id value = [obj valueForKey:key];
	if (!value || value == [NSNull null]) {
		return nil;
	}

	if ([type isEqualToString:QSTablePlistType]) {

		NSError *error = nil;
		value = [NSPropertyListSerialization dataWithPropertyList:value format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];

		if (error) {
			NSLog(@"plist error: %@", error);
		}
	}

	return value;
}


- (BOOL)insertObject:(id)obj insertType:(QSDatabaseInsertType)insertType database:(FMDatabase *)database {

	NSMutableArray *values = [NSMutableArray new];
	NSMutableArray *keysWithNonNilValues = [NSMutableArray new];

	for (NSString *oneKey in [self.objectModel.propertiesModel allKeys]) {

		id oneValue = [self databaseValueForKey:oneKey object:obj];
		if (!oneValue) {
			continue;
		}

		[values addObject:oneValue];
		[keysWithNonNilValues addObject:oneKey];
	}

	NSString *sqlKeysList = [NSString qs_SQLKeysListWithArray:[keysWithNonNilValues copy]];
	NSString *placeholders = [NSString qs_SQLValueListWithPlaceholders:[values count]];

	NSString *sqlBeginning = @"insert into";
	if (insertType == QSDatabaseInsertOrReplace) {
		sqlBeginning = @"insert or replace into";
	}
	else if (insertType == QSDatabaseInsertOrIgnore) {
		sqlBeginning = @"insert or ignore into";
	}

	NSString *sql = [NSString stringWithFormat:@"%@ %@ %@ values %@", sqlBeginning, self.tableName, sqlKeysList, placeholders];

	return [database executeUpdate:sql withArgumentsInArray:values];
}


- (void)saveObject:(id)obj database:(FMDatabase *)database {

	[self insertObject:obj insertType:QSDatabaseInsertOrReplace database:database];
}


- (void)saveOrIgnoreObject:(id)obj database:(FMDatabase *)database {

	[self insertObject:obj insertType:QSDatabaseInsertOrIgnore database:database];
}


- (void)saveObjects:(NSArray *)objects database:(FMDatabase *)database {

	for (id oneObject in objects) {
		[self saveObject:oneObject database:database];
	}
}


- (void)saveOrIgnoreObjects:(NSArray *)objects database:(FMDatabase *)database {

	for (id oneObject in objects) {
		[self saveOrIgnoreObject:oneObject database:database];
	}
}

- (void)saveObjects:(NSArray *)objects {

	if ([objects count] < 1) {
		return;
	}
	
	if (self.objectModel.uniqued) {
		[self cacheObjects:objects];
	}

	if (self.objectModel.immutable) {

		/*If they're immutable, they don't change once they exist in the database.
		 So we use SQL insert or ignore.*/
		
		[self saveOrIgnoreObjects:objects];
		return;
	}

	else {

		/*Since the objects still may have references on main thread,
		 it's necessary to copy them before saving them in background.*/

		objects = [objects qs_arrayWithCopyOfEachObject];
	}

	[self.queue update:^(FMDatabase *database) {

		[self saveObjects:objects database:database];
	}];
}


- (void)saveOrIgnoreObjects:(NSArray *)objects {

	[self.queue update:^(FMDatabase *database) {

		[self saveOrIgnoreObjects:objects database:database];
	}];
}


- (void)updateLookupTableForObject:(id)obj relationship:(NSString *)relationship {

	id parentID = [obj valueForKey:QSUniqueIDKey];
	NSArray *children = [obj valueForKey:relationship];
	NSArray *childIDs = [children valueForKeyPath:QSUniqueIDKey];

	QSRelationshipModel *relationshipModel = [self.objectModel relationshipModelForName:relationship];
	NSAssert(relationshipModel != nil, nil);

	[relationshipModel.lookupTable saveChildObjectIDs:childIDs parentID:parentID queue:self.queue];
}


- (void)updateObject:(id)obj withDictionary:(NSDictionary *)d {

	for (NSString *oneKey in d) {

		id oneValue = d[oneKey];
		if (oneValue == [NSNull null]) {
			oneValue = nil;
		}

		[obj setValue:oneValue forKey:oneKey];
	}
}


- (void)updateObjectWithUniqueID:(id)uniqueID dictionary:(NSDictionary *)d {

	if (self.objectModel.uniqued) {

		id obj = [self cachedObjectForUniqueID:uniqueID];
		if (obj) {
			[self updateObject:obj withDictionary:d];
		}
	}

	[self.queue update:^(FMDatabase *database) {
		[database qs_updateRowsWithDictionary:d whereKey:QSUniqueIDKey equalsValue:uniqueID tableName:self.tableName];
	}];
}


#pragma mark - Deleting

- (void)deleteObjectsWithUniqueIDs:(NSArray *)uniqueIDs {

	[self.queue update:^(FMDatabase *database) {
		[database qs_deleteRowsWhereKey:QSUniqueIDKey inValues:uniqueIDs tableName:self.tableName];
	}];

	[self deleteParentIDsFromLookupTables:uniqueIDs];
}


- (void)deleteParentIDsFromLookupTables:(NSArray *)uniqueIDs {

	for (QSRelationshipModel *oneRelationshipModel in self.objectModel.relationshipModels) {

		QSLookupTable *oneLookupTable = oneRelationshipModel.lookupTable;
		[oneLookupTable deleteParentIDs:uniqueIDs queue:self.queue];
	}
}


- (void)deleteObjects:(NSArray *)objects {

	NSArray *uniqueIDs = [objects valueForKeyPath:QSUniqueIDKey];
	[self deleteObjectsWithUniqueIDs:uniqueIDs];
}


@end
