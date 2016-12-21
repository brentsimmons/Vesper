//
//  QSDataModel.m
//  Vesper
//
//  Created by Brent Simmons on 3/5/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSDataModel.h"
#import "QSTable.h"
#import "QSLookupTable.h"
#import "QSDatabaseQueue.h"
#import "FMDatabase.h"


@interface QSDataModel ()

@property (nonatomic, readonly) NSMutableDictionary *objectModelDictionary;
@property (nonatomic, readonly) NSString *databaseFilePath;

@end


@interface QSObjectModel ()

@property (nonatomic, readonly) NSMutableDictionary *relationshipModelDictionary;
@property (nonatomic, weak, readonly) QSDataModel *dataModel;

- (instancetype)initWithClassName:(NSString *)className dictionary:(NSDictionary *)dictionary dataModel:(QSDataModel *)dataModel;

@end


@interface QSRelationshipModel ()

@property (nonatomic, weak, readonly) QSDataModel *dataModel;

- (instancetype)initWithName:(NSString *)name dictionary:(NSDictionary *)dictionary dataModel:(QSDataModel *)dataModel;

@end


@implementation QSDataModel


#pragma mark - Init

- (instancetype)initWithDictionary:(NSDictionary *)d createStatements:(NSString *)createStatements databaseFilePath:(NSString *)databaseFilePath queue:(QSDatabaseQueue *)queue {

	self = [super init];
	if (self == nil) {
		return nil;
	}

	_queue = queue;
	_databaseFilePath = databaseFilePath;

	_objectModelDictionary = [NSMutableDictionary new];

	NSDictionary *objectModelsDictionary = d[@"objects"];
	NSMutableArray *objectNames = [NSMutableArray new];
	NSMutableArray *objectModels = [NSMutableArray new];

	for (NSString *oneObjectName in [objectModelsDictionary allKeys]) {

		[objectNames addObject:oneObjectName];

		NSDictionary *oneObjectDictionary = objectModelsDictionary[oneObjectName];
		QSObjectModel *oneObjectModel = [[QSObjectModel alloc] initWithClassName:oneObjectName dictionary:oneObjectDictionary dataModel:self];

		[objectModels addObject:oneObjectModel];

		_objectModelDictionary[oneObjectName] = oneObjectModel;
	}

	_objectNames = [objectNames copy];
	_objectModels = [objectModels copy];

	[_queue runInDatabase:^(FMDatabase *database) {

		[createStatements enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {

			if  ([[line lowercaseString] hasPrefix:@"create "]) {
				[database executeUpdate:line];
			}
		}];
	}];

	return self;
}


- (QSObjectModel *)objectModelForClassName:(NSString *)className {

	return self.objectModelDictionary[className];
}


- (QSTable *)objectTableForClass:(Class)class {

	return [self objectModelForClassName:NSStringFromClass(class)].table;
}


@end



@implementation QSObjectModel


#pragma mark - Init

- (instancetype)initWithClassName:(NSString *)className dictionary:(NSDictionary *)dictionary dataModel:(QSDataModel *)dataModel {

	self = [super init];
	if (self == nil) {
		return nil;
	}

	_dataModel = dataModel;
	_relationshipModelDictionary = [NSMutableDictionary new];
	_className = className;
	_tableName = dictionary[@"table"];
	_immutable = [dictionary qs_boolForKey:@"immutable"];
	_uniqued = [dictionary qs_boolForKey:@"uniqued"];
	
	_table = [[QSTable alloc] initWithObjectModel:self queue:dataModel.queue];

	_propertiesModel = dictionary[@"properties"];

	NSMutableArray *relationshipModels = [NSMutableArray new];
	NSMutableArray *relationshipNames = [NSMutableArray new];
	NSDictionary *relationships = dictionary[@"relationships"];

	for (NSString *oneRelationshipName in [relationships allKeys]) {

		[relationshipNames addObject:oneRelationshipName];

		NSDictionary *oneRelationshipDictionary = relationships[oneRelationshipName];
		QSRelationshipModel *oneRelationshipModel = [[QSRelationshipModel alloc] initWithName:oneRelationshipName dictionary:oneRelationshipDictionary dataModel:dataModel];

		[relationshipModels addObject:oneRelationshipModel];

		_relationshipModelDictionary[oneRelationshipName] = oneRelationshipModel;
	}

	_relationshipModels = [relationshipModels copy];
	_relationshipNames = [relationshipNames copy];

	return self;
}


- (QSRelationshipModel *)relationshipModelForClassName:(NSString *)className {

	return self.relationshipModelDictionary[className];
}


- (QSRelationshipModel *)relationshipModelForName:(NSString *)name {

	return [self.relationshipModels qs_firstObjectWhereValueForKey:@"relationshipName" equalsValue:name];
}


- (QSLookupTable *)lookupTableForRelationship:(NSString *)relationshipName {

	QSRelationshipModel *relationshipModel = [self relationshipModelForName:relationshipName];
	return relationshipModel.lookupTable;
}


@end


@implementation QSRelationshipModel

@synthesize childTable = _childTable;
@synthesize lookupTable = _lookupTable;


#pragma mark - Init

- (instancetype)initWithName:(NSString *)name dictionary:(NSDictionary *)dictionary dataModel:(QSDataModel *)dataModel {

	self = [super init];
	if (self == nil) {
		return nil;
	}

	_dataModel = dataModel;
	_relationshipName = name;
	_tableName = dictionary[@"table"];
	_parentIDName = dictionary[@"parentID"];
	_childIDName = dictionary[@"childID"];
	_indexKey = dictionary[@"indexKey"];
	_childClassName = dictionary[@"childClass"];

	_lookupTable = [[QSLookupTable alloc] initWithTableName:_tableName parentIDKey:_parentIDName childIDKey:_childIDName indexKey:_indexKey];

	return self;
}


#pragma mark - Accessors

- (QSTable *)childTable {

	if (_childTable == nil) {
		QSObjectModel *objectModel = [self.dataModel objectModelForClassName:self.childClassName];
		_childTable = objectModel.table;
	}

	return _childTable;
}


@end

