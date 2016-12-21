//
//  VSAPICall.m
//  Vesper
//
//  Created by Brent Simmons on 5/8/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//

#import "VSAPICall.h"
#import "VSAPIResult.h"


@interface VSAPICall ()

@property (nonatomic) NSURLRequest *URLRequest;
@property (nonatomic) NSString *taskDescription;
@property (nonatomic) NSURLSession *URLSession;
@property (nonatomic, copy) VSAPIResultBlock resultBlock;
@property (nonatomic) NSString *authenticationToken;
@property (nonatomic) id<VSAPICallDelegate> delegate;
@property (nonatomic) BOOL isCancelled;
@property (nonatomic) BOOL didEncounter401Response;
@property (nonatomic) BOOL didCallCompletionBlock;

@end


@implementation VSAPICall


@synthesize completionBlock = _completionBlock;

- (instancetype)initWithRequest:(NSURLRequest *)URLRequest taskDescription:(NSString *)taskDescription URLSession:(NSURLSession *)URLSession delegate:(id<VSAPICallDelegate>)delegate resultBlock:(VSAPIResultBlock)resultBlock {

	self = [self init];
	if (!self) {
		return nil;
	}

	_URLRequest = URLRequest;
	_taskDescription = taskDescription;
	_URLSession = URLSession;
	_resultBlock = resultBlock;
	_delegate = delegate;
	
	return self;
}


#pragma mark - NSOperation

- (void)main {

	if (self.isCancelled) {
		return;
	}

	[self preparedRequest:^(id request) {

		if (self.isCancelled) {
			return;
		}

		NSURLSessionDataTask *task = [self.URLSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

			if (self.isCancelled) {
				return;
			}

			VSAPIResult *apiResult = [VSAPIResult resultWithRequest:request response:response data:data error:error];

			if (apiResult.statusCode == 401 && !self.didEncounter401Response && self.setsAuthenticationToken) {

				self.didEncounter401Response = YES;
				[self handleExpiredAuthenticationToken];
				return;
			}

			[self finish:apiResult];
		}];

		task.taskDescription = self.taskDescription;
		[task resume];
	}];
}


- (void)cancel {

	self.isCancelled = YES;
	[self callCompletionBlock];
}


#pragma mark - Private

- (void)preparedRequest:(QSObjectResultBlock)resultBlock {

	if (!self.setsAuthenticationToken) {
		QSCallBlockWithParameter(resultBlock, self.URLRequest);
		return;
	}

	NSMutableURLRequest *request = [self.URLRequest mutableCopy];

	[self fetchAuthenticationToken:^{

		if (!self.authenticationToken) {
			[self finish:nil];
		}

		[request addValue:self.authenticationToken forHTTPHeaderField:@"x-zumo-auth"];

		QSCallBlockWithParameter(resultBlock, [request copy]);
	}];
}


- (void)fetchAuthenticationToken:(QSVoidCompletionBlock)completion {

	[self.delegate authenticationToken:^(id authenticationToken) {

		self.authenticationToken = authenticationToken;
		QSCallCompletionBlock(completion);
	}];
}


- (void)handleExpiredAuthenticationToken {

	[self.delegate authenticationTokenIsInvalid:self.authenticationToken];
	[self fetchAuthenticationToken:^{

		if (!self.authenticationToken) {
			[self finish:nil];
		}
		else {
			[self main];
		}
	}];
}


- (void)finish:(VSAPIResult *)apiResult {

	if (!self.isCancelled) {
		QSCallBlockWithParameter(self.resultBlock, apiResult);
	}

	[self callCompletionBlock];
}


- (void)callCompletionBlock {

	if (self.didCallCompletionBlock) {
		return;
	}
	self.didCallCompletionBlock = YES;

	QSCallBlockWithParameter(self.completionBlock, self);
}


@end
