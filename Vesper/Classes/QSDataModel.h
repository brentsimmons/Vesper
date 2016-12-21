//
//  QSDataModel.h
//  Vesper
//
//  Created by Brent Simmons on 3/5/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;


/*Immutable. Thread-safe.*/


@class QSObjectModel;
@class QSRelationshipModel;
@class QSTable;
@class QSLookupTable;
@class QSDatabaseQueue;


@interface QSDataModel : NSObject


- (instancetype)initWithDictionary:(NSDictionary *)d createStatements:(NSString *)createStatements databaseFilePath:(NSString *)databaseFilePath queue:(QSDatabaseQueue *)queue;

@property (nonatomic, readonly) NSArray *objectNames;
@property (nonatomic, readonly) NSArray *objectModels;

@property (nonatomic, readonly) QSDatabaseQueue *queue;

- (QSObjectModel *)objectModelForClassName:(NSString *)className;
- (QSTable *)objectTableForClass:(Class)class; /*For convenience.*/

@end



@interface QSObjectModel : NSObject


@property (nonatomic, readonly) NSString *className;
@property (nonatomic, readonly) NSString *tableName;

@property (nonatomic, assign, readonly) BOOL immutable;
@property (nonatomic, assign, readonly) BOOL uniqued;

@property (nonatomic, readonly) QSTable *table;

@property (nonatomic, readonly) NSDictionary *propertiesModel;

@property (nonatomic, readonly) NSArray *relationshipModels;
@property (nonatomic, retain) NSArray *relationshipNames;

- (QSRelationshipModel *)relationshipModelForClassName:(NSString *)className;
- (QSRelationshipModel *)relationshipModelForName:(NSString *)name;

- (QSLookupTable *)lookupTableForRelationship:(NSString *)relationshipName; /*For convenience.*/


@end


@interface QSRelationshipModel : NSObject


@property (nonatomic, readonly) NSString *relationshipName;
@property (nonatomic, readonly) NSString *tableName;
@property (nonatomic, readonly) NSString *parentIDName;
@property (nonatomic, readonly) NSString *childIDName;
@property (nonatomic, readonly) NSString *indexKey;
@property (nonatomic, readonly) NSString *childClassName;

@property (nonatomic, readonly) QSLookupTable *lookupTable;
@property (nonatomic, readonly) QSTable *childTable;

@end

