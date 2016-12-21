//
//  VSAttachmentsDatabase.m
//  Vesper
//
//  Created by Brent Simmons on 2/18/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "VSAttachmentDataController.h"
#import "VSAttachmentData.h"
#import "VSThumbnail.h"


static NSString *attachmentsFolderPath = nil;
static dispatch_queue_t serialDispatchQueue;

static void startup(void) {

	static dispatch_once_t pred;

	dispatch_once(&pred, ^{

		NSError *error = nil;
		NSString *documentsFolder = QSDataFolder(nil);
		attachmentsFolderPath = [documentsFolder stringByAppendingPathComponent:@"Attachments"];

#if TARGET_IPHONE_SIMULATOR
		NSLog(@"attachmentsFolderPath: %@", attachmentsFolderPath);
#endif

		if (![[NSFileManager defaultManager] createDirectoryAtPath:attachmentsFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating attachments folder: %@ %@", attachmentsFolderPath, error);
			abort();
		}

		serialDispatchQueue = dispatch_queue_create("VSAttachmentDataController Serial Dispatch Queue", DISPATCH_QUEUE_SERIAL);
	});
}



static NSString *pathWithFilename(NSString *filename) {
	startup();
    return [attachmentsFolderPath stringByAppendingPathComponent:filename];
}


#pragma mark - API

NSString *VSPathForAttachmentID(NSString *uniqueID) {
	return pathWithFilename(uniqueID);
}


NSString *VSSaveImageAttachmentAndCreateThumbnail(QS_IMAGE *image, NSString *uniqueID) {

    assert(image != nil);
    assert(uniqueID != nil);
    
	startup();

    if (image == nil || [uniqueID length] < 1)
        return nil;

#if TARGET_OS_IPHONE
    NSString *mimeType = QSMimeTypeJPEG;
#else
	NSString *mimeType = QSMimeTypeTIFF;
#endif

    @autoreleasepool {

#if TARGET_OS_IPHONE
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
        if (imageData == nil) {
            imageData = UIImagePNGRepresentation(image);
            mimeType = QSMimeTypePNG;
        }
#else
		NSData *imageData = [image TIFFRepresentation];
#endif

        if (imageData == nil)
            return nil;

        VSSaveAttachmentData(imageData, uniqueID);
    }

    [VSThumbnail renderAndSaveThumbnailForImage:image attachmentID:uniqueID thumbnailResultBlock:nil];

    return mimeType;
}


void VSSaveAttachmentData(NSData *data, NSString *uniqueID) {

    startup();

    dispatch_async(serialDispatchQueue, ^{

        @autoreleasepool {
            NSError *error = nil;
            NSString *path = pathWithFilename(uniqueID);
            if (![data writeToFile:path options:NSDataWritingAtomic error:&error])
                NSLog(@"Error writing to %@: %@", path, error);
        }
    });
}


void VSFetchAttachmentData(NSArray *uniqueIDs, QSFetchResultsBlock fetchResultsBlock) {

    startup();
    
    dispatch_async(serialDispatchQueue, ^{

        NSMutableArray *fetchedObjects = [NSMutableArray new];

        @autoreleasepool {

            for (NSString *oneUniqueID in uniqueIDs) {

                NSError *error = nil;
                NSString *path = pathWithFilename(oneUniqueID);
                NSData *oneFileData = [NSData dataWithContentsOfFile:path options:0 error:&error];
//                if (oneFileData == nil) {
//                    NSLog(@"Error reading %@: %@", path, error);
//                    continue;
//                }

                VSAttachmentData *attachmentData = [VSAttachmentData new];
                attachmentData.uniqueID = oneUniqueID;
                attachmentData.binaryData = oneFileData;
				attachmentData.path = path;

                [fetchedObjects qs_safeAddObject:attachmentData];
            }
        }

        @autoreleasepool {
            if (fetchResultsBlock != nil)
                fetchResultsBlock(fetchedObjects);
        }
        
    });
}


void VSFetchAttachment(NSString *uniqueID, VSAttachmentDataResultBlock callback) {

	startup();
    if ([uniqueID length] < 1)
        return;

    VSFetchAttachmentData(@[uniqueID], ^(NSArray *fetchedObjects) {

        VSAttachmentData *attachmentData = [fetchedObjects qs_safeObjectAtIndex:0];
        callback(attachmentData);
    });
}


void VSFetchImageAttachment(NSString *uniqueID, QSImageResultBlock callback) {

	startup();

    VSFetchAttachment(uniqueID, ^(VSAttachmentData *attachmentData) {

        if (attachmentData == nil)
            return;
#if TARGET_OS_IPHONE
        UIImage *image = [UIImage imageWithData:attachmentData.binaryData];
#else
		NSImage *image = [[NSImage alloc] initWithData:attachmentData.binaryData];
#endif

        callback(image);
    });
}


static void VSDeleteAttachmentDataWithUniqueID(NSString *uniqueID) {

	startup();

	@autoreleasepool {
		NSString *path = pathWithFilename(uniqueID);
		NSError *error  = nil;
		if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error] && error != nil) {
			NSLog(@"delete file error: %@", error);
		}
	}
}


