//
//  VSArchiveIndicatorView.h
//  Vesper
//
//  Created by Brent Simmons on 4/8/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, VSArchiveIndicatorState) {
	VSArchiveIndicatorStateHinting,
	VSArchiveIndicatorStateIndicating
};


@interface VSArchiveIndicatorView : UIView

@property (nonatomic, assign) VSArchiveIndicatorState archiveIndicatorState;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) CGFloat arrowTranslationX;

@end
