//
//  VSMergeTagsTests.m
//  Vesper
//
//  Created by Brent Simmons on 6/12/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VSTag.h"
#import "QSDateParser.h"
#import "VSSyncUtilities.h"


@interface VSMergeTagsTests : XCTestCase

@end

@implementation VSMergeTagsTests


- (void)testMergeTagNameProperty {

	/*Sync tag name newer.*/

	VSTag *tag = [[VSTag alloc] initWithName:@"Test"];
	tag.nameModificationDate = QSDateWithString(@"2014-05-01T00:00:00+00:00");
	NSDictionary *JSONTag = @{@"name" : @"test", @"nameModificationDate" : @"2014-06-01T00:00:00+00:00"};
	XCTAssertTrue(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"test");
	XCTAssertEqualObjects(tag.nameModificationDate, QSDateWithString(JSONTag[@"nameModificationDate"]));

	tag = [[VSTag alloc] initWithName:@"Test"];
	tag.nameModificationDate = QSDateWithString(@"2014-05-01T00:00:00+00:00");
	JSONTag = @{@"name" : @"test", @"nameModificationDate" : [NSDate date]};
	XCTAssertTrue(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"test");
	XCTAssertEqualObjects(tag.nameModificationDate, JSONTag[@"nameModificationDate"]);

	/*Existing tag name newer.*/

	tag = [[VSTag alloc] initWithName:@"Test2"];
	NSDate *tagNameModificationDate = tag.nameModificationDate;
	JSONTag = @{@"name" : @"test2", @"nameModificationDate" : QSDateWithString(@"2014-05-01T00:00:00+00:00")};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

	tag = [[VSTag alloc] initWithName:@"Test2"];
	tagNameModificationDate = tag.nameModificationDate;
	JSONTag = @{@"name" : @"test2", @"nameModificationDate" : @"2014-05-01T00:00:00+00:00"};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

	/*JSON missing and weird values*/

	JSONTag = @{};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

	JSONTag = @{@"name" : [NSNull null]};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

	JSONTag = @{@"name" : @"foo"};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

	JSONTag = @{@"nameModificationDate" : @"foo"};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

	JSONTag = @{@"name" : @"boogens", @"nameModificationDate" : @"foo"};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

	JSONTag = @{@"name" : @"boogens", @"nameModificationDate" : [NSNull null]};
	XCTAssertFalse(VSSyncProperty(tag, JSONTag, @"name"));
	XCTAssertEqualObjects(tag.name, @"Test2");
	XCTAssertEqualObjects(tag.nameModificationDate, tagNameModificationDate);

}

@end