void VSDeleteAttachmentDataWithUniqueIDs(NSArray *uniqueIDs) {

	startup();

	dispatch_async(serialDispatchQueue, ^{
		@autoreleasepool {

			for (NSString *oneUniqueID in uniqueIDs) {
				VSDeleteAttachmentDataWithUniqueID(oneUniqueID);
			}
		}
	});
}


unsigned long long VSContentLengthForAttachmentID(NSString *uniqueID) {

	NSCParameterAssert(uniqueID != nil);

	startup();

	NSString *path = VSPathForAttachmentID(uniqueID);
	if (QSStringIsEmpty(path)) {
		return 0;
	}

	NSError *error = nil;
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
	if (!fileAttributes) {
		return 0;
	}

	return [fileAttributes fileSize];
}


void VSMD5ForAttachmentID(NSString *uniqueID, QSDataResultBlock callback) {

	assert(uniqueID != nil);
	assert(callback != nil);

	startup();

	NSString *path = VSPathForAttachmentID(uniqueID);
	if (QSStringIsEmpty(path)) {
		QSCallBlockWithParameter(callback, nil);
	}

	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	if (fileHandle == nil) {
		QSCallBlockWithParameter(callback, nil);
	}

	dispatch_async(serialDispatchQueue, ^{

		@autoreleasepool {

			CC_MD5_CTX md5;
			CC_MD5_Init(&md5);

			while(true) {

				@autoreleasepool {
					NSData *d = [fileHandle readDataOfLength:1024 * 1024];
					CC_MD5_Update(&md5, [d bytes], (CC_LONG)[d length]);
					if ([d length] < 1) {
						break;
					}
				}
			}

			unsigned char hash[CC_MD5_DIGEST_LENGTH];
			CC_MD5_Final(hash, &md5);

			NSData *hashData = [NSData dataWithBytes:(const void *)hash length:CC_MD5_DIGEST_LENGTH];

			QSCallBlockWithParameter(callback, hashData);
		}
	});
}


void VSAttachmentUniqueIDsOnDisk(QSFetchResultsBlock callback) {

	startup();

	dispatch_async(serialDispatchQueue, ^{

		@autoreleasepool {

			NSError *error = nil;
			NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:attachmentsFolderPath error:&error];
			if (error != nil) {
				dispatch_async(dispatch_get_main_queue(), ^{
					callback(nil);
				});
				return;
			}

			NSMutableArray *uniqueIDs = [NSMutableArray new];

			for (NSString *oneFilename in fileNames) {

				/*Simple check to make sure it's actually an attachment.*/

				if ([oneFilename rangeOfString:@"."].length > 0 || [oneFilename rangeOfString:@"-"].length < 1) {
					continue;
				}

				[uniqueIDs addObject:oneFilename];
			}

			QSCallFetchResultsBlock(callback, [uniqueIDs copy]);
		}
	});
}



