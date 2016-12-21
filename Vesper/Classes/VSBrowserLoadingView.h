//
//  VSBrowserLoadingView.h
//  Vesper
//
//  Created by Brent Simmons on 3/3/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface VSBrowserLoadingView : UIView

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign, getter=isLoading) BOOL loading;
@end
