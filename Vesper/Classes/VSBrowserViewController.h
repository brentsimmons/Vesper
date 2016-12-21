//
//  VSBrowserViewController.h
//  Vesper
//
//  Created by Brent Simmons on 2/4/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "VSBaseViewController.h"
#import "VSBrowserPullToRefreshView.h"


@interface VSBrowserViewController : VSBaseViewController <UIWebViewDelegate, UIScrollViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, VSPullToRefreshDelegate>


- (id)initWithURL:(NSURL *)initialURL;

- (void)beginLoading;

+ (BOOL)canOpenURL:(NSURL *)url;


@end
