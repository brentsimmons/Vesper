//
//  VSSyncTagMerger.m
//  Vesper
//
//  Created by Brent Simmons on 11/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSSyncTagMerger.h"
#import "VSSyncUtilities.h"


static BOOL mergeTag(NSDictionary *JSONTag, VSTag *existingTag) {

	return VSSyncProperty(existingTag, JSONTag, @"name");
}


void VSSyncMergeTags(NSArray *JSONTags, VSDataController *dataController, QSVoidCompletionBlock completion) {

	NSMutableArray *tagsToSave = [NSMutableArray new];

	for (NSDictionary *oneJSONTag in JSONTags) {

		NSString *oneSyncTagName = oneJSONTag[VSSyncNameKey];
		if (QSStringIsEmpty(oneSyncTagName)) {
			continue;
		}

		VSTag *oneTag = [[VSDataController sharedController] tagWithName:oneSyncTagName];
		if (mergeTag(oneJSONTag, oneTag)) {
			[tagsToSave addObject:oneTag];
		}
	}

	[dataController saveTags:[tagsToSave copy]];

	QSCallCompletionBlock(completion);
}
