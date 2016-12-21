//
//  QSTable.h
//  Vesper
//
//  Created by Brent Simmons on 3/10/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSDatabaseQueue.h"


/*Understand objects.*/


@class QSObjectModel;


@interface QSTable : NSObject


- (instancetype)initWithObjectModel:(QSObjectModel *)objectModel queue:(QSDatabaseQueue *)queue;

/*The queue is shared with the QSDatabase and all other QSTable
 instances attached to that same QSDatabase.*/

@property (nonatomic, readonly) QSDatabaseQueue *queue;


/*Methods that take an FMDatabase are meant to be called from within a QSDatabaseQueue
 block. Methods that take a QSDatabaseQueue execute on that background serial queue.*/


/*Objects are uniqued. Relationships are fetched and attached.
 Merge policy: main thread always wins.
 If objects exist in cache, then those objects are returned
 even if the database has different data -- because main thread has newest data.*/


- (NSArray *)fetchAllObjects:(FMDatabase *)database;

- (NSArray *)fetchObjects:(FMDatabase *)database resultSetBlock:(QSDatabaseResultSetBlock)resultSetBlock;

- (NSArray *)fetchObjectsWithUniqueIDs:(NSArray *)uniqueIDs database:(FMDatabase *)database;

- (NSArray *)fetchAllUniqueIDs:(FMDatabase *)database;

- (id)fetchObjectWithUniqueID:(id)uniqueID database:(FMDatabase *)database;


/*fetchResultsBlocks are always called on the main thread.*/

- (void)allObjects:(QSFetchResultsBlock)fetchResultsBlock;

- (void)allUniqueIDs:(QSFetchResultsBlock)fetchResultsBlock;

- (void)objectsWithUniqueIDs:(NSArray *)uniqueIDs fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock;

- (void)objects:(QSDatabaseResultSetBlock)resultSetBlock fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock;

- (BOOL)isEmpty:(FMDatabase *)database;


/*Objects must conform to QSAPIObject protocol.*/

- (void)JSONObjects:(QSDatabaseResultSetBlock)resultSetBlock fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock;


- (void)saveObjects:(NSArray *)objects; /*Does not save relationships.*/

- (void)updateLookupTableForObject:(id)obj relationship:(NSString *)relationship;


/*Updates database. Also updates cached object if it exists.*/

- (void)updateObjectWithUniqueID:(id)uniqueID dictionary:(NSDictionary *)d;

- (void)deleteObjects:(NSArray *)objects; /*Also removes from lookup table.*/

- (void)deleteObjectsWithUniqueIDs:(NSArray *)uniqueIDs; /*Also removes from lookup table.*/

@end
