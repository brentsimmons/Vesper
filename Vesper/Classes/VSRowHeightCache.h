//
//  VSRowHeightCache.h
//  Vesper
//
//  Created by Brent Simmons on 3/29/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//



@class VSTimelineNote;


@interface VSRowHeightCache : NSObject


+ (instancetype)sharedCache;

- (CGFloat)cachedHeightForTimelineNote:(VSTimelineNote *)timelineNote; /*Returns 0.0f if not cached.*/

- (void)cacheHeight:(CGFloat)height forTimelineNote:(VSTimelineNote *)timelineNote;

- (void)empty;

@end

