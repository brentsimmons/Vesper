//
//  VSAttachmentSyncData.h
//  Vesper
//
//  Created by Brent Simmons on 11/25/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//



@interface VSAttachmentSyncData : NSObject


- (void)addUniqueIDOfAttachmentCreatedLocally:(NSString *)uniqueID;

- (void)uniqueIDsOfAttachmentsToUpload:(QSFetchResultsBlock)fetchResultsBlock;


@end
