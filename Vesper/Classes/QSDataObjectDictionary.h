//
//  QSDataObjectDictionary.h
//  Vesper
//
//  Created by Brent Simmons on 3/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

@import Foundation;


@class QSObjectModel;


@interface QSDataObjectDictionary : NSObject

+ (NSArray *)objectDictionariesForObjects:(NSArray *)databaseObjects objectModel:(QSObjectModel *)objectModel;

@end
