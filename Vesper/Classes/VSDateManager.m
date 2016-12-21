//
//  VSDateManager.m
//  Vesper
//
//  Created by Brent Simmons on 5/4/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSDateManager.h"
#import "QSDateParser.h"
#import "VSAPIResult.h"


@interface VSDateManager ()

@property (nonatomic, assign) NSTimeInterval skew;

@end


static NSString *VSDateSkewKey = @"dateSkew";


@implementation VSDateManager


#pragma mark - Class Methods

+ (instancetype)sharedManager {

	static id gMyInstance = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMyInstance = [self new];
	});

	return gMyInstance;
}


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	_skew = [[NSUserDefaults standardUserDefaults] doubleForKey:VSDateSkewKey];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDateReported:) name:VSServerDateNotification object:nil];

	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Accessors

- (void)setSkew:(NSTimeInterval)skew {

	if (skew == _skew) {
		return;
	}

	_skew = skew;

	[[NSUserDefaults standardUserDefaults] setDouble:skew forKey:VSDateSkewKey];
}


#pragma mark - Notifications

- (void)serverDateReported:(NSNotification *)note {

	NSDate *serverDate = [note userInfo][VSServerDateKey];
	if (!serverDate) {
		return;
	}

	NSTimeInterval skew = [serverDate timeIntervalSinceDate:[NSDate date]];
	if (skew > 120.0 || skew < -120.0) { /*Two minutes is plenty to account for the https call.*/
		self.skew = skew;
	}
	else {
		self.skew = 0.0;
	}

//	NSLog(@"skew: %f", self.skew);
//	NSLog(@"current unskewed date: %@", [self currentDate]);
}


#pragma mark - API

- (NSDate *)currentDate {

	if (self.skew == 0.0) {
		return [NSDate date];
	}

	NSDate *now = [NSDate date];
	NSDate *unskewedDate = [now dateByAddingTimeInterval:self.skew];

	static NSDate *oldDate = nil;
	static NSDate *futureDate = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		oldDate = QSDateWithString(@"2014-05-01T00:00:00+00:00");
		futureDate = QSDateWithString(@"2020-05-01T00:00:00+00:00");
	});

	if ([unskewedDate earlierDate:oldDate] == unskewedDate) {
		return now;
	}
	if ([unskewedDate earlierDate:futureDate] == futureDate) {
		return now;
	}

	return unskewedDate;
}


@end
