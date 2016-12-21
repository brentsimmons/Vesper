//
//  VSAttachmentStorage.m
//  Vesper
//
//  Created by Brent Simmons on 7/21/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "VSAttachmentStorage.h"
#import "VSBinaryCache.h"
#import "VSAttachmentData.h"
#import "NSData+QSKit.h"


@interface VSAttachmentStorage ()

@property (nonatomic) NSString *folder;
@property (nonatomic) VSBinaryCache *binaryCache;
@property (nonatomic) dispatch_queue_t serialDispatchQueue;

@end


@implementation VSAttachmentStorage


#pragma mark - Class Methods

+ (instancetype)sharedStorage {
	
	static id gMyInstance = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		NSString *documentsFolder = QSDataFolder(nil);
		NSString *attachmentsFolder = [documentsFolder stringByAppendingPathComponent:@"Attachments"];
		
		NSError *error = nil;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:attachmentsFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Error creating attachments folder: %@ %@", attachmentsFolder, error);
			abort();
		}
		
#if TARGET_IPHONE_SIMULATOR
		NSLog(@"attachmentsFolder: %@", attachmentsFolder);
#endif
		
		gMyInstance = [[self alloc] initWithFolder:attachmentsFolder];
	});
	
	return gMyInstance;
}


#pragma mark - Init

- (instancetype)initWithFolder:(NSString *)folder {
	
	self = [super init];
	if (!self) {
		return nil;
	}
	
	_folder = folder;
	_binaryCache = [[VSBinaryCache alloc] initWithFolder:folder];
	_serialDispatchQueue = dispatch_queue_create("VSAttachmentStorage Serial Dispatch Queue", DISPATCH_QUEUE_SERIAL);
	
	[self ensureLowQualityImages];
	
	return self;
}


#pragma mark - API

- (NSString *)pathForAttachmentID:(NSString *)attachmentID {
	
	return [self.binaryCache filePathForKey:attachmentID];
}


- (void)saveAttachmentData:(NSData *)data attachmentID:(NSString *)attachmentID {
	
	if (!data || attachmentID.length < 1) {
		return;
	}
	
	dispatch_async(self.serialDispatchQueue, ^{
		[self.binaryCache setBinaryData:data key:attachmentID error:nil];
	});
}


- (void)fetchAttachments:(NSArray *)attachmentIDs callback:(QSFetchResultsBlock)callback {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		NSMutableArray *fetchedObjects = [NSMutableArray new];
		
		@autoreleasepool {
			
			for (NSString *oneAttachmentID in attachmentIDs) {
				
				NSData *d = [self.binaryCache binaryDataForKey:oneAttachmentID error:nil];
				
				if (d) {
					
					VSAttachmentData *attachmentData = [VSAttachmentData new];
					
					attachmentData.uniqueID = oneAttachmentID;
					attachmentData.binaryData = d;
					attachmentData.path = [self pathForAttachmentID:oneAttachmentID];
					
					[fetchedObjects addObject:attachmentData];
				}
			}
		}
		
		QSCallBlockWithParameter(callback, [fetchedObjects copy]);
	});
}


- (void)deleteAttachments:(NSArray *)attachmentIDs {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		for (NSString *oneAttachmentID in attachmentIDs) {
			
			[self.binaryCache removeBinaryDataForKey:oneAttachmentID error:nil];
		}
	});
}


- (void)contentLengthForAttachment:(NSString *)attachmentID callback:(QSObjectResultBlock)callback {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		UInt64 length = [self.binaryCache lengthOfBinaryDataForKey:attachmentID error:nil];
		QSCallBlockWithParameter(callback, @(length));
	});
}


- (void)md5ForAttachment:(NSString *)attachmentID callback:(QSObjectResultBlock)callback {
	
	NSString *f = [self pathForAttachmentID:attachmentID];
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		@autoreleasepool {
			
			CC_MD5_CTX md5;
			CC_MD5_Init(&md5);
			
			NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:f];
			if (fileHandle == nil) {
				QSCallBlockWithParameter(callback, nil);
				return;
			}
			
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


- (void)attachmentIDs:(QSFetchResultsBlock)callback {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		NSError *error = nil;
		NSArray *attachmentIDs = [self.binaryCache allKeys:&error];
		if (error) {
			attachmentIDs = nil;
		}
		
		QSCallBlockWithParameter(callback, attachmentIDs);
	});
}


- (void)attachmentIDsSortedByFileSize:(QSFetchResultsBlock)callback {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		NSArray *objects = [self.binaryCache allObjects:nil];
		
		if (!objects) {
			QSCallBlockWithParameter(callback, nil);
			return;
		}
		
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:VSBinaryLength ascending:YES];
		NSArray *sortedObjects = [objects sortedArrayUsingDescriptors:@[sortDescriptor]];
		NSArray *sortedKeys = [sortedObjects valueForKey:VSBinaryKey];
		
		QSCallBlockWithParameter(callback, sortedKeys);
	});
}


