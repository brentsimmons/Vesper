//
//  VSMainThreadQueue.h
//  Vesper
//
//  Created by Brent Simmons on 5/9/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


#import "QSBlocks.h"


@protocol VSOperation <NSObject>

- (void)main;
- (void)cancel;

@property (nonatomic, copy) QSObjectResultBlock completionBlock;

@end


@interface VSMainThreadQueue : NSObject


@property (nonatomic) NSUInteger numberOfOperations;
@property (nonatomic) NSUInteger maxOperationsCount;

- (void)addOperation:(id<VSOperation>)operation;

- (void)cancelOperations;

@end
