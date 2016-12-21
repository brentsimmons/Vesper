//
//  VSJSONNoteTests.m
//  Vesper
//
//  Created by Brent Simmons on 6/14/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "QSDateParser.h"
#import "VSDateManager.h"


@interface VSJSONNoteTests : XCTestCase

@end

@implementation VSJSONNoteTests


- (void)testJSONRepresentation {

	NSDate *now = [[VSDateManager sharedManager] currentDate];
	VSNote *note = [VSNote new];
	NSDictionary *JSONNote = [note JSONRepresentation];
	XCTAssertNotNil(JSONNote[@"noteID"]);
	XCTAssertFalse([JSONNote[@"archived"] boolValue]);
	NSDate *creationDate = QSDateWithString(JSONNote[@"creationDate"]);
	NSTimeInterval nowTimeInterval = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval creationDateTimeInterval = [creationDate timeIntervalSince1970];
	XCTAssertEqualWithAccuracy(nowTimeInterval, creationDateTimeInterval, 0.1);

	note.text = @"This is some text.";
	note.textModificationDate = [[VSDateManager sharedManager] currentDate];
	note.archived = YES;
	note.archivedModificationDate = [[VSDateManager sharedManager] currentDate];
	JSONNote = [note JSONRepresentation];
	XCTAssertNotNil(JSONNote[@"noteID"]);
	XCTAssertTrue([JSONNote[@"archived"] boolValue]);
	NSDate *archivedModificationDate = QSDateWithString(JSONNote[@"archivedModificationDate"]);
	XCTAssertTrue([archivedModificationDate earlierDate:now] == now);
	XCTAssertEqualObjects(JSONNote[@"text"], @"This is some text.");
}


- (void)testObjectWithJSONRepresentation {

	NSDate *now = [[VSDateManager sharedManager] currentDate];
	NSDictionary *JSONNote = @{@"noteID" : @(123456987984354), @"text" : @"Some text", @"textModificationDate" : [[[VSDateManager sharedManager] currentDate] qs_iso8601DateString], @"archived" : @(YES), @"archivedModificationDate" : @"2014-06-01T00:00:00.456Z", @"creationDate" : @"2013-06-01T00:00:00.456Z", @"sortDate" : @"2014-04-01T02:03:04.456Z", @"sortDateModificationDate" : [NSNull null], @"tagsModificationDate" : @"2013-06-01T00:00:00.456Z"};
	VSNote *note = [VSNote objectWithJSONRepresentation:JSONNote];

	XCTAssertEqual(note.uniqueID, 123456987984354);
	XCTAssertEqualObjects(note.archivedModificationDate, QSDateWithString(@"2014-06-01T00:00:00.456Z"));
	XCTAssertEqualObjects(note.creationDate, QSDateWithString(@"2013-06-01T00:00:00.456Z"));
	XCTAssertEqualObjects(note.sortDate, QSDateWithString(@"2014-04-01T02:03:04.456Z"));
	XCTAssertNil(note.sortDateModificationDate);

	NSTimeInterval nowTimeInterval = [now timeIntervalSince1970];
	NSTimeInterval noteTimeInterval = [note.textModificationDate timeIntervalSince1970];
	XCTAssertEqualWithAccuracy(nowTimeInterval, noteTimeInterval, 0.001);
}

@end
