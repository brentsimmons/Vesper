//
//  VSAttachment.m
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSAttachment.h"
#import "VSSyncConstants.h"
#import "VSAttachmentStorage.h"


@interface VSAttachment ()

@property (nonatomic, readwrite) NSString *uniqueID;
@property (nonatomic, readwrite) NSString *mimeType;
@property (nonatomic, assign, readwrite) int64_t height;
@property (nonatomic, assign, readwrite) int64_t width;

@end


@implementation VSAttachment


#pragma mark - Init

+ (instancetype)attachmentWithUniqueID:(NSString *)uniqueID mimeType:(NSString *)mimeType height:(int64_t)height width:(int64_t)width {
	
	NSParameterAssert(uniqueID != nil);
	NSParameterAssert(mimeType != nil);
	
	VSAttachment *attachment = [VSAttachment new];
	
	attachment.uniqueID = uniqueID;
	attachment.mimeType = mimeType;
	attachment.height = height;
	attachment.width = width;
	
	return attachment;
}


#pragma mark - QSAPIObject

+ (instancetype)objectWithJSONRepresentation:(NSDictionary *)JSONDictionary {
	
	VSAttachment *attachment = [VSAttachment new];
	
	attachment.uniqueID = JSONDictionary[VSSyncUniqueIDKey];
	attachment.mimeType = JSONDictionary[VSSyncMimeTypeKey];
	
	NSNumber *width = JSONDictionary[VSSyncWidthKey];
	if (!width || (id)width == [NSNull null]) {
		attachment.width = 0;
	}
	else {
		attachment.width = [width longLongValue];
	}
	
	NSNumber *height = JSONDictionary[VSSyncHeightKey];
	if (!height || (id)height == [NSNull null]) {
		attachment.height = 0;
	}
	else {
		attachment.height = [height longLongValue];
	}
	
	return attachment;
}


- (NSDictionary *)JSONRepresentation {
	
	NSMutableDictionary *d = [NSMutableDictionary new];
	
	d[VSSyncUniqueIDKey] = self.uniqueID;
	d[VSSyncMimeTypeKey] = self.mimeType;
	d[VSSyncWidthKey] = @(self.width);
	d[VSSyncHeightKey] = @(self.height);
	
	return [d copy];
}

#pragma mark - Convenience

- (BOOL)isImage {
	return QSMimeTypeIsImage(self.mimeType);
}


- (CGSize)size {
	return CGSizeMake((CGFloat)self.width, (CGFloat)self.height);
}


- (NSString *)path {
	return [[VSAttachmentStorage sharedStorage] pathForAttachmentID:self.uniqueID];
}


#pragma mark - JSON Serialization

- (NSDictionary *)JSONDictionary {
	
	NSMutableDictionary *d = [NSMutableDictionary new];
	
	d[VSSyncUniqueIDKey] = self.uniqueID;
	d[VSSyncMimeTypeKey] = self.mimeType;
	d[VSSyncWidthKey] = @(self.width);
	d[VSSyncHeightKey] = @(self.height);
	
	return [d copy];
}


#pragma mark - NSObject

- (NSUInteger)hash {
	
	return [self.uniqueID hash];
}


- (BOOL)isEqual:(id)object {
	
	if (!object || ![object isKindOfClass:[self class]]) {
		return NO;
	}
	
	VSAttachment *otherAttachment = (VSAttachment *)object;
	
	return self.height == otherAttachment.height && self.width == otherAttachment.width && [self.uniqueID isEqualToString:otherAttachment.uniqueID] && [self.mimeType isEqualToString:otherAttachment.mimeType];
}

@end


