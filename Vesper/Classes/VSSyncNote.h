//
//  VSSyncNote.h
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@interface VSSyncNote : VSSyncObject



@property (nonatomic) NSNumber *clientID;
@property (nonatomic) NSDate *creationDate;

@property (nonatomic) NSString *text;
@property (nonatomic) NSDate *textModificationDate;

@property (nonatomic, assign) BOOL archived;
@property (nonatomic) NSDate *archivedModificationDate;

@property (nonatomic) NSDate *sortDate;
@property (nonatomic) NSDate *sortDateModificationDate;

@property (nonatomic) NSArray *tagUniqueIDs;
@property (nonatomic) NSDate *tagsModificationDate;

@property (nonatomic) NSArray *attachments;
@property (nonatomic) NSDate *attachmentsModificationDate;


@end
