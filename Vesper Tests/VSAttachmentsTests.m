//
//  VSAttachmentsTests.m
//  Vesper
//
//  Created by Brent Simmons on 6/14/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VSAttachment.h"

@interface VSAttachmentsTests : XCTestCase

@end

@implementation VSAttachmentsTests


- (void)testJSONRepresentation {

	NSString *uuidString = [[NSUUID UUID] UUIDString];
	VSAttachment *attachment = [VSAttachment attachmentWithUniqueID:uuidString mimeType:@"audio/m4a" height:124578 width:0];
	NSDictionary *d = [attachment JSONRepresentation];

	XCTAssertEqualObjects(uuidString, d[@"uniqueID"]);
	XCTAssertEqualObjects(@"audio/m4a", d[@"mimeType"]);
	XCTAssertEqual(124578, [d[@"height"] integerValue]);
	XCTAssertEqual(0, [d[@"width"] integerValue]);
}


- (void)testObjectWithJSONRepresentation {

	NSDictionary *d = @{@"uniqueID" : @"5F76EBC5-EE3A-4B33-9DE7-73E57FF04DF1", @"mimeType" : @"image/jpeg", @"height" : @(480), @"width" : @(0)};
	VSAttachment *attachment = [VSAttachment objectWithJSONRepresentation:d];

	XCTAssertEqualObjects(attachment.uniqueID, @"5F76EBC5-EE3A-4B33-9DE7-73E57FF04DF1");
	XCTAssertEqualObjects(attachment.mimeType, @"image/jpeg");
	XCTAssertEqual(attachment.height, 480);
	XCTAssertEqual(attachment.width, 0);
}


@end
