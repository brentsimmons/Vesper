//
//  QSAPIObject.h
//  Vesper
//
//  Created by Brent Simmons on 3/6/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;


/*JSON representations are NSDictionaries.*/


@protocol QSAPIObject <NSObject>

@required


/*Methods may return nil, but it's strongly discouraged.
 Methods may be called on any thread. The responsibility for thread
 safety is handled outside of the object implementing this protocol.*/

- (NSDictionary *)JSONRepresentation;

+ (instancetype)objectWithJSONRepresentation:(NSDictionary *)JSONRepresentation;

@end


@interface QSAPIObject : NSObject


+ (NSArray *)JSONArrayWithObjects:(NSArray *)objects;

+ (NSArray *)objectsWithJSONArray:(NSArray *)JSONArray class:(Class<QSAPIObject>)class;

+ (void)objectsWithJSONArray:(NSArray *)JSONArray class:(Class<QSAPIObject>)class resultsBlock:(QSFetchResultsBlock)resultsBlock;


@end


