//
//  VSSQLDataController.h
//  Vesper
//
//  Created by Brent Simmons on 2/20/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@import Foundation;

@interface VSSQLDataController : NSObject


- (void)deletedNoteIDs:(QSFetchResultsBlock)fetchResultsBlock; /*Fetch results is array of clientIDs.*/

- (void)addDeletedNoteClientIDs:(NSArray *)clientIDs;

- (void)removeDeletedNoteClientIDs:(NSArray *)clientIDs;


@end
