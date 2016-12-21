//
//  QSDataRowFetcher.h
//  Vesper
//
//  Created by Brent Simmons on 3/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

@import Foundation;


@interface QSRowFetcher : NSObject


- (instancetype)initWithProperties:(NSDictionary *)properties cache:(QSWeakCache *)cache;

- (NSArray *)objectsWithResultSet:(FMResultSet *)resultSet objectModel:(QSObjectModel *)objectModel;

- (NSArray *)dictionariesWithResultSet:(FMResultSet *)resultSet objectModel:(QSObjectModel *)objectModel;

@end
