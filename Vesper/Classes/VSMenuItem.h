//
//  VSMenuItem.h
//  Vesper
//
//  Created by Brent Simmons on 5/6/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface VSMenuItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) VSPosition position;

@end


