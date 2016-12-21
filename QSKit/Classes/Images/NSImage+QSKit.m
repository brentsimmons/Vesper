//
//  NSImage+QSKit.m
//  Q Branch Standard Kit
//
//  Created by Brent Simmons on 10/30/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "NSImage+QSKit.h"


@implementation NSImage (QSKit)


+ (void)qs_imageWithData:(NSData *)data imageResultBlock:(QSImageResultBlock)imageResultBlock {

	NSParameterAssert(data != nil);

	NSImage *image = [[NSImage alloc] initWithData:data];

	QSCallBlockWithParameter(imageResultBlock, image);
}


+ (instancetype)imageWithContentsOfFile:(NSString *)f {

	return [[self alloc] initWithContentsOfFile:f];
}

@end
