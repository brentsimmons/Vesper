//
//  VSThumbnail.m
//  Vesper
//
//  Created by Brent Simmons on 3/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSThumbnail.h"
#import "VSThumbnailRenderer.h"
#import "VSThumbnailDatabase.h"
#import "VSAttachment.h"
#import "VSAttachmentData.h"
#import "VSAttachmentStorage.h"


@implementation VSThumbnail


static VSThumbnailRenderer *imageRenderer = nil;


+ (void)initialize {
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		
		imageRenderer = [VSThumbnailRenderer new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageAttachmentSaved:) name:VSDidSaveImageAttachmentNotification object:nil];
		
	});
}


#pragma mark - Notifications

+ (void)imageAttachmentSaved:(NSNotification *)note {
	
	QS_IMAGE *image = [note userInfo][QSImageKey];
	NSString *attachmentID = [note userInfo][QSUniqueIDKey];
	
	if (!image || !attachmentID) {
		return;
	}
	
	[self renderAndSaveThumbnailForImage:image attachmentID:attachmentID thumbnailResultBlock:nil];
}


#pragma mark - Layout

+ (CGRect)thumbnailRectForApparentRect:(CGRect)apparentRect {
	return VSThumbnailActualRectForApparentRect(apparentRect);
}


+ (CGRect)apparentRectForActualRect:(CGRect)actualRect {
	return VSThumbnailApparentRectForActualRect(actualRect);
}


#pragma mark - Notifications

NSString *VSThumbnailRenderedNotification = @"VSThumbnailRenderedNotification";
NSString *VSThumbnailKey = @"VSThumbnailKey";

+ (void)sendThumbnailRenderedNotifications:(NSArray *)thumbnails {
	
	dispatch_async(dispatch_get_main_queue(), ^{
		
		for (VSThumbnail *oneThumbnail in thumbnails)
			[[NSNotificationCenter defaultCenter] postNotificationName:VSThumbnailRenderedNotification object:self userInfo:@{VSThumbnailKey : oneThumbnail}];
	});
}


#pragma mark - API

+ (void)renderAndSaveThumbnailForAttachmentID:(NSString *)attachmentID thumbnailResultBlock:(QSThumbnailResultBlock)thumbnailResultBlock {
	
	NSParameterAssert(!QSIsEmpty(attachmentID));
	NSParameterAssert(thumbnailResultBlock != nil);
	
	[[VSAttachmentStorage sharedStorage] fetchBestImageAttachment:attachmentID callback:^(QS_IMAGE *image) {
		
		[self renderAndSaveThumbnailForImage:image attachmentID:attachmentID thumbnailResultBlock:thumbnailResultBlock];
	}];
}


+ (void)renderAndSaveThumbnailForImage:(QS_IMAGE *)image attachmentID:(NSString *)attachmentID thumbnailResultBlock:(QSThumbnailResultBlock)thumbnailResultBlock {
	
	if (!image) {
		return;
	}
	
	NSParameterAssert(attachmentID != nil);
	
	[imageRenderer renderThumbnailWithImage:image imageResultBlock:^(QS_IMAGE *renderedImage) {
		
		if (renderedImage == nil) {
			return;
		}
		
		VSThumbnail *thumbnail = [VSThumbnail new];
#if TARGET_OS_IPHONE
		thumbnail.scale = (NSUInteger)[UIScreen mainScreen].scale;
#else
		thumbnail.scale = 1;
#endif
		thumbnail.image = renderedImage;
		thumbnail.uniqueID = attachmentID;
		
		[[VSThumbnailDatabase sharedDatabase] saveThumbnail:thumbnail];
		
		[self sendThumbnailRenderedNotifications:@[thumbnail]];
		
		if (thumbnailResultBlock != nil) {
			thumbnailResultBlock(thumbnail);
		}
	}];
}


@end
