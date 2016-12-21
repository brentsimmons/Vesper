//
//  VSTag.h
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


#import "QSAPIObject.h"

@interface VSTag : NSObject <NSCopying, QSAPIObject>


/*Mutable: name may change in case. nameModificationDate may change.*/


- (instancetype)initWithName:(NSString *)name;

@property (nonatomic, readonly) NSString *uniqueID; /*Normalized name; lower-cased.*/
@property (nonatomic) NSString *name;
@property (nonatomic) NSDate *nameModificationDate;

+ (NSString *)uniqueIDForTagName:(NSString *)name;
+ (NSString *)normalizedTagName:(NSString *)name;


@end
