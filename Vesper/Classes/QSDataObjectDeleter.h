//
//  QSDataObjectDeleter.h
//  Vesper
//
//  Created by Brent Simmons on 3/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;


@class QSObjectModel;
@class QSDatabaseQueue;


@interface QSDataObjectDeleter : NSObject


+ (void)deleteObjectSpecifiers:(NSArray *)objectSpecifiers objectModel:(QSObjectModel *)objectModel queue:(QSDatabaseQueue *)queue;


@end
