//
//  VSTimelineNote.h
//  Vesper
//
//  Created by Brent Simmons on 3/1/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@class VSNote;


/*Mostly immutable. Properties that may change:
 sortDate
 archived
 */

@interface VSTimelineNote : NSObject <NSCopying>


+ (VSTimelineNote *)timelineNoteWithNote:(VSNote *)note;


@property (nonatomic, assign, readonly) int64_t uniqueID;
@property (nonatomic, readonly) NSString *truncatedText;
@property (nonatomic, readonly) NSArray *links;
@property (nonatomic, readonly) NSString *thumbnailID;

@property (nonatomic) NSDate *sortDate;
@property (nonatomic, assign) BOOL archived;

/*Calculated*/

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *remainingText;
@property (nonatomic, assign, readonly) BOOL hasThumbnail;
@property (nonatomic, readonly) QS_IMAGE *thumbnail;

- (void)takeValuesFromNote:(VSNote *)note;


@end
