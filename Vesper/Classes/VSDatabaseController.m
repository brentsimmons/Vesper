//
//  VSDatabaseController.m
//  Vesper
//
//  Created by Brent Simmons on 2/18/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSDatabaseController.h"
#import "FMDatabase.h"
#import "FMDatabase+Extras.h"


@interface VSDatabaseController ()

@property (nonatomic, strong) NSString *databaseKey;
@property (nonatomic, strong) NSString *refcountKey;
@property (nonatomic, strong, readwrite) NSString *databaseFilePath;
@end


@implementation VSDatabaseController


#pragma mark Init

- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement {

	self = [super init];
	if (self == nil)
		return nil;

 	_databaseKey = [NSString stringWithFormat:@"%@_cachedDatabaseKey", databaseName];
	_refcountKey = [NSString stringWithFormat:@"%@_cachedRefCountKey", databaseName];

    NSError *error = nil;
    NSString *dataFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if (![[NSFileManager defaultManager] createDirectoryAtPath:dataFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Error creating data folder: %@", error);
        abort();
    }

#if TARGET_IPHONE_SIMULATOR
    NSLog(@"dataFolder: %@", dataFolder);
#endif

	_databaseFilePath = [dataFolder stringByAppendingPathComponent:databaseName];

    NSString *serialQueueName = [NSString stringWithFormat:@"%@ Serial Dispatch Queue", NSStringFromClass([self class])];
  	_serialDispatchQueue = dispatch_queue_create([serialQueueName UTF8String], DISPATCH_QUEUE_SERIAL);

    [self ensureDatabaseFileExists:createTableStatement];

    _objectCache = [NSMapTable weakToWeakObjectsMapTable];

    return self;
}


#pragma mark Setup

- (void)ensureDatabaseFileExists:(NSString *)createTableStatement {
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.databaseFilePath])
		return;
    [self runDatabaseBlockInTransaction:^(FMDatabase *database) {
        [database executeUpdate:createTableStatement];
    }];
}


#pragma mark Utilities

+ (NSString *)sqlValuesListWithStrings:(NSArray *)strings {

	if ([strings count] < 1)
		return nil;

	NSMutableString *s = [[NSMutableString alloc] initWithString:@"("];

    @autoreleasepool {
        NSUInteger numberOfStrings = [strings count];
        NSUInteger indexOfString = 0;

        for (NSString *oneString in strings) {

            [s appendString:@"'"];
            [s appendString:oneString];
            [s appendString:@"'"];

            BOOL isLast = (indexOfString == (numberOfStrings - 1));
            if (!isLast)
                [s appendString:@", "];
            indexOfString++;
        }

        [s appendString:@")"];
    }

	return s;
}


#pragma mark Saving

- (void)saveDatabaseObject:(VSDatabaseObject *)databaseObject {

//    NSAssert(databaseObject.uniqueID != nil, @"databaseObject.uniqueID must not be nil");
//
//    NSString *uniqueID = databaseObject.uniqueID;
//	//    [self.objectCache setObject:databaseObject forKey:uniqueID];
//
//    NSMutableDictionary *databaseObjectDictionary = [[databaseObject dictionaryRepresentation] mutableCopy];
//    [databaseObjectDictionary removeObjectForKey:@"uniqueID"];
//    NSDictionary *valuesDictionary = [databaseObjectDictionary copy];
//
//    NSString *tableName = [[databaseObject class] tableName];
//
//    [self runDatabaseBlockInTransaction:^(FMDatabase *database) {
//
//        NSMutableString *sqlString = [NSMutableString stringWithString:@"insert or replace into "];
//        [sqlString appendString:tableName];
//        [sqlString appendString:@" (uniqueID, "];
//        NSArray *keys = [valuesDictionary allKeys];
//
//        NSUInteger indexOfKey = 0;
//        NSUInteger numberOfKeys = [keys count];
//
//        for (NSString *oneKey in keys) {
//            [sqlString appendString:oneKey];
//            if (indexOfKey < numberOfKeys - 1)
//                [sqlString appendString:@", "];
//            else
//                [sqlString appendString:@") "];
//            indexOfKey++;
//        }
//
//        [sqlString appendString:@"values (?, "];
//
//        indexOfKey = 0;
//        for (NSString *oneKey in keys) {
//            [sqlString appendString:@"?"];
//            if (indexOfKey < numberOfKeys - 1)
//                [sqlString appendString:@", "];
//            else
//                [sqlString appendString:@");"];
//            indexOfKey++;
//        }
//
//        NSMutableArray *values = [NSMutableArray new];
//        [values addObject:uniqueID];
//        for (NSString *oneKey in keys) {
//            id oneValue = [valuesDictionary valueForKey:oneKey];
//            [values addObject:oneValue];
//        }
//
//        [database executeUpdate:[sqlString copy] withArgumentsInArray:[values copy]];
//    }];
}


#pragma mark Database

- (void)runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock {
	dispatch_async(self.serialDispatchQueue, ^{
		@autoreleasepool {
			[self beginTransaction];
			databaseBlock(self.database);
			[self endTransaction];
		}
	});
}




