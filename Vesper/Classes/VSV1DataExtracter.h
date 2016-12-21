//
//  VSV1DataExtracter.h
//  Vesper
//
//  Created by Brent Simmons on 9/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


/*Gets data from V1 database.
 
 Returns array of notes. It's up to the caller to deal
 with saving notes, tags, and attachments.
 
 Should be called from with a QSDatabaseQueue block.
 (Not main thread.)*/


@class FMDatabase;

NSArray *VSV1Data(FMDatabase *database);

