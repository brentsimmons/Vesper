//
//  QSDataObjectDeleter.m
//  Vesper
//
//  Created by Brent Simmons on 3/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSDataObjectDeleter.h"
#import "QSDatabaseUtilities.h"
#import "QSDataModel.h"
#import "QSDatabaseQueue.h"


@implementation QSDataObjectDeleter


+ (void)deleteObjectsWithSpecifiers:(NSArray *)objectSpecifiers objectModel:(QSObjectModel *)objectModel database:(FMDatabase *)database {

	NSArray *uniqueIDs = [objectSpecifiers valueForKeyPath:QSUniqueIDKey];
	if (QSIsEmpty(uniqueIDs)) {
		return;
	}

	QSDatabaseDeleteRowsWithUniqueIDs(uniqueIDs, QSUniqueIDKey, objectModel.tableName, database);

	for (QSRelationshipModel *oneRelationshipModel in objectModel.relationshipModels) {

		QSDatabaseDeleteRowsWithUniqueIDs(uniqueIDs, QSUniqueIDKey, oneRelationshipModel.tableName, database);
	}
}


+ (void)deleteObjectSpecifiers:(NSArray *)objectSpecifiers objectModel:(QSObjectModel *)objectModel queue:(QSDatabaseQueue *)queue {

	[queue update:^(FMDatabase *database) {

		[self deleteObjectsWithSpecifiers:objectSpecifiers objectModel:objectModel database:database];
	}];
}


@end
