//
//  QSRelationship.h
//  Vesper
//
//  Created by Brent Simmons on 3/2/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

@import Foundation;

@class FMResultSet;
@class QSRelationshipModel;


@interface QSRelationship : NSObject

@property (nonatomic, readonly) NSSet *relationshipItems; /*QSRelationshipItem*/
@property (nonatomic, readonly) NSArray *sortedRelationshipItems; /*sorted by ix*/
@property (nonatomic, readonly) id parentID;
@property (nonatomic, readonly) NSSet *childIDs; /*All childIDs referenced in relationshipItems.*/

/*Returns dictionary of QSRelationships keyed by parent ID.*/

+ (NSDictionary *)relationshipsWithResultSet:(FMResultSet *)rs relationshipModel:(QSRelationshipModel *)relationshipModel;

+ (NSSet *)childIDsInRelationships:(NSDictionary *)relationships; /*Distinct childIDs, to make fetching efficient.*/

+ (QSRelationship *)relationshipInRelationships:(NSDictionary *)relationships parentID:(id)parentID;

@end


@interface QSRelationshipItem : NSObject

@property (nonatomic, readonly) id parentID;
@property (nonatomic, readonly) id childID;
@property (nonatomic, readonly) int64_t ix;


@end
