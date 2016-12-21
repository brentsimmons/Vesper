//
//  VSTimelineContext.h
//  Vesper
//
//  Created by Brent Simmons on 3/15/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


@class VSTimelineNotesController;
@class VSTag;
@class VSRowHeightCache;


@interface VSTimelineContext : NSObject


@property (nonatomic) NSString *title;
@property (nonatomic) VSTag *tag;
@property (nonatomic, assign) BOOL canReorderNotes;
@property (nonatomic, assign) BOOL canMakeNewNotes;
@property (nonatomic, assign) BOOL searchesArchivedNotesOnly;
@property (nonatomic) VSTimelineNotesController *timelineNotesController;
@property (nonatomic) NSString *noNotesImageName;
@property (nonatomic, readonly) QS_IMAGE *noNotesImage;
@property (nonatomic) BOOL showInitialNoNotesView;


@end
