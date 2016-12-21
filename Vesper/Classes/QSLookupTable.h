//
//  QSDatabaseLookupTable.h
//  Vesper
//
//  Created by Brent Simmons on 3/9/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;


@class FMDatabase;

@interface QSLookupTable : NSObject


- (instancetype)initWithTableName:(NSString *)tableName parentIDKey:(NSString *)parentIDKey childIDKey:(NSString *)childIDKey indexKey:(NSString *)indexKey;


- (BOOL)deleteWhereParentIDEquals:(id)value database:(FMDatabase *)database;

- (BOOL)deleteWhereChildIDEquals:(id)value database:(FMDatabase *)database;

- (void)deleteParentIDs:(NSArray *)uniqueIDs queue:(QSDatabaseQueue *)queue;

- (void)deleteChildIDs:(NSArray *)uniqueIDs queue:(QSDatabaseQueue *)queue;

/*Returns array of NSDictionaries: QSParentIDKey, QSChildIDKey, QSIndexKey.
 Sorted by parentID, then index, so it can be used to attach relationships
 in the correct order.*/

extern NSString *QSParentIDKey;
extern NSString *QSChildIDKey;
extern NSString *QSIndexKey;

- (NSArray *)relationshipsForObjectIDs:(NSArray *)parentUniqueIDs database:(FMDatabase *)database;

- (NSArray *)distinctChildUniqueIDsInRelationships:(NSArray *)relationships;


- (void)saveChildObjectIDs:(NSArray *)childObjectIDs parentID:(id)parentID queue:(QSDatabaseQueue *)queue;

- (void)allChildIDs:(QSDatabaseQueue *)queue fetchResultsBlock:(QSFetchResultsBlock)fetchResultsBlock;



@end
