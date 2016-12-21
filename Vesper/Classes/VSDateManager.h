//
//  VSDateManager.h
//  Vesper
//
//  Created by Brent Simmons on 5/4/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//




@interface VSDateManager : NSObject


+ (instancetype)sharedManager;


/*Adjusted for clock skew based on date returned by server.*/

- (NSDate *)currentDate;


@end

