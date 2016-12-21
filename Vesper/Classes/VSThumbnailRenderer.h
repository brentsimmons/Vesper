//
//  VSThumbnailRenderer.h
//  Vesper
//
//  Created by Brent Simmons on 10/23/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

@import Foundation;
#if TARGET_OS_IPHONE
@import UIKit;
#else
@import AppKit;
#endif


@interface VSThumbnailRenderer : NSObject


/*Thread-safe. Rendering happens on a background queue. imageResultBlock could be called on any thread.*/

- (void)renderThumbnailWithImage:(QS_IMAGE *)fullSizeImage imageResultBlock:(QSImageResultBlock)imageResultBlock;

- (void)renderThumbnailWithData:(NSData *)fullSizeImageData imageResultBlock:(QSImageResultBlock)imageResultBlock;


/*Layout support. Thumbnails may have padding for a shadow. (See VSThumbnail.h for the methods you should call instead of these.)*/

CGRect VSThumbnailActualRectForApparentRect(CGRect apparentRect);
CGRect VSThumbnailApparentRectForActualRect(CGRect actualRect);

@end

