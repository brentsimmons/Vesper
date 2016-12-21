//
//  VSThumbnailCache.h
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


extern NSString *VSThumbnailCachedNotification; /*VSImageKey and QSUniqueIDKey in userInfo.*/


@interface VSThumbnailCache : NSObject


+ (instancetype)sharedCache;

- (void)loadThumbnailsWithAttachmentIDs:(NSArray *)attachmentIDs;

- (QS_IMAGE *)thumbnailForAttachmentID:(NSString *)attachmentID;


@end