- (VSDatabaseObject *)databaseObjectWithRow:(FMResultSet *)resultSet class:(Class)class {

    VSDatabaseObject *databaseObject = (VSDatabaseObject *)[class new];
    [databaseObject takeValuesFromResultSetRow:resultSet];
    return databaseObject;
}


- (NSArray *)databaseObjectsWithResultSet:(FMResultSet *)resultSet class:(Class)class {

	NSMutableArray *fetchedObjects = [NSMutableArray new];
    @autoreleasepool {
        while ([resultSet next])
            [fetchedObjects rs_safeAddObject:[self databaseObjectWithRow:resultSet class:class]];
    }
	return [fetchedObjects copy];
}


- (void)runFetchForClass:(Class)databaseObjectClass fetchBlock:(VSDatabaseFetchBlock)fetchBlock fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock {

	dispatch_async(self.serialDispatchQueue, ^{
		@autoreleasepool {
			[self beginTransaction];
			FMResultSet *resultSet = fetchBlock(self.database);
			NSArray *fetchedObjects = [self databaseObjectsWithResultSet:resultSet class:databaseObjectClass];
			[self endTransaction];

            if (fetchResultsBlock != nil)
                fetchResultsBlock(fetchedObjects);

			//			dispatch_async(dispatch_get_main_queue(), ^{
			//				@autoreleasepool {
			//					NSArray *uniquedObjects = [self uniquedObjectsWithObjects:fetchedObjects];
			//					if (fetchResultsBlock != nil)
			//						fetchResultsBlock(uniquedObjects);
			//				}
			//			});
		}
	});
}


- (void)fetchAllObjectsForClass:(Class)databaseObjectClass sortString:(NSString *)sortString fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock {

    NSString *tableName = [databaseObjectClass tableName];
    [self runFetchForClass:databaseObjectClass fetchBlock:^FMResultSet *(FMDatabase *database) {
        NSString *sqlString = [NSString stringWithFormat:@"select * from %@ %@;", tableName, sortString ? sortString: @""];
        return [database executeQuery:sqlString];
    } fetchResultsBlock:fetchResultsBlock];
}


- (void)fetchObjectsWithUniqueIDs:(NSArray *)uniqueIDs sortString:(NSString *)sortString databaseObjectClass:(Class)databaseObjectClass fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock {

    [self runFetchForClass:databaseObjectClass fetchBlock:^FMResultSet *(FMDatabase *database) {

        NSString *valuesString = [[self class] sqlValuesListWithStrings:uniqueIDs];
        NSString *tableName = [databaseObjectClass tableName];
        NSString *sqlString = [NSString stringWithFormat:@"select * from %@ where uniqueID in %@ %@;", tableName, valuesString, sortString ? sortString : @""];

        return [database executeQuery:sqlString];
    } fetchResultsBlock:fetchResultsBlock];
}


- (FMDatabase *)createDatabase {
	FMDatabase *db = [FMDatabase openDatabaseWithPath:self.databaseFilePath];
	[db setBusyRetryTimeout:100];
	[db executeUpdate:@"PRAGMA synchronous = 1;"];
	[db setShouldCacheStatements:YES];
	return db;
}


- (FMDatabase *)database {
	FMDatabase *db = [[[NSThread currentThread] threadDictionary] objectForKey:self.databaseKey];
	if (db)
		return db;
	db = [self createDatabase];
	if (db)
		[[[NSThread currentThread] threadDictionary] setObject:db forKey:self.databaseKey];
	return db;
}


- (void)newDatabase {
	FMDatabase *db = [self createDatabase];
	if (db)
		[[[NSThread currentThread] threadDictionary] setObject:db forKey:self.databaseKey];
}


#pragma mark Tables

- (NSArray *)columnNamesForTableName:(NSString *)tableName {
	FMResultSet *rs = [self.database executeQuery:[NSString stringWithFormat: @"PRAGMA table_info('%@')", tableName]];
	NSMutableArray *columnNames = [NSMutableArray array];
	while([rs next]) {
		NSString *oneColumnName = [rs stringForColumn:@"name"];
		[columnNames rs_safeAddObject:oneColumnName];
	}
	//NSLog(@"columnNames: %@", columnNames);
	[rs close];
	return columnNames;
}


- (BOOL)tableName:(NSString *)tableName hasColumnNamed:(NSString *)columnName {
	NSArray *columnNames = [self columnNamesForTableName:tableName];
	return [columnNames containsObject:columnName];
}


#pragma mark Transactions

- (void)beginTransaction {
    NSInteger transactionRefCount = [[[NSThread currentThread] threadDictionary] rs_integerForKey:self.refcountKey];
    if (transactionRefCount < 0)
        transactionRefCount = 0;
    transactionRefCount++;
    [[[NSThread currentThread] threadDictionary] rs_setInteger:transactionRefCount forKey:self.refcountKey];
    if (transactionRefCount == 1)
        [[self database] beginTransaction];
}


- (void)endTransaction {
    NSInteger transactionRefCount = [[[NSThread currentThread] threadDictionary] rs_integerForKey:self.refcountKey];
    transactionRefCount--;
    if (transactionRefCount < 1)
        transactionRefCount = 0;
    [[[NSThread currentThread] threadDictionary] rs_setInteger:transactionRefCount forKey:self.refcountKey];
    if (transactionRefCount == 0)
        [[self database] commit];
}


@end
