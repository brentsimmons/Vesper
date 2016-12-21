//
//  FMDatabase+QSKit.m
//  Vesper
//
//  Created by Brent Simmons on 3/3/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "FMDatabase+QSKit.h"
#import "NSString+QSDatabase.h"


@implementation FMDatabase (QSKit)


#pragma mark - Deleting

- (BOOL)qs_deleteRowsWhereKey:(NSString *)key inValues:(NSArray *)values tableName:(NSString *)tableName {

	if ([values count] < 1) {
		return YES;
	}

	NSString *placeholders = [NSString qs_SQLValueListWithPlaceholders:[values count]];
	NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ in %@", tableName, key, placeholders];

	return [self executeUpdate:sql withArgumentsInArray:values];
}


- (BOOL)qs_deleteRowsWhereKey:(NSString *)key equalsValue:(id)value tableName:(NSString *)tableName {

	NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@ = ?", tableName, key];
	return [self executeUpdate:sql, value];
}


#pragma mark - Selecting

- (FMResultSet *)qs_selectRowsWhereKey:(NSString *)key inValues:(NSArray *)values tableName:(NSString *)tableName {

	NSMutableString *sql = [NSMutableString stringWithFormat:@"select * from %@ where %@ in ", tableName, key];
	NSString *placeholders = [NSString qs_SQLValueListWithPlaceholders:[values count]];
	[sql appendString:placeholders];

	return [self executeQuery:[sql copy] withArgumentsInArray:values];
}


- (FMResultSet *)qs_selectSingleRowWhereKey:(NSString *)key equalsValue:(id)value tableName:(NSString *)tableName {

	NSString *sql = [NSMutableString stringWithFormat:@"select * from %@ where %@ = ? limit 1", tableName, key];
	return [self executeQuery:sql, value];
}


- (FMResultSet *)qs_selectAllRows:(NSString *)tableName {

	NSString *sql = [NSString stringWithFormat:@"select * from %@", tableName];
	return [self executeQuery:sql];
}


- (FMResultSet *)qs_selectColumnWithKey:(NSString *)key tableName:(NSString *)tableName {

	return [self executeQuery:[NSString stringWithFormat:@"select %@ from %@", key, tableName]];
}


- (BOOL)qs_rowExistsWithValue:(id)value forKey:(NSString *)key tableName:(NSString *)tableName {

	NSString *sql = [NSString stringWithFormat:@"select 1 from %@ where %@ = ? limit 1;", tableName, key];
	FMResultSet *rs = [self executeQuery:sql, value];

	return [rs next];
}


- (BOOL)qs_tableIsEmpty:(NSString *)tableName {

	NSString *sql = [NSString stringWithFormat:@"select 1 from %@ limit 1;", tableName];
	FMResultSet *rs = [self executeQuery:sql];

	BOOL isEmpty = YES;
	while ([rs next]) {
		isEmpty = NO;
	}
	return isEmpty;
}


#pragma mark - Updating

- (BOOL)qs_updateRowsWithDictionary:(NSDictionary *)d whereKey:(NSString *)key equalsValue:(id)value tableName:(NSString *)tableName {

	return [self qs_updateRowsWithDictionary:d whereKey:key inValues:@[value] tableName:tableName];
}


- (BOOL)qs_updateRowsWithDictionary:(NSDictionary *)d whereKey:(NSString *)key inValues:(NSArray *)keyValues tableName:(NSString *)tableName {

	NSMutableArray *keys = [NSMutableArray new];
	NSMutableArray *values = [NSMutableArray new];

	for (NSString *oneKey in d) {
		[keys addObject:oneKey];
		[values addObject:d[oneKey]];
	}

	NSString *keyPlaceholders = [NSString qs_SQLKeyPlaceholderPairsWithKeys:keys];
	NSString *keyValuesPlaceholder = [NSString qs_SQLValueListWithPlaceholders:[keyValues count]];
	NSString *sql = [NSString stringWithFormat:@"update %@ set %@ where %@ in %@", tableName, keyPlaceholders, key, keyValuesPlaceholder];

	NSMutableArray *parameters = [values mutableCopy];
	[parameters addObjectsFromArray:keyValues];

	return [self executeUpdate:sql withArgumentsInArray:[parameters copy]];
}


#pragma mark - Saving

- (BOOL)qs_insertRowWithDictionary:(NSDictionary *)d insertType:(QSDatabaseInsertType)insertType tableName:(NSString *)tableName {

	NSMutableArray *keys = [NSMutableArray new];
	NSMutableArray *values = [NSMutableArray new];

	for (NSString *oneKey in d) {
		[keys addObject:oneKey];
		[values addObject:d[oneKey]];
	}

	NSString *sqlKeysList = [NSString qs_SQLKeysListWithArray:[keys copy]];
	NSString *placeholders = [NSString qs_SQLValueListWithPlaceholders:[values count]];

	NSString *sqlBeginning = @"insert into ";
	if (insertType == QSDatabaseInsertOrReplace) {
		sqlBeginning = @"insert or replace into ";
	}
	else if (insertType == QSDatabaseInsertOrIgnore) {
		sqlBeginning = @"insert or ignore into ";
	}

	NSString *sql = [NSString stringWithFormat:@"%@ %@ %@ values %@", sqlBeginning, tableName, sqlKeysList, placeholders];

	return [self executeUpdate:sql withArgumentsInArray:values];
}


@end



@implementation FMResultSet (QSKit)


- (NSArray *)qs_arrayForSingleColumnResultSet {

	NSMutableArray *results = [NSMutableArray new];

	while ([self next]) {
		id oneObject = [self objectForColumnIndex:0];
		[results addObject:oneObject];
	}

	return [results copy];
}


@end
