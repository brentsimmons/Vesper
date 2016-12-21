//
//  RSSQLiteDatabaseController.h
//  RSCoreTests
//
//  Created by Brent Simmons on 5/25/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*For sub-classing only. Shared code for handling a simple SQLite3 database.
 The database file is placed in the appropriate place for Mac and iPhone OS.*/

@class FMDatabase;

@interface RSSQLiteDatabaseController : NSObject {
@protected
	NSString *databaseFilePath;
	BOOL databaseIsNew;		
	NSString *databaseKey; //Subclasses should not need to deal with these two keys
	NSString *refcountKey;
}


@property (nonatomic, retain, readonly) FMDatabase *database; //Returns a per-thread database; same db should not be used in different threads
@property (nonatomic, retain, readonly) NSString *databaseFilePath;
@property (nonatomic, assign, readonly) BOOL databaseIsNew;

- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement;

- (void)beginTransaction;
- (void)endTransaction;

/*Useful for migration*/
- (NSArray *)columnNamesForTableName:(NSString *)tableName;
- (BOOL)tableName:(NSString *)tableName hasColumnNamed:(NSString *)columnName;


/*For subclasses*/
- (void)ensureDatabaseFileExists:(NSString *)createTableStatement;

@end
