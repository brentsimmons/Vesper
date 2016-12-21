//
//  QSBlocks.m
//  Vesper
//
//  Created by Brent Simmons on 3/10/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSBlocks.h"


void QSCallCompletionBlock(QSVoidCompletionBlock completion) {

	if (!completion) {
		return;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			completion();
		}
	});
}


void QSCallBlockWithParameter(QSObjectResultBlock block, id obj) {

	if (!block) {
		return;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			block(obj);
		}
	});
}


void QSCallFetchResultsBlock(QSFetchResultsBlock fetchResultsBlock, NSArray *fetchedObjects) {

	QSCallBlockWithParameter(fetchResultsBlock, fetchedObjects);
}

