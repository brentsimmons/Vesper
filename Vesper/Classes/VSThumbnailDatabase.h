//
//  VSThumbnailDatabase.h
//  Vesper
//
//  Created by Brent Simmons on 3/15/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@class VSThumbnail;


/*All methods are thread-safe.*/


@interface VSThumbnailDatabase : NSObject

+ (instancetype)sharedDatabase;

- (void)saveThumbnails:(NSArray *)thumbnails;
- (void)saveThumbnail:(VSThumbnail *)thumbnail;

- (void)fetchThumbnails:(NSArray *)attachmentIDs callback:(QSFetchResultsBlock)callback;

- (void)deleteThumbnails:(NSArray *)attachmentIDs;

- (void)deleteUnreferencedThumbnails:(NSArray *)referencedAttachmentIDs;

@end

