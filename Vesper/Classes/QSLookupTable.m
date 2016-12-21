//
//  QSLookupTable.m
//  Vesper
//
//  Created by Brent Simmons on 3/9/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSLookupTable.h"
#import "FMDatabase+QSKit.h"
#import "FMDatabase.h"
#import "NSString+QSDatabase.h"
#import "QSDatabaseQueue.h"


@interface QSLookupTable ()

@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, readonly) NSString *parentIDKey;
@property (nonatomic, readonly) NSString *childIDKey;
@property (nonatomic, readonly) NSString *indexKey;

@end


@implementation QSLookupTable


#pragma mark - Init

- (instancetype)initWithTableName:(NSString *)tableName parentIDKey:(NSString *)parentIDKey childIDKey:(NSString *)childIDKey indexKey:(NSString *)indexKey {

	self = [super init];
	if (!self) {
		return nil;
	}

	_tableName = tableName;
	_parentIDKey = parentIDKey;
	_childIDKey = childIDKey;
	_indexKey = indexKey;

	return self;
}


#pragma mark - Deleting

- (BOOL)deleteWhereParentIDEquals:(id)value database:(FMDatabase *)database {

	return [database qs_deleteRowsWhereKey:self.parentIDKey equalsValue:value tableName:self.tableName];
}


- (BOOL)deleteWhereChildIDEquals:(id)value database:(FMDatabase *)database {

	return [database qs_deleteRowsWhereKey:self.childIDKey equalsValue:value tableName:self.tableName];
}


- (void)deleteParentIDs:(NSArray *)uniqueIDs queue:(QSDatabaseQueue *)queue {

	[queue update:^(FMDatabase *database) {

		[database qs_deleteRowsWhereKey:self.parentIDKey inValues:uniqueIDs tableName:self.tableName];
	}];
}


- (void)deleteChildIDs:(NSArray *)uniqueIDs queue:(QSDatabaseQueue *)queue {

	[queue update:^(FMDatabase *database) {

		[database qs_deleteRowsWhereKey:self.childIDKey inValues:uniqueIDs tableName:self.tableName];
	}];
}


#pragma mark - Fetching

NSString *QSParentIDKey = @"parentID";
NSString *QSChildIDKey = @"childID";
NSString *QSIndexKey = @"index";

- (NSArray *)relationshipsForObjectIDs:(NSArray *)parentUniqueIDs database:(FMDatabase *)database {

	if ([parentUniqueIDs count] < 1) {
		return nil;
	}

	NSString *placeholder = [NSString qs_SQLValueListWithPlaceholders:[parentUniqueIDs count]];
	NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@ in %@ order by %@ ASC, %@ ASC", self.tableName, self.parentIDKey, placeholder, self.parentIDKey, self.indexKey];

	FMResultSet *rs = [database executeQuery:sql withArgumentsInArray:parentUniqueIDs];
	NSMutableArray *relationships = [NSMutableArray new];

	while ([rs next]) {

		NSMutableDictionary *d = [NSMutableDictionary new];

		d[QSParentIDKey] = [rs objectForColumnName:self.parentIDKey];
		d[QSChildIDKey] = [rs objectForColumnName:self.childIDKey];
		d[QSIndexKey] = @([rs longLongIntForColumn:self.indexKey]);

		[relationships addObject:d];
	}

	return [relationships copy];
}


- (NSArray *)childIDsForParentID:(id)parentID database:(FMDatabase *)database {

	NSString *sql = [NSString stringWithFormat:@"select %@ from %@ where %@ = ? order by %@ ASC", self.childIDKey, self.tableName, self.parentIDKey, self.indexKey];
	FMResultSet *rs = [database executeQuery:sql, parentID];

	NSArray *childIDs = [rs qs_arrayForSingleColumnResultSet];

	return childIDs;
}


- (NSArray *)distinctChildUniqueIDsInRelationships:(NSArray *)relationships {

	return [relationships valueForKeyPath:QSChildIDKey];
}


- (void)allChildIDs:(QSDatabaseQueue *)queue fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock {

	[queue fetch:^(FMDatabase *database) {

		FMResultSet *rs = [database qs_selectColumnWithKey:self.childIDKey tableName:self.tableName];
		NSArray *uniqueIDs = [rs qs_arrayForSingleColumnResultSet];

		QSCallFetchResultsBlock(fetchResultsBlock, uniqueIDs);
	}];
}


- (void)saveChildObjectIDs:(NSArray *)childObjectIDs parentID:(id)parentID queue:(QSDatabaseQueue *)queue {

	[queue update:^(FMDatabase *database) {

		/*If they're the same, don't bother.*/

		NSArray *currentChildIDs = [self childIDsForParentID:parentID database:database];
		if (QSIsEmpty(childObjectIDs) && QSIsEmpty(currentChildIDs)) {
			return;
		}

		if (QSIsEmpty(childObjectIDs)) {
			[self deleteWhereParentIDEquals:parentID database:database];
			return;
		}

		if ([childObjectIDs isEqual:currentChildIDs]) {
			return;
		}

		[self deleteWhereParentIDEquals:parentID database:database];

		NSUInteger ix = 0;

		for (id oneChildID in childObjectIDs) {

			NSMutableDictionary *d = [NSMutableDictionary new];
			d[self.indexKey] = @(ix);
			d[self.parentIDKey] = parentID;
			d[self.childIDKey] = oneChildID;

			[database qs_insertRowWithDictionary:d insertType:QSDatabaseInsertOrReplace tableName:self.tableName];

			ix++;
		}
	}];
}

@end
