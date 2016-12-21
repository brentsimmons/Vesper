//
//  VSDetailTextStorage.h
//  Vesper
//
//  Created by Brent Simmons on 7/19/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VSDetailTextStorage : NSTextStorage

@property (nonatomic, strong) NSDictionary *titleAttributes;
@property (nonatomic, strong) NSDictionary *bodyAttributes;
@property (nonatomic, assign) BOOL readOnly;

- (void)highlightLinks:(NSArray *)links;
- (void)unhighlightLinks;

- (instancetype)initAsReadOnly:(BOOL)readOnly;


@end
