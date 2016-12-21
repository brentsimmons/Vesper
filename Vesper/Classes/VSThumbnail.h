//
//  VSThumbnail.h
//  Vesper
//
//  Created by Brent Simmons on 3/10/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


@class VSAttachmentData;



@interface VSThumbnail : NSObject


@property (nonatomic, strong) NSString *uniqueID;
@property (nonatomic, assign) NSUInteger scale;
@property (nonatomic, strong) QS_IMAGE *image;


/*Will send VSThumbnailRenderedNotification with VSThumbnailKey in userInfo for any thumbnails fetched/rendered async.
 thumbnailResultBlock may be nil. It will be called on any thread.*/

extern NSString *VSThumbnailRenderedNotification;
extern NSString *VSThumbnailKey;


typedef void (^QSThumbnailResultBlock)(VSThumbnail *thumbnail);

+ (void)renderAndSaveThumbnailForImage:(QS_IMAGE *)image attachmentID:(NSString *)attachmentID thumbnailResultBlock:(QSThumbnailResultBlock)thumbnailResultBlock;
+ (void)renderAndSaveThumbnailForAttachmentID:(NSString *)attachmentID thumbnailResultBlock:(QSThumbnailResultBlock)thumbnailResultBlock;


/*Layout support. A thumbnail will have padding around the edges for shadows.*/

+ (CGRect)thumbnailRectForApparentRect:(CGRect)apparentRect;
+ (CGRect)apparentRectForActualRect:(CGRect)actualRect;

@end
