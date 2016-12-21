//
//  QSRelationship.m
//  Vesper
//
//  Created by Brent Simmons on 3/2/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSRelationship.h"
#import "FMResultSet.h"
#import "QSDataModel.h"


@interface QSRelationshipItem ()

@property (nonatomic, readwrite) id parentID;
@property (nonatomic, readwrite) id childID;
@property (nonatomic, assign, readwrite) int64_t ix;

+ (QSRelationshipItem *)relationshipItemWithRow:(FMResultSet *)rs relationshipModel:(QSRelationshipModel *)relationshipModel;

@end


@interface QSRelationship ()

@property (nonatomic) NSMutableSet *mutableRelationshipItems;
@property (nonatomic, readwrite) id parentID;

- (void)addRelationshipItem:(QSRelationshipItem *)relationshipItem;

@end


@implementation QSRelationship


#pragma mark - Class Methods

+ (NSArray *)relationshipsWithResultSet:(FMResultSet *)rs relationshipModel:(QSRelationshipModel *)relationshipModel {

	NSMutableDictionary *relationships = [NSMutableDictionary new];

	while ([rs next]) {

		QSRelationshipItem *oneRelationshipItem = [QSRelationshipItem relationshipItemWithRow:rs relationshipModel:relationshipModel];

		id parentID = oneRelationshipItem.parentID;

		QSRelationship *relationship = relationships[parentID];
		if (!relationship) {
			relationship = [QSRelationship new];
			relationship.parentID = parentID;
			relationships[parentID] = relationship;
		}

		[relationship addRelationshipItem:oneRelationshipItem];
	}

	return [relationships copy];
}


+ (NSSet *)childIDsInRelationships:(NSDictionary *)relationships {

	NSMutableSet *childIDs = [NSMutableSet new];

	for (QSRelationship *oneRelationship in relationships) {
		NSSet *oneChildIDs = oneRelationship.childIDs;
		if (!QSIsEmpty(oneChildIDs)) {
			[childIDs unionSet:oneChildIDs];
		}
	}

	return childIDs;
}


+ (QSRelationship *)relationshipInRelationships:(NSDictionary *)relationships parentID:(id)parentID {

	return relationships[parentID];
}


#pragma mark - Init

- (instancetype) init {
	self = [super init];
	if (self == nil) {
		return nil;
	}

	_mutableRelationshipItems = [NSMutableSet new];

	return self;
}


#pragma mark - Relationship items

- (void)addRelationshipItem:(QSRelationshipItem *)relationshipItem {
	[self.mutableRelationshipItems addObject:relationshipItem];
}


- (NSSet *)relationshipItems {
	return [self.mutableRelationshipItems copy];
}


- (NSArray *)sortedRelationshipItems {

	NSMutableArray *sortedItems = [[self.relationshipItems allObjects] mutableCopy];
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"ix" ascending:YES];
	[sortedItems sortUsingDescriptors:@[sortDescriptor]];

	return [sortedItems copy];
}


- (NSSet *)childIDs {

	NSArray *childIDs = [self.relationshipItems valueForKeyPath:@"childID"];
	return [NSSet setWithArray:childIDs];
}


#pragma mark - NSObject

- (NSUInteger)hash {

	/*We don't have anything stable to hash.
	 I'd use [self.relationshipItems count], but this object
	 is put in a dictionary as soon it's created,
	 and that count will change as relationship items are added.
	 So it's gonna be 8. Everyone likes 8.*/

	return 8;
}


- (BOOL)isEqual:(id)object {

	if (!object || ![object isKindOfClass:[self class]]) {
		return NO;
	}

	QSRelationship *otherRelationship = (QSRelationship *)object;
	if (self.parentID != otherRelationship.parentID) {
		return NO;
	}

	return [otherRelationship.relationshipItems isEqual:self.relationshipItems];
}


@end


@implementation QSRelationshipItem


#pragma mark - Class Methods

+ (QSRelationshipItem *)relationshipItemWithRow:(FMResultSet *)rs relationshipModel:(QSRelationshipModel *)relationshipModel {

	QSRelationshipItem *relationship = [QSRelationshipItem new];

	relationship.parentID = [rs objectForColumnName:relationshipModel.parentIDName];
	relationship.childID = [rs objectForColumnName:relationshipModel.childIDName];
	relationship.ix = [rs longLongIntForColumn:relationshipModel.indexKey];

	return relationship;
}


#pragma mark - NSObject

- (NSUInteger)hash {
	return (NSUInteger)self.ix;
}


- (BOOL)isEqual:(id)object {

	if (!object || ![object isKindOfClass:[self class]]) {
		return NO;
	}

	QSRelationshipItem *otherItem = (QSRelationshipItem *)object;
	return otherItem.ix == self.ix && [otherItem.parentID isEqual:self.parentID] && [otherItem.childID isEqual:self.childID];
}

@end
