//
//  QSObjectSpecifier.h
//  Vesper
//
//  Created by Brent Simmons on 3/2/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;


@interface QSObjectSpecifier : NSObject


+ (NSArray *)objectSpecifiersWithObjects:(NSArray *)objects className:(NSString *)className;

+ (QSObjectSpecifier *)objectSpecifierWithClassName:(NSString *)className uniqueID:(id)uniqueID;

@property (nonatomic, readonly) NSString *className;
@property (nonatomic, readonly) id uniqueID;


@end
