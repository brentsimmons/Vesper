//
//  VSMergeNotesTests.m
//  Vesper
//
//  Created by Brent Simmons on 6/14/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VSNote.h"
#import "QSDateParser.h"
#import "VSSyncUtilities.h"


@interface VSMergeNotesTests : XCTestCase

@end

@implementation VSMergeNotesTests


- (void)testMergeNewerText {

	VSNote *note = [VSNote new];
	note.textModificationDate = QSDateWithString(@"2014-05-01T00:00:00.123Z");
	note.text = @"This is original text.";
	NSDictionary *JSONNote = @{@"text" : @"This is some new text.", @"textModificationDate" : @"2014-06-01T00:00:00.456Z"};
	BOOL didChange = VSSyncProperty(note, JSONNote, @"text");
	XCTAssertTrue(didChange);
	XCTAssertEqualObjects(@"This is some new text.", note.text);
	XCTAssertEqualObjects(note.textModificationDate, QSDateWithString(JSONNote[@"textModificationDate"]));

}


- (void)testMergeOlderText {

	NSDate *now = [NSDate date];
	VSNote *note = [VSNote new];
	note.textModificationDate = now;
	note.text = @"This is newest text.";
	NSDictionary *JSONNote = @{@"text" : @"This is some older text.", @"textModificationDate" : @"2014-06-01T00:00:00.456Z"};
	BOOL didChange = VSSyncProperty(note, JSONNote, @"text");
	XCTAssertFalse(didChange);
	XCTAssertEqualObjects(@"This is newest text.", note.text);
	XCTAssertEqualObjects(note.textModificationDate, now);
}


- (void)testMergeNewerArchivedFlag {

	VSNote *note = [VSNote new];
	note.archivedModificationDate = QSDateWithString(@"2014-05-11T03:40:44.123Z");
	note.archived = YES;
	NSDictionary *JSONNote = @{@"archived" : @(NO), @"archivedModificationDate" : @"2014-06-12T12:23:54.456Z"};
	BOOL didChange = VSSyncProperty(note, JSONNote, @"archived");
	XCTAssertTrue(didChange);
	XCTAssertFalse(note.archived);
	XCTAssertEqualObjects(note.archivedModificationDate, QSDateWithString(@"2014-06-12T12:23:54.456Z"));
}


- (void)testOlderArchivedFlag {

	NSDate *now = [NSDate date];
	VSNote *note = [VSNote new];
	note.archivedModificationDate = now;
	note.archived = YES;
	NSDictionary *JSONNote = @{@"archived" : @(NO), @"archivedModificationDate" : @"2014-06-12T12:23:54.456Z"};
	BOOL didChange = VSSyncProperty(note, JSONNote, @"archived");
	XCTAssertFalse(didChange);
	XCTAssertTrue(note.archived);
	XCTAssertEqualObjects(note.archivedModificationDate, now);
}


@end
