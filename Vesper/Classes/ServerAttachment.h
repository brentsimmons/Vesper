//
//  ServerAttachment.h
//  Vesper
//
//  Created by Brent Simmons on 11/26/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "ServerObject.h"

@interface ServerAttachment : ServerObject

@property (nonatomic) NSString *uniqueID;
@property (nonatomic) int64_t height;
@property (nonatomic) int64_t width;
@property (nonatomic) NSString *mimeType;

@end
