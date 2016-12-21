//
//  VSEditableTagView.h
//  Vesper
//
//  Created by Brent Simmons on 4/12/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VSTagProxy;


@protocol VSEditableTagView <NSObject>

@property (nonatomic, strong, readonly) VSTagProxy *tagProxy;

@end
