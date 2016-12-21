//
//  VSJSONTagsTests.m
//  Vesper
//
//  Created by Brent Simmons on 6/12/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface VSJSONTagsTests : XCTestCase

@end

@implementation VSJSONTagsTests


- (void)testJSONRepresentation {

	VSTag *tag = [[VSTag alloc] initWithName:@"Test"];
	NSDictionary *JSONTag = [tag JSONRepresentation];
	XCTAssertEqualObjects(tag.uniqueID, @"test");
	XCTAssertEqualObjects(JSONTag[@"nameModificationDate"], [tag.nameModificationDate qs_iso8601DateString]);
	XCTAssertEqualObjects(tag.name, @"Test");

	tag = [[VSTag alloc] initWithName:@"Test "];
	JSONTag = [tag JSONRepresentation];
	XCTAssertEqualObjects(tag.uniqueID, @"test");
	XCTAssertEqualObjects(JSONTag[@"nameModificationDate"], [tag.nameModificationDate qs_iso8601DateString]);
	XCTAssertEqualObjects(tag.name, @"Test ");

	tag = [[VSTag alloc] initWithName:@"\t\t\nTest \n"];
	JSONTag = [tag JSONRepresentation];
	XCTAssertEqualObjects(tag.uniqueID, @"test");
	XCTAssertEqualObjects(JSONTag[@"nameModificationDate"], [tag.nameModificationDate qs_iso8601DateString]);
	XCTAssertEqualObjects(tag.name, @"\t\t\nTest \n");

}


- (void)testObjectWithJSONRepresentation {

	NSDate *now = [NSDate date];
	NSDictionary *JSONTag = @{@"name" : @"Test", @"nameModificationDate" : [now qs_iso8601DateString]};
	VSTag *tag = [VSTag objectWithJSONRepresentation:JSONTag];
	XCTAssertEqualObjects(JSONTag[@"name"], tag.name);
	XCTAssertEqualObjects(@"test", tag.uniqueID);

	NSTimeInterval nowTimeInterval = [now timeIntervalSince1970];
	NSTimeInterval tagTimeInterval = [tag.nameModificationDate timeIntervalSince1970];
	XCTAssertEqualWithAccuracy(nowTimeInterval, tagTimeInterval, 0.001);
}

@end
