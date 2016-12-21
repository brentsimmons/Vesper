//
//  VSDatabaseController.h
//  Vesper
//
//  Created by Brent Simmons on 2/18/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class FMDatabase;
@class FMResultSet;
@class VSDatabaseObject;


typedef void (^VSDatabaseFetchResultsBlock)(NSArray *fetchedObjects);
typedef void (^VSDatabaseFetchResultsCountBlock)(NSUInteger count);
typedef void (^VSDatabaseUpdateBlock)(FMDatabase *database);
typedef FMResultSet *(^VSDatabaseFetchBlock)(FMDatabase *database);
typedef FMResultSet *(^VSDatabaseFetchObjectsBlock)(FMDatabase *database, NSRange range);
typedef void (^VSDatabaseCallback)(void);


@interface VSDatabaseController : NSObject


- (id)initWithDatabaseFileName:(NSString *)databaseName createTableStatement:(NSString *)createTableStatement;


@property (nonatomic, strong, readonly) FMDatabase *database; //Returns a per-thread database; same db should not be used in different threads
@property (nonatomic, strong, readonly) NSString *databaseFilePath;

@property (nonatomic, strong) dispatch_queue_t serialDispatchQueue;
@property (nonatomic, strong) NSMapTable *objectCache;

- (void)runDatabaseBlockInTransaction:(VSDatabaseUpdateBlock)databaseBlock;
- (void)beginTransaction;
- (void)endTransaction;

- (void)fetchAllObjectsForClass:(Class)databaseObjectClass sortString:(NSString *)sortString fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock;
- (void)fetchObjectsWithUniqueIDs:(NSArray *)uniqueIDs sortString:(NSString *)sortString databaseObjectClass:(Class)databaseObjectClass fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock;


- (void)runFetchForClass:(Class)databaseObjectClass fetchBlock:(VSDatabaseFetchBlock)fetchBlock fetchResultsBlock:(VSDatabaseFetchResultsBlock)fetchResultsBlock;

- (void)saveDatabaseObject:(VSDatabaseObject *)databaseObject;

/*Useful for migration*/

- (NSArray *)columnNamesForTableName:(NSString *)tableName;
- (BOOL)tableName:(NSString *)tableName hasColumnNamed:(NSString *)columnName;

+ (NSString *)sqlValuesListWithStrings:(NSArray *)strings;
- (NSArray *)databaseObjectsWithResultSet:(FMResultSet *)resultSet class:(Class)class;
//- (NSArray *)uniquedObjectsWithObjects:(NSArray *)databaseObjects;

@end
