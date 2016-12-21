//
//  VSDataMigraterTests.m
//  Vesper
//
//  Created by Brent Simmons on 3/27/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VSV1DataExtracter.h"
#import "FMDatabase.h"


@interface VSDataMigraterTests : XCTestCase

@end


@implementation VSDataMigraterTests


static const NSUInteger kNumberOfNotes = 55;

- (void)testExtractV1Data {

	NSString *databaseFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"Vesper-Notes" ofType:@"sqlite3"];

	FMDatabase *database = [[FMDatabase alloc] initWithPath:databaseFile];
	XCTAssertNotNil(database);

	[database open];
	NSArray *notes = VSV1Data(database);
	[database close];

	NSUInteger numberOfNotes = [notes count];
	XCTAssertTrue(numberOfNotes == kNumberOfNotes);

	/*Things in common to all notes.*/

	for (VSNote *oneNote in notes) {

		XCTAssertNotNil(oneNote.creationDate);
		XCTAssertNotNil(oneNote.sortDate);

		XCTAssertTrue(oneNote.uniqueID > 0);

		XCTAssertTrue([oneNote.attachments count] < 2);

		if ([oneNote.attachments count] > 0) {

			XCTAssertNotNil(oneNote.thumbnailID);
			XCTAssertNotNil(oneNote.firstImageAttachment);
		}
	}

	/*Spot checks*/

	VSNote *testNote = [notes qs_firstObjectWhereValueForKey:@"text" equalsValue:@"Automated testing"];
	XCTAssertNotNil(testNote);
	XCTAssertTrue([testNote.tags count] == 2);
	NSArray *tagNames = testNote.tagNames;
	NSArray *expectedTagNames = @[@"Todo", @"Vesper"];
	XCTAssertEqualObjects(tagNames, expectedTagNames);

	testNote = [notes qs_firstObjectWhereValueForKey:@"text" equalsValue:@"Papa and quilts"];
	XCTAssertNotNil(testNote);
	VSAttachment *attachment = testNote.firstImageAttachment;
	XCTAssertNotNil(attachment);
	XCTAssertEqual(attachment.height, 768);
	XCTAssertEqual(attachment.width, 576);
	XCTAssertEqualObjects(attachment.mimeType, @"image/jpeg");
	XCTAssertEqualObjects(attachment.uniqueID, @"58D16D42-6E73-4B90-BF58-65640DE5BEC8");
	XCTAssertFalse(testNote.archived);

	testNote = [notes qs_firstObjectWhereValueForKey:@"text" equalsValue:@"19\""];
	XCTAssertNotNil(testNote);
	attachment = testNote.firstImageAttachment;
	XCTAssertEqualObjects(attachment.uniqueID, @"E73B1930-ED0A-4765-B414-032546BF7859");
	XCTAssertTrue(testNote.archived);
	XCTAssertEqual(testNote.firstImageAttachment.height, 1136);

	/*Links*/

	NSMutableSet *allFoundLinks = [NSMutableSet new];
	for (VSNote *oneNote in notes) {
		[allFoundLinks addObjectsFromArray:oneNote.links];
	}
	XCTAssertTrue([allFoundLinks count] == 3);
	NSMutableSet *expectedLinks = [NSMutableSet new];
	[expectedLinks addObject:@"vesperapp.co"];
	[expectedLinks addObject:@"Apple.com"];
	[expectedLinks addObject:@"Inessential.com"];
	XCTAssertEqualObjects(allFoundLinks, expectedLinks);

	/*Tags*/

	NSMutableSet *allFoundTagNames = [NSMutableSet new];
	for (VSNote *oneNote in notes) {
		[allFoundTagNames addObjectsFromArray:oneNote.tagNames];
	}
	XCTAssertEqual([allFoundTagNames count], (NSUInteger)9);
	NSSet *expectedTagNamesSet = [NSSet setWithArray:@[@"Tutorial", @"WWDC", @"Vesper", @"House", @"Todo", @"Office", @"The Record", @"Books Read", @"Books"]];
	XCTAssertEqualObjects(allFoundTagNames, expectedTagNamesSet);

	/*Attachments*/

	NSMutableSet *allAttachmentIDs = [NSMutableSet new];
	for (VSNote *oneNote in notes) {
		[allAttachmentIDs addObjectsFromArray:[oneNote.attachments valueForKeyPath:@"uniqueID"]];
	}
	XCTAssertEqual([allAttachmentIDs count], (NSUInteger)20);
	NSSet *expectedAttachmentIDs = [NSSet setWithArray:@[@"C084F139-689C-4DFE-AB5F-FB4C9E066480", @"B25B2EEE-A2A8-49A2-957B-8CE9BF00AF79", @"16E3C395-40CA-4168-9A5C-818F807CD699", @"8A53EFAD-E2BA-479E-AA02-D2F7A70871E6", @"CF1F4FA7-AECB-4322-9840-BC985B1B183B", @"4434953F-549E-4E8C-9DDF-4A2034CCEB57", @"05A9A30A-3D57-4DCC-9A98-E0721C26D850", @"F1C23BCC-43E2-4D4A-8CAA-161A76370AEB", @"D03267A6-F74F-4B8E-BA76-38381CB51895", @"538DCB50-3F6B-45B6-961B-3D876B04138B", @"AA309E24-D156-4E0F-9B9F-6344822ABD86", @"74408AF6-356A-4058-9EA7-ECA561AA291B", @"E73B1930-ED0A-4765-B414-032546BF7859", @"112C0A2B-78CB-4591-A389-81D19F6C7CA2", @"4F0D9654-60F0-4471-A212-501E7AFD3F39", @"B2D94C35-1D06-4D93-A8BF-8E66731E0EE3", @"BDC86B97-0C96-4261-8D66-773EA02908FE", @"954A36C9-BB74-46DA-8A20-45CEEA5A2B25", @"8C7F3F16-29D3-4AAF-9A1F-1D474956B128", @"58D16D42-6E73-4B90-BF58-65640DE5BEC8"]];
	XCTAssertEqualObjects(allAttachmentIDs, expectedAttachmentIDs);

}


@end