- (void)attachmentIsImage:(NSString *)attachmentID callback:(QSObjectResultBlock)callback {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		NSString *f = [self pathForAttachmentID:attachmentID];
		NSString *mimeType = QSMimeTypeForFile(f);
		
		BOOL isImage = [mimeType hasPrefix:@"image/"];
		
		QSCallBlockWithParameter(callback, @(isImage));
	});
}


#pragma mark - Images

NSString *VSDidSaveImageAttachmentNotification = @"VSDidSaveImageAttachmentNotification";

- (NSString *)saveImageAttachment:(QS_IMAGE *)image attachmentID:(NSString *)attachmentID {
	
	if (!image || attachmentID.length < 1) {
		return nil;
	}
	
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
		
		if (!imageData) {
			return nil;
		}
		
		[self saveAttachmentData:imageData attachmentID:attachmentID];
	}
	
	[self createLowQualityImageIfNeeded:attachmentID highQualityImage:image];
	
	[[NSNotificationCenter defaultCenter] qs_postNotificationNameOnMainThread:VSDidSaveImageAttachmentNotification object:self userInfo:@{QSUniqueIDKey : attachmentID, QSImageKey : image}];
	
	return mimeType;
}


NSString *VSLowQualityImageExtension = @"-low";

- (BOOL)attachmentIDDenotesLowQualityImage:(NSString *)attachmentID {
	
	return [attachmentID hasSuffix:VSLowQualityImageExtension];
}


- (NSString *)filenameForImage:(NSString *)attachmentID imageQuality:(VSImageQuality)imageQuality {
	
	if (imageQuality == VSImageQualityLow) {
		return [attachmentID stringByAppendingString:VSLowQualityImageExtension];
	}
	
	return attachmentID;
}


- (NSString *)pathForImage:(NSString *)attachmentID imageQuality:(VSImageQuality)imageQuality {
	
	NSString *filename = [self filenameForImage:attachmentID imageQuality:imageQuality];
	return [self pathForAttachmentID:filename];
}


- (void)fetchImageAttachment:(NSString *)attachmentID imageQuality:(VSImageQuality)imageQuality callback:(QSImageResultBlock)callback {
	
	NSString *filename = [self filenameForImage:attachmentID imageQuality:imageQuality];
	
	[self fetchAttachments:@[filename] callback:^(NSArray *fetchedObjects) {
		
		VSAttachmentData *attachmentData = [fetchedObjects firstObject];
		if (!attachmentData.binaryData || ![attachmentData.binaryData qs_dataIsImage]) {
			QSCallBlockWithParameter(callback, nil);
			return;
		}
		
		[QS_IMAGE qs_imageWithData:attachmentData.binaryData imageResultBlock:^(QS_IMAGE *image) {
			
			QSCallBlockWithParameter(callback, image);
		}];
	}];
}


- (void)fetchBestImageAttachment:(NSString *)attachmentID callback:(QSImageResultBlock)callback {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		if ([self.binaryCache binaryForKeyExists:attachmentID]) {
			[self fetchImageAttachment:attachmentID imageQuality:VSImageQualityFull callback:callback];
			return;
		}
		
		NSString *filename = [self filenameForImage:attachmentID imageQuality:VSImageQualityLow];
		if ([self.binaryCache binaryForKeyExists:filename]) {
			[self fetchImageAttachment:attachmentID imageQuality:VSImageQualityLow callback:callback];
			return;
		}
		
		QSCallBlockWithParameter(callback, nil);
	});
}


- (void)deleteImages:(NSArray *)attachmentIDs {
	
	[self deleteAttachments:attachmentIDs];
	
	NSMutableArray *filenames = [NSMutableArray new];
	for (NSString *oneAttachmentID in attachmentIDs) {
		NSString *oneFilename = [self filenameForImage:oneAttachmentID imageQuality:VSImageQualityLow];
		[filenames addObject:oneFilename];
	}
	
	[self deleteAttachments:[filenames copy]];
}


- (void)md5ForImageAttachment:(NSString *)attachmentID imageQuality:(VSImageQuality)imageQuality callback:(QSObjectResultBlock)callback {
	
	NSString *filename = [self filenameForImage:attachmentID imageQuality:imageQuality];
	[self md5ForAttachment:filename callback:callback];
}


