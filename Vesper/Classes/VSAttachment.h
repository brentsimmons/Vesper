//
//  VSAttachment.h
//  Vesper
//
//  Created by Brent Simmons on 9/27/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


#import "QSAPIObject.h"


/*Immutable*/

@interface VSAttachment : NSObject <QSAPIObject>


@property (nonatomic, readonly) NSString *uniqueID;
@property (nonatomic, readonly) NSString *mimeType;
@property (nonatomic, assign, readonly) int64_t height;
@property (nonatomic, assign, readonly) int64_t width;

/*Convenience*/

@property (nonatomic, assign, readonly) BOOL isImage;
@property (nonatomic, assign, readonly) CGSize size;
@property (nonatomic, readonly) NSString *path; /*May not exist on disk.*/


/*uniqueID and mimeType must not be nil.*/

+ (instancetype)attachmentWithUniqueID:(NSString *)uniqueID mimeType:(NSString *)mimeType height:(int64_t)height width:(int64_t)width;


@end
