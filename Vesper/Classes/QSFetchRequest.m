//
//  QSFetchRequest.m
//  Vesper
//
//  Created by Brent Simmons on 3/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "QSFetchRequest.h"
#import "QSTable.h"


@interface QSFetchRequest ()

@property (nonatomic, readwrite) QSTable *table;
@property (nonatomic, copy, readonly) QSDatabaseResultSetBlock resultSetBlock;

@end


@implementation QSFetchRequest


#pragma mark - Init

- (instancetype)initWithTable:(QSTable *)table resultSetBlock:(QSDatabaseResultSetBlock)resultSetBlock {

	self = [super init];
	if (!self) {
		return nil;
	}

	_table = table;
	_resultSetBlock = resultSetBlock;

	return self;
}


#pragma mark - API

- (void)performFetch:(QSFetchResultsBlock)fetchResultsBlock {

	[self.table objects:self.resultSetBlock fetchResultsBlock:fetchResultsBlock];
}

@end
