//
//  VSTag.m
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTag.h"
#import "QSDateParser.h"
#import "VSDateManager.h"


@interface VSTag ()

@property (nonatomic, readwrite) NSString *uniqueID; /*For -copyWithZone*/

@end


@implementation VSTag


#pragma mark - Class Methods

+ (NSString *)uniqueIDForTagName:(NSString *)name {

	NSString *uniqueID = [self normalizedTagName:name];
	uniqueID = [uniqueID lowercaseString];

	return uniqueID;
}


+ (NSString *)normalizedTagName:(NSString *)name {
	return [name qs_stringWithCollapsedWhitespace];
}


#pragma mark - Init

- (instancetype)initWithName:(NSString *)name {

	self = [super init];
	if (!self) {
		return nil;
	}

	_name = name;
	_uniqueID = [[self class] uniqueIDForTagName:name];
	_nameModificationDate = [[VSDateManager sharedManager] currentDate];

	return self;
}


#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {

	VSTag *tag = [[[self class] allocWithZone:zone] init];
	
	tag.name = self.name;
	tag.uniqueID = self.uniqueID;
	tag.nameModificationDate = self.nameModificationDate;

	return tag;
}


#pragma mark - NSObject

- (NSUInteger)hash {
	return [self.uniqueID hash];
}


- (BOOL)isEqual:(id)object {

	if (!object || ![object isKindOfClass:[self class]]) {
		return NO;
	}

	VSTag *otherTag = (VSTag *)object;

	return [self.uniqueID isEqualToString:otherTag.uniqueID] && [self.name isEqualToString:otherTag.name] && [self.nameModificationDate isEqual:otherTag.nameModificationDate];
}


#pragma mark - Accessors

- (void)setName:(NSString *)name {

	if (!_name) {
		_name = name;
		return;
	}

	_name = name;
}


#pragma mark - QSAPIObject

+ (instancetype)objectWithJSONRepresentation:(NSDictionary *)JSONDictionary {

	NSString *name = JSONDictionary[VSSyncNameKey];
	VSTag *tag = [[VSTag alloc] initWithName:name];

	NSString *nameModificationDateString = JSONDictionary[VSSyncNameModificationDateKey];
	if (!QSStringIsEmpty(nameModificationDateString)) {
		tag.nameModificationDate = QSDateWithString(nameModificationDateString);
	}

	return tag;
}


- (NSDictionary *)JSONRepresentation {

	NSMutableDictionary *d = [NSMutableDictionary new];

	d[VSSyncTagIDKey] = self.uniqueID;
	d[VSSyncNameKey] = self.name;

	if (self.nameModificationDate) {
		d[VSSyncNameModificationDateKey] = [self.nameModificationDate qs_iso8601DateString];
	}
	
	return [d copy];
}

@end
