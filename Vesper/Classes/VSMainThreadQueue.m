//
//  VSMainThreadQueue.m
//  Vesper
//
//  Created by Brent Simmons on 5/9/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSMainThreadQueue.h"


@interface VSMainThreadQueue ()

@property (nonatomic) NSMutableArray *pendingOperations;
@property (nonatomic) NSMutableArray *runningOperations;
@property (nonatomic, readonly) NSUInteger numberOfRunningOperations;
@property (nonatomic, readonly) NSUInteger numberOfPendingOperations;

@end


@implementation VSMainThreadQueue


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (!self) {
		return nil;
	}

	_pendingOperations = [NSMutableArray new];
	_runningOperations = [NSMutableArray new];
	_maxOperationsCount = 2;
	
	return self;
}


#pragma mark - API

- (void)addOperation:(id<VSOperation>)operation {

	[self.pendingOperations addObject:operation];
	[self updateNumberOfOperations];

	[self continueExecuting];
}


#pragma mark - Queue

- (NSUInteger)numberOfRunningOperations {

	return [self.runningOperations count];
}


- (NSUInteger)numberOfPendingOperations {

	return [self.pendingOperations count];
}


- (void)updateNumberOfOperations {
	self.numberOfOperations = self.numberOfRunningOperations + self.numberOfPendingOperations;
}


- (void)runNextOperation {

	id<VSOperation> operation = [self.pendingOperations firstObject];
	[self.pendingOperations removeObject:operation];

	operation.completionBlock = ^(id<VSOperation> finishedOperation) {

		[self.runningOperations removeObject:finishedOperation];
		[self updateNumberOfOperations];
		[self performSelectorOnMainThread:@selector(continueExecuting) withObject:nil waitUntilDone:NO];
	};
	 
	[self.runningOperations addObject:operation];
	[(id)operation performSelectorOnMainThread:@selector(main) withObject:nil waitUntilDone:NO];
}


- (void)continueExecuting {

	while (self.numberOfRunningOperations < self.maxOperationsCount && self.numberOfPendingOperations > 0) {

		[self runNextOperation];
	}
}


- (void)cancelOperations {

	[self.runningOperations makeObjectsPerformSelector:@selector(cancel)];
	[self.pendingOperations makeObjectsPerformSelector:@selector(cancel)];
	[self.runningOperations removeAllObjects];
	[self.pendingOperations removeAllObjects];

	self.numberOfOperations = 0;
}


@end
