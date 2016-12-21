//
//  VSBinaryCacheTests.m
//  Vesper
//
//  Created by Brent Simmons on 7/22/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VSBinaryCache.h"


@interface VSBinaryCacheTests : XCTestCase

@property (nonatomic) VSBinaryCache *binaryCache;

@end


@implementation VSBinaryCacheTests

- (void)setUp {

	if (!self.binaryCache) {

		NSString *folder = NSTemporaryDirectory();
		folder = [folder stringByAppendingPathComponent:@"VSBinaryCacheTests"];

		[[NSFileManager defaultManager] removeItemAtPath:folder error:nil];
		[[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];

		self.binaryCache = [[VSBinaryCache alloc] initWithFolder:folder];
	}
}


- (void)testBinaryCache {

	NSString *f = [[NSBundle bundleForClass:[self class]] pathForResource:@"tutorial" ofType:@"jpg"];

	NSString *testKey = @"testKey";

	NSData *d = [NSData dataWithContentsOfFile:f];
	XCTAssertTrue([self.binaryCache setBinaryData:d key:testKey error:nil]);

	NSData *fetchedData = [self.binaryCache binaryDataForKey:testKey error:nil];
	XCTAssertEqualObjects(d, fetchedData);

	UInt64 length = [self.binaryCache lengthOfBinaryDataForKey:testKey error:nil];
	XCTAssertEqual(length, 433883ULL);

	XCTAssertFalse([self.binaryCache binaryForKeyExists:@"doesntExist"]);

	XCTAssertTrue([self.binaryCache binaryForKeyExists:testKey]);

	NSArray *allKeys = [self.binaryCache allKeys:nil];
	XCTAssertEqualObjects(allKeys, @[testKey]);

	NSArray *allObjects = [self.binaryCache allObjects:nil];
	NSDictionary *expectedObject = @{VSBinaryKey: testKey, VSBinaryLength: @(433883)};
	XCTAssertEqualObjects(allObjects, @[expectedObject]);

	XCTAssertTrue([self.binaryCache removeBinaryDataForKey:testKey error:nil]);

	allKeys = [self.binaryCache allKeys:nil];
	XCTAssertTrue(allKeys.count < 1);
}


@end
