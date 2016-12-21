//
//  QSObjectSpecifier.m
//  Vesper
//
//  Created by Brent Simmons on 3/2/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSObjectSpecifier.h"

@interface QSObjectSpecifier ()

@property (nonatomic, readwrite) NSString *className;
@property (nonatomic, readwrite) id uniqueID;

@end


@implementation QSObjectSpecifier


+ (NSArray *)objectSpecifiersWithObjects:(NSArray *)objects className:(NSString *)className {

	NSMutableArray *objectSpecifiers = [NSMutableArray new];

	for (id oneObject in objects) {

		id uniqueID = [oneObject valueForKey:@"uniqueID"];
		[objectSpecifiers addObject:[self objectSpecifierWithClassName:className uniqueID:uniqueID]];
	}

	return [objectSpecifiers copy];
}


+ (QSObjectSpecifier *)objectSpecifierWithObject:(id)obj {

	NSString *className = NSStringFromClass([obj class]);
	id uniqueID = [obj valueForKey:@"uniqueID"];

	return [self objectSpecifierWithClassName:className uniqueID:uniqueID];
}



+ (QSObjectSpecifier *)objectSpecifierWithClassName:(NSString *)className uniqueID:(id)uniqueID {

	QSObjectSpecifier *objectSpecifier = [QSObjectSpecifier new];

	objectSpecifier.className = className;
	objectSpecifier.uniqueID = uniqueID;

	return objectSpecifier;
}


@end
