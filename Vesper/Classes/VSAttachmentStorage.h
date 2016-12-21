//
//  VSAttachmentStorage.h
//  Vesper
//
//  Created by Brent Simmons on 7/21/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

@import Foundation;


extern NSString *VSDidSaveImageAttachmentNotification; /*userInfo - QSUniqueIDKey, QSImageKey*/


@interface VSAttachmentStorage : NSObject


+ (instancetype)sharedStorage;

- (instancetype)initWithFolder:(NSString *)folder;


- (NSString *)pathForAttachmentID:(NSString *)attachmentID;

- (void)saveAttachmentData:(NSData *)data attachmentID:(NSString *)attachmentID;

- (void)fetchAttachments:(NSArray *)attachmentIDs callback:(QSFetchResultsBlock)callback; /*Array of VSAttachmentData*/

- (void)deleteAttachments:(NSArray *)attachmentIDs;

- (void)contentLengthForAttachment:(NSString *)attachmentID callback:(QSObjectResultBlock)callback; /*NSNumber*/

- (void)md5ForAttachment:(NSString *)attachmentID callback:(QSObjectResultBlock)callback; /*NSData*/

- (void)attachmentIDs:(QSFetchResultsBlock)callback; /*NSString*/

- (void)attachmentIDsSortedByFileSize:(QSFetchResultsBlock)callback; /*Smallest to largest.*/

- (void)attachmentIsImage:(NSString *)attachmentID callback:(QSObjectResultBlock)callback; /*NSNumber (BOOL)*/


typedef NS_ENUM(NSUInteger, VSImageQuality) {
	VSImageQualityFull,
	VSImageQualityLow
};

- (NSString *)filenameForImage:(NSString *)attachmentID imageQuality:(VSImageQuality)imageQuality;

- (NSString *)pathForImage:(NSString *)attachmentID imageQuality:(VSImageQuality)imageQuality;

- (NSString *)saveImageAttachment:(QS_IMAGE *)image attachmentID:(NSString *)attachmentID; /*Returns mime type. Saves full and low versions.*/

- (void)fetchImageAttachment:(NSString *)attachmentID imageQuality:(VSImageQuality)imageQuality callback:(QSImageResultBlock)callback;

- (void)fetchBestImageAttachment:(NSString *)attachmentID callback:(QSImageResultBlock)callback; /*Fetches full if it exists.*/

- (void)deleteImages:(NSArray *)attachmentIDs; /*Deletes full and low versions.*/

- (void)lowQualityImages:(QSFetchResultsBlock)callback;

- (void)createLowQualityImageIfNeeded:(NSString *)attachmentID attachmentData:(NSData *)attachmentData;

extern NSString *VSLowQualityImageExtension;


@end
