//
//  QSDatabaseQueue.h
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/19/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

@import Foundation;

@class FMDatabase;
@class FMResultSet;
@class QSDatabaseQueue;


@protocol QSDatabaseQueueDelegate <NSObject>

@optional

- (void)makeFunctionsForDatabase:(FMDatabase *)database queue:(QSDatabaseQueue *)queue;

@end


/*Thread-safe. Creates database in Documents folder (iOS) or Application Support folder (Mac).
 
 update, fetch, and vacuum are async.
 updateBlock and fetchBlock run on a background serial queue.
 update and fetch both have autoreleasepools.*/


typedef void (^QSDatabaseBlock)(FMDatabase *database);
typedef FMResultSet *(^QSDatabaseResultSetBlock)(FMDatabase *database);


@interface QSDatabaseQueue : NSObject

@property (nonatomic, strong, readonly) NSString *databasePath; /*For debugging use, so you can open the database in sqlite3.*/


/*If you use the filename version, it creates the file wherever QSDataFile() says.*/

- (instancetype)initWithFilename:(NSString *)filename excludeFromBackup:(BOOL)excludeFromBackup;
- (instancetype)initWithFilepath:(NSString *)filepath excludeFromBackup:(BOOL)excludeFromBackup;

@property (nonatomic, weak) id<QSDatabaseQueueDelegate> delegate;


- (void)update:(QSDatabaseBlock)updateBlock; /*Wrapped in a transaction.*/

- (void)runInDatabase:(QSDatabaseBlock)databaseBlock; /*Same as update: but no transaction.*/

- (void)fetch:(QSDatabaseBlock)fetchBlock;
- (void)fetchSync:(QSDatabaseBlock)fetchBlock;

- (void)vacuum;

- (NSArray *)arrayWithSingleColumnResultSet:(FMResultSet *)rs;

@end
