//
//  VSTagSuggester.m
//  Vesper
//
//  Created by Brent Simmons on 3/30/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSTagSuggester.h"


@implementation VSTagSuggester


+ (NSArray *)tags:(NSArray *)tags matchingSearchString:(NSString *)searchString {

	if ([tags count] < 1) {
		return nil;
	}

	NSMutableArray *foundTags = [NSMutableArray new];
	NSSet *tagsToSearch = [NSSet setWithArray:tags];

	/*Do increasingly-fuzzy matches.*/

	NSSet *filteredTags = [tagsToSearch filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", searchString]];
	[foundTags addObjectsFromArray:[filteredTags allObjects]];

	filteredTags = [tagsToSearch filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name beginswith[cd] %@", searchString]];
	for (id oneTag in filteredTags) {
		if (![foundTags containsObject:oneTag]) {
			[foundTags addObject:oneTag];
		}
	}

	filteredTags = [tagsToSearch filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name contains %@", searchString]];
	for (id oneTag in filteredTags) {
		if (![foundTags containsObject:oneTag]) {
			[foundTags addObject:oneTag];
		}
	}

	filteredTags = [tagsToSearch filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@", searchString]];
	for (id oneTag in filteredTags) {
		if (![foundTags containsObject:oneTag]) {
			[foundTags addObject:oneTag];
		}
	}
	
	return foundTags;
}


@end