- (void)lowQualityImages:(QSFetchResultsBlock)callback {
	
	[self attachmentIDs:^(NSArray *attachmentIDs) {
		
		NSMutableArray *lowQualityImageIDs = [NSMutableArray new];
		
		for (NSString *oneAttachmentID in attachmentIDs) {
			
			if ([oneAttachmentID hasSuffix:VSLowQualityImageExtension]) {
				[lowQualityImageIDs addObject:oneAttachmentID];
			}
		}
		
		QSCallBlockWithParameter(callback, [lowQualityImageIDs copy]);
	}];
}


- (void)ensureLowQualityImages {
	
	[self attachmentIDs:^(NSArray *attachmentIDs) {
		
		[self ensureLowQualityImages:attachmentIDs];
	}];
}


- (void)ensureLowQualityImages:(NSArray *)diskAttachmentIDs {
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		@autoreleasepool {
			
			for (NSString *oneAttachmentID in diskAttachmentIDs) {
				
				[self ensureOneLowQualityImage:oneAttachmentID diskAttachmentIDs:diskAttachmentIDs];
			}
		}
	});
}


- (void)ensureOneLowQualityImage:(NSString *)attachmentID diskAttachmentIDs:(NSArray *)diskAttachmentIDs {
	
	@autoreleasepool {
		
		if ([attachmentID hasSuffix:VSLowQualityImageExtension]) { /*Is low-quality version?*/
			return;
		}
		if ([attachmentID hasPrefix:@"tutorial"]) { /*Tutorial images don't get synced and thus don't need low-quality versions.*/
			return;
		}
		
		NSString *attachmentIDLowQuality = [self filenameForImage:attachmentID imageQuality:VSImageQualityLow];
		if ([diskAttachmentIDs containsObject:attachmentIDLowQuality]) { /*Low-quality version already exists?*/
			return;
		}
		
		[self createLowQualityImage:attachmentID];
	}
}


- (void)createLowQualityImage:(NSString *)attachmentID highQualityImage:(QS_IMAGE *)highQualityImage {
	
	@autoreleasepool {
		
		NSData *imageData = nil;
		
#if TARGET_OS_IPHONE
		
		imageData = UIImageJPEGRepresentation(highQualityImage, 0.3f);
		
#else /*Mac*/
		
		/*TODO: Mac image data*/
		
#endif
		
		if (imageData) {
			
			NSString *lowQualityAttachmentID = [self filenameForImage:attachmentID imageQuality:VSImageQualityLow];
			[self saveAttachmentData:imageData attachmentID:lowQualityAttachmentID];
		}
	}
}


- (void)createLowQualityImage:(NSString *)attachmentID {
	
	@autoreleasepool {
		
		if (!attachmentID || [self attachmentIDDenotesLowQualityImage:attachmentID]) {
			return;
		}
		
		NSString *f = [self pathForAttachmentID:attachmentID];
		QS_IMAGE *image = [QS_IMAGE imageWithContentsOfFile:f];
		
		if (image) {
			[self createLowQualityImage:attachmentID highQualityImage:image];
		}
	}
}


- (BOOL)lowQualityImageForFullQualityAttachmentIDExists:(NSString *)attachmentID {
	
	BOOL isDirectory = NO;
	NSString *filename = [self filenameForImage:attachmentID imageQuality:VSImageQualityLow];
	NSString *f = [self pathForAttachmentID:filename];
	
	return [[NSFileManager defaultManager] fileExistsAtPath:f isDirectory:&isDirectory];
}


- (void)createLowQualityImageIfNeeded:(NSString *)attachmentID highQualityImage:(QS_IMAGE *)highQualityImage {
	
	if (!highQualityImage || [self attachmentIDDenotesLowQualityImage:attachmentID] || [attachmentID hasPrefix:@"tutorial"]) {
		return;
	}
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		@autoreleasepool {
			
			if ([self lowQualityImageForFullQualityAttachmentIDExists:attachmentID]) {
				return;
			}
			
			[self createLowQualityImage:attachmentID highQualityImage:highQualityImage];
		}
	});
}


- (void)createLowQualityImageIfNeeded:(NSString *)attachmentID attachmentData:(NSData *)attachmentData {
	
	if (!attachmentData || [self attachmentIDDenotesLowQualityImage:attachmentID]) { /*is a low-quality image?*/
		return;
	}
	
	dispatch_async(self.serialDispatchQueue, ^{
		
		@autoreleasepool {
			
			if ([self lowQualityImageForFullQualityAttachmentIDExists:attachmentID]) {
				return;
			}
			
			NSString *mimeType = QSMimeTypeForData(attachmentData);
			if (QSMimeTypeIsImage(mimeType)) {
				
				[QS_IMAGE qs_imageWithData:attachmentData imageResultBlock:^(QS_IMAGE *image) {
					
					[self createLowQualityImageIfNeeded:attachmentID highQualityImage:image];
				}];
			}
		}
	});
}


@end
