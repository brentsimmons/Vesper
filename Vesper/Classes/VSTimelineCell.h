//
//  VSTimelineCell.h
//  Vesper
//
//  Created by Brent Simmons on 5/9/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@class VSTimelineCell;

extern NSString *VSTimelineCellShouldCancelPanNotification;

@protocol VSTimelineCellDelegate <NSObject>

- (BOOL)timelineCellIsPanning:(VSTimelineCell *)timelineCell;
- (void)timelineCellDidCancelOrEndPanning:(VSTimelineCell *)timelineCell;
- (BOOL)timelineCellShouldBeginPanning:(VSTimelineCell *)timelineCell;
- (void)timelineCellDidBeginPanning:(VSTimelineCell *)timelineCell;
- (void)timelineCellWillBeginPanning:(VSTimelineCell *)timelineCell;

- (void)timelineCellDidDelete:(VSTimelineCell *)timelineCell;

@end


typedef NS_ENUM(NSUInteger, VSArchiveControlStyle) {
	VSArchiveControlStyleArchive,
	VSArchiveControlStyleRestoreDelete
};


@interface VSTimelineCell : UITableViewCell

@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) NSString *archiveActionText;
@property (nonatomic, assign) BOOL archiveIndicatorUseItalicFont;
@property (nonatomic, assign) BOOL renderingForAnimation;
@property (nonatomic, assign) BOOL hideThumbnail; /*for animation*/
@property (nonatomic, assign) BOOL shouldHaveTopDivider;
@property (nonatomic, assign, readonly) CGRect thumbnailRect; /*for animation; full rect, not apparent rect*/
@property (nonatomic, weak) id<VSTimelineCellDelegate> delegate;
@property (nonatomic, assign) VSArchiveControlStyle archiveControlStyle;
@property (nonatomic, assign) BOOL isSampleText;

+ (void)adjustLayoutBitsWithSize:(CGSize)size;
+ (void)emptyCaches;
+ (CGFloat)height;
+ (CGFloat)heightWithTitle:(NSString *)title text:(NSString *)text links:(NSArray *)links useItalicFonts:(BOOL)useItalicFonts hasThumbnail:(BOOL)hasThumbnail truncateIfNeeded:(BOOL)truncateIfNeeded;

- (void)configureWithTitle:(NSString *)title text:(NSString *)text links:(NSArray *)links useItalicFonts:(BOOL)useItalicFonts hasThumbnail:(BOOL)hasThumbnail truncateIfNeeded:(BOOL)truncateIfNeeded;

- (UIImage *)imageForAnimationWithThumbnailHidden:(BOOL)thumbnailHidden;
- (UIImage *)imageForDetailPanBackAnimation;

@end
