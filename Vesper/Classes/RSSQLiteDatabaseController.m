//
//  RSSQLiteDatabaseController.m
//  RSCoreTests
//
//  Created by Brent Simmons on 5/25/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSSQLiteDatabaseController.h"
#import "FMDatabase+Extras.h"
#import "FMDatabase.h"
#import "VSAppDelegateProtocol.h"


@interface RSSQLiteDatabaseController ()
@property (nonatomic, assign, readwrite) BOOL databaseIsNew;
@property (nonatomic, retain, readonly) NSString *databaseKey;
@property (nonatomic, retain, readonly) NSString *refcountKey;
- (void)ensureDatabaseFileExists:(NSString *)createTableStatement;
@end

@implementation RSSQLiteDatabaseController

@synthesize databaseFilePath, databaseIsNew;
@synthesize databaseKey, refcountKey;

#pragma mark Init

- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement {
	self = [super init];
	if (self == nil)
		return nil;
	databaseKey = [[NSString stringWithFormat:@"%@_cachedDatabaseKey", databaseName] retain];
	refcountKey = [[NSString stringWithFormat:@"%@_cachedRefCountKey", databaseName] retain];
	databaseFilePath = [[rs_app_delegate.pathToDataFolder stringByAppendingPathComponent:databaseName] retain];
	[self ensureDatabaseFileExists:createTableStatement];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[databaseKey release];
	[refcountKey release];
	[databaseFilePath release];
	[super dealloc];
}


#pragma mark Setup

- (void)ensureDatabaseFileExists:(NSString *)createTableStatement {
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.databaseFilePath])
		return;
	self.databaseIsNew = YES;
	@synchronized(self) {
		[[self database] executeUpdate:createTableStatement];
	}
}


#pragma mark Database

- (FMDatabase *)createDatabase {
	FMDatabase *db = FMDBOpenDatabaseWithPath(self.databaseFilePath);//[FMDatabase openDatabaseWithPath:self.databaseFilePath];
	[db setBusyRetryTimeout:100];
	[db executeUpdate:@"PRAGMA synchronous = 0;"];
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
	@synchronized(self) {
		NSInteger transactionRefCount = [[[NSThread currentThread] threadDictionary] rs_integerForKey:self.refcountKey];
		if (transactionRefCount < 0)
			transactionRefCount = 0;
		transactionRefCount++;
		[[[NSThread currentThread] threadDictionary] rs_setInteger:transactionRefCount forKey:self.refcountKey];
		if (transactionRefCount == 1)
			[[self database] beginTransaction];
	}
}


- (void)endTransaction {
	@synchronized(self) {
		NSInteger transactionRefCount = [[[NSThread currentThread] threadDictionary] rs_integerForKey:self.refcountKey];
		transactionRefCount--;
		if (transactionRefCount < 1)
			transactionRefCount = 0;
		[[[NSThread currentThread] threadDictionary] rs_setInteger:transactionRefCount forKey:self.refcountKey];
		if (transactionRefCount == 0)
			[[self database] commit];
	}
}


@end
