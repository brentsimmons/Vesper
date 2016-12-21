//
//  QSFetchRequest.h
//  Vesper
//
//  Created by Brent Simmons on 3/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;
#import "QSDatabaseQueue.h"


/*Wrapper for -[QSTable objects:fetchResultsBlock:] --
 which takes two blocks, which makes it a little unwieldy.*/


@class QSTable;


@interface QSFetchRequest : NSObject


- (instancetype)initWithTable:(QSTable *)table resultSetBlock:(QSDatabaseResultSetBlock)resultSetBlock;

- (void)performFetch:(QSFetchResultsBlock)fetchResultsBlock;


@end
