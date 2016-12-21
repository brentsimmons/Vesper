//
//  ServerAttachment.m
//  Vesper
//
//  Created by Brent Simmons on 11/26/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "ServerAttachment.h"

@implementation ServerAttachment

static NSString *kMimeTypeKey = @"mimeType";
static NSString *kWidthKey = @"width";
static NSString *kHeightKey = @"height";

+ (instancetype)objectWithJSONDictionary:(NSDictionary *)JSONDictionary {

	ServerAttachment *attachment = [super objectWithJSONDictionary:JSONDictionary];

	attachment.mimeType = [JSONDictionary qs_objectForKeyNotNSNull:kMimeTypeKey];

	NSNumber *width = [JSONDictionary qs_objectForKeyNotNSNull:kWidthKey];
	if (width) {
		attachment.width = width.longLongValue;
	}

	NSNumber *height = [JSONDictionary qs_objectForKeyNotNSNull:kHeightKey];
	if (height) {
		attachment.height = height.longLongValue;
	}

	return attachment;
}

@end
