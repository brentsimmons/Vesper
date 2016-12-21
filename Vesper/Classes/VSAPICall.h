//
//  VSAPICall.h
//  Vesper
//
//  Created by Brent Simmons on 5/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


#import "VSMainThreadQueue.h"


@protocol VSAPICallDelegate <NSObject>

@required

@property (nonatomic, readonly) NSString *authenticationToken;

- (void)authenticationToken:(QSObjectResultBlock)resultBlock;
- (void)authenticationTokenIsInvalid:(NSString *)authenticationToken;

@end


@interface VSAPICall : NSObject <VSOperation>


- (instancetype)initWithRequest:(NSURLRequest *)URLRequest taskDescription:(NSString *)taskDescription URLSession:(NSURLSession *)URLSession delegate:(id<VSAPICallDelegate>)delegate resultBlock:(VSAPIResultBlock)resultBlock;

@property (nonatomic) BOOL setsAuthenticationToken;


@end
