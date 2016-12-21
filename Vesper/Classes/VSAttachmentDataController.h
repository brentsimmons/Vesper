//
//  VSAttachmentDataController
//  Vesper
//
//  Created by Brent Simmons on 2/18/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VSAttachmentData;


/*Thread safe. Async. Callbacks will be called on any thread.*/

NSString *VSSaveImageAttachmentAndCreateThumbnail(QS_IMAGE *image, NSString *uniqueID); /*Returns mimeType; call from background thread only*/

void VSSaveAttachmentData(NSData *data, NSString *uniqueID);

void VSFetchAttachmentData(NSArray *uniqueIDs, QSFetchResultsBlock fetchResultsBlock); /*VSAttachmentData*/

typedef void (^VSAttachmentDataResultBlock)(VSAttachmentData *attachmentData);

void VSFetchAttachment(NSString *uniqueID, VSAttachmentDataResultBlock callback);

void VSFetchImageAttachment(NSString *uniqueID, QSImageResultBlock callback);

NSString *VSPathForAttachmentID(NSString *uniqueID); /*Attachment may not exist on disk.*/

void VSDeleteAttachmentDataWithUniqueIDs(NSArray *uniqueIDs);

unsigned long long VSContentLengthForAttachmentID(NSString *uniqueID);

void VSMD5ForAttachmentID(NSString *uniqueID, QSDataResultBlock callback); /*Calls back on main thread.*/

void VSAttachmentUniqueIDsOnDisk(QSFetchResultsBlock callback); /*Passes nil to callback in case of an error. Empty array if no files.*/
