
//
//  VSAPICaller.m
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSAPICaller.h"
#import "VSAPIResult.h"
#import "NSMutableURLRequest+QSKit.h"
#import "VSMainThreadQueue.h"
#import "VSAttachmentStorage.h"


static NSString *VSAPIBaseURLString = @"https://vesper.azure-mobile.net/";
static NSString *VSAPIAppString = @"TTgplXupjJDlonGJiXdvGEjSERTTkE33";
//static NSString *VSAPIBaseURLString = @"https://vespertest1.azure-mobile.net/";
//static NSString *VSAPIAppString = @"PjViCaEpnSVIbxgOXDuqHclsaYpvtA59";


@interface NSMutableURLRequest (Vesper)

- (void)vs_addJSON:(id)obj;
- (void)vs_addSyncToken:(NSString *)syncToken;

@end


@interface VSAPICaller () <NSURLSessionDelegate>

@property (nonatomic) NSURLSession *URLSession;
@property (nonatomic) NSUInteger numberOfSyncCallsQueued;
@property (nonatomic) VSMainThreadQueue *queue;
@property (nonatomic) BOOL syncInProgress;

@end


static NSString *VSNumberOfOperationsKey = @"numberOfOperations";
static void *VSNumberOfOperationsContext = &VSNumberOfOperationsContext;


@implementation VSAPICaller


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (self == nil) {
		return nil;
	}

	NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
	sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	sessionConfiguration.timeoutIntervalForRequest = 60.0f;
	sessionConfiguration.HTTPShouldSetCookies = NO;
	sessionConfiguration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
	sessionConfiguration.HTTPMaximumConnectionsPerHost = 2;
	sessionConfiguration.HTTPCookieStorage = nil;
	sessionConfiguration.URLCache = nil;

	_URLSession = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:[NSOperationQueue mainQueue]];

	_queue = [VSMainThreadQueue new];
	_queue.maxOperationsCount = 2;

	[_queue addObserver:self forKeyPath:VSNumberOfOperationsKey options:0 context:VSNumberOfOperationsContext];
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {

	[_queue removeObserver:self forKeyPath:VSNumberOfOperationsKey context:VSNumberOfOperationsContext];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	if (context == VSNumberOfOperationsContext) {

#if TARGET_OS_IPHONE
		[UIApplication sharedApplication].networkActivityIndicatorVisible = self.queue.numberOfOperations > 0;
#endif
		[self updateSyncInProgress];
	}
}


#pragma mark - Sync in Progress

- (void)updateSyncInProgress {

	BOOL currentSyncInProgress = self.syncInProgress;
	BOOL updatedSyncInProgress = self.queue.numberOfOperations > 0;

	if (currentSyncInProgress == updatedSyncInProgress) {
		return;
	}

	self.syncInProgress = updatedSyncInProgress;

	if (!currentSyncInProgress && updatedSyncInProgress) {
		[[NSNotificationCenter defaultCenter] postNotificationName:VSSyncDidBeginNotification object:nil];
	}
	else if (currentSyncInProgress && !updatedSyncInProgress) {
		[[NSNotificationCenter defaultCenter] postNotificationName:VSSyncDidCompleteNotification object:nil];
	}
}


#pragma mark - Run Task

- (VSAPICall *)apiCallWithRequest:(NSURLRequest *)request taskDescription:(NSString *)taskDescription resultBlock:(VSAPIResultBlock)resultBlock {

	return [[VSAPICall alloc] initWithRequest:request taskDescription:taskDescription URLSession:self.URLSession delegate:self.delegate resultBlock:resultBlock];
}


- (void)addAPICall:(VSAPICall *)apiCall {

	[self.queue addOperation:apiCall];
}


#pragma mark - Account

- (void)createAccount:(NSString *)username password:(NSString *)password emailUpdates:(BOOL)emailUpdates resultBlock:(VSAPIResultBlock)resultBlock {

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/createAccount" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request qs_addBasicAuthorization:username password:password];
	[request vs_addJSON:@{VSAccountEmailUpdatesKey : @(emailUpdates)}];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Create Account" resultBlock:resultBlock];
	[self addAPICall:apiCall];
}


- (void)login:(NSString *)username password:(NSString *)password resultBlock:(VSAPIResultBlock)resultBlock {

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/login" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request qs_addBasicAuthorization:username password:password];
	[request vs_addJSON:@{}];

	/*Can't be done via operation queue and VSAPICall -- because a VSAPICall may need to do a login.*/

	NSURLSessionDataTask *task = [self.URLSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

		VSAPIResult *result = [VSAPIResult resultWithRequest:request response:response data:data error:error];

		QSCallBlockWithParameter(resultBlock, result);
	}];

	task.taskDescription = @"Login";
	[task resume];
}


- (void)forgotPassword:(NSString *)username resultBlock:(VSAPIResultBlock)resultBlock {

	NSParameterAssert(!QSStringIsEmpty(username));

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/forgotpassword" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request vs_addJSON:@{@"username": username}];

	/*Don't use VSAPICall because those are just for sync calls.*/

	NSURLSessionDataTask *task = [self.URLSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

		VSAPIResult *result = [VSAPIResult resultWithRequest:request response:response data:data error:error];

		QSCallBlockWithParameter(resultBlock, result);
	}];

	task.taskDescription = @"Forgot Password";
	[task resume];
}


- (void)changePassword:(NSString *)updatedPassword resultBlock:(VSAPIResultBlock)resultBlock {

	NSParameterAssert(!QSStringIsEmpty(updatedPassword));

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/changepasswordauthenticated" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request vs_addJSON:@{@"password": updatedPassword}];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Change Password" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


#pragma mark - Email Updates

- (void)downloadEmailUpdatesSetting:(NSString *)authenticationToken resultBlock:(VSAPIResultBlock)resultBlock {

	if (QSStringIsEmpty(authenticationToken)) {
		QSCallBlockWithParameter(resultBlock, nil);
		return;
	}

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/emailupdates" queryDictionary:nil];
	[request setHTTPMethod:@"GET"];
	[request addValue:authenticationToken forHTTPHeaderField:@"x-zumo-auth"];

	/*Not a VSAPICall -- because those are counted as syncing calls, and this isn't.*/

	NSURLSessionDataTask *task = [self.URLSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

		VSAPIResult *result = [VSAPIResult resultWithRequest:request response:response data:data error:error];

		QSCallBlockWithParameter(resultBlock, result);
	}];

	task.taskDescription = @"Download Email Updates";
	[task resume];

}


- (void)uploadEmailUpdatesSetting:(BOOL)emailUpdates resultBlock:(VSAPIResultBlock)resultBlock {

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/emailupdates" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request vs_addJSON:@{@"emailUpdates": @(emailUpdates)}];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Upload Email Updates" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


#pragma mark - Deleted Objects

- (void)uploadDeletedNotes:(NSArray *)deletedNotes syncToken:(NSString *)syncToken resultBlock:(VSAPIResultBlock)resultBlock {

	/*deletedNotes is an array of note IDs.*/

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/deletedNotes" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request vs_addSyncToken:syncToken];
	[request vs_addJSON:deletedNotes];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Upload Deleted Notes" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


#pragma mark - Attachment Data

static NSString *VSHTTPDateString(NSDate *d) {

	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
	[dateFormatter setLocale:enUSPOSIXLocale];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"];

	NSString *dateString = [dateFormatter stringFromDate:d];
	return [NSString stringWithFormat:@"%@ GMT", dateString];
}


- (void)downloadBlobFileUploadURL:(NSString *)md5 mimeType:(NSString *)mimeType contentLength:(uint64_t)contentLength resourceName:(NSString *)resourceName dateString:(NSString *)dateString resultBlock:(VSAPIResultBlock)resultBlock {

	NSParameterAssert(!QSStringIsEmpty(md5));
	NSParameterAssert(!QSStringIsEmpty(mimeType));
	NSParameterAssert(!QSStringIsEmpty(resourceName));
	NSParameterAssert(!QSStringIsEmpty(dateString));
	NSParameterAssert(contentLength > 0);
	NSParameterAssert(resultBlock != nil);

	NSURL *URL = [self URLWithRelativePath:@"api/blobs/urlForUploading" queryDictionary:@{@"filename" : resourceName, @"md5" : md5, @"mimeType" : mimeType, @"date" : dateString, @"contentLength" : @(contentLength)}];
	NSMutableURLRequest *request = [self URLRequestWithURL:URL];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Download Blog File Upload URL" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


- (void)uploadAttachmentDataToBlobStorage:(NSString *)uniqueID md5:(NSString *)md5 mimeType:(NSString *)mimeType contentLength:(uint64_t)contentLength urlString:(NSString *)urlString dateString:(NSString *)dateString authorization:(NSString *)authorization additionalHeaders:(NSDictionary *)additionalHeaders resultBlock:(VSAPIResultBlock)resultBlock {

	NSParameterAssert(!QSStringIsEmpty(uniqueID));
	NSParameterAssert(!QSStringIsEmpty(mimeType));
	NSParameterAssert(!QSStringIsEmpty(urlString));
	NSParameterAssert(resultBlock != nil);

	NSURL *uploadURL = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:uploadURL];
	[request setHTTPMethod:@"PUT"];
	[request setValue:mimeType forHTTPHeaderField:QSHTTPRequestHeaderContentType];
	[request setValue:md5 forHTTPHeaderField:@"Content-MD5"];
	[request setValue:[@(contentLength) stringValue] forHTTPHeaderField:@"Content-Length"];

	for (NSString *oneKey in additionalHeaders) {
		[request setValue:additionalHeaders[oneKey] forHTTPHeaderField:oneKey];
	}

	NSString *attachmentFilepath = [[VSAttachmentStorage sharedStorage] pathForAttachmentID:uniqueID];
	NSURL *attachmentURL = [NSURL fileURLWithPath:attachmentFilepath];

	NSURLSessionUploadTask *uploadTask = [self.URLSession uploadTaskWithRequest:request fromFile:attachmentURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

		VSAPIResult *result = [VSAPIResult resultWithRequest:request response:response data:data error:error];
		QSCallBlockWithParameter(resultBlock, result);

	}];

	uploadTask.taskDescription = @"Upload Attachment";
	[uploadTask resume];
}


- (void)uploadAttachmentData:(NSString *)attachmentDataPath uniqueID:(NSString *)uniqueID mimeType:(NSString *)mimeType resultBlock:(VSAPIResultBlock)resultBlock {

	[[VSAttachmentStorage sharedStorage] contentLengthForAttachment:uniqueID callback:^(NSNumber *contentLengthNum) {

		uint64_t contentLength = [contentLengthNum unsignedLongLongValue];
		if (contentLength < 1) {
			QSCallBlockWithParameter(resultBlock, nil);
			return;
		}

		[[VSAttachmentStorage sharedStorage] md5ForAttachment:uniqueID callback:^(NSData *md5Hash) {
			if (md5Hash == nil) {
				QSCallBlockWithParameter(resultBlock, nil);
				return;
			}

			NSString *md5 = [md5Hash base64EncodedStringWithOptions:0];
			NSString *dateString = VSHTTPDateString([NSDate date]);

			[self downloadBlobFileUploadURL:md5 mimeType:mimeType contentLength:contentLength resourceName:uniqueID dateString:dateString resultBlock:^(VSAPIResult *apiResult) {

				if (!apiResult.succeeded) {
					QSCallBlockWithParameter(resultBlock, apiResult);
					return;
				}

				NSDictionary *result = apiResult.JSONObject;
				if (QSIsEmpty(result)) {
					QSCallBlockWithParameter(resultBlock, apiResult);
					return;
				}
				NSString *urlString = result[@"url"];
				NSString *authorization = result[@"authorization"];
				NSDictionary *additionalHeaders = result[@"additionalHeaders"];

				if (QSStringIsEmpty(urlString)/* || QSStringIsEmpty(authorization)*/) {
					QSCallBlockWithParameter(resultBlock, apiResult);
					return;
				}

				[self uploadAttachmentDataToBlobStorage:uniqueID md5:md5 mimeType:mimeType contentLength:contentLength urlString:urlString dateString:dateString authorization:authorization additionalHeaders:additionalHeaders resultBlock:resultBlock];
			}];
		}];
	}];
}


- (void)downloadAttachmentData:(NSString *)uniqueID resultBlock:(VSAPIResultBlock)resultBlock {

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/blobs/download" queryDictionary:@{@"filename" : uniqueID}];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Download Blob Attachment" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


- (void)listAttachments:(VSAPIResultBlock)resultBlock {

	NSURL *URL = [self URLWithRelativePath:@"api/blobs/list" queryDictionary:nil];
	NSMutableURLRequest *request = [self URLRequestWithURL:URL];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"List Blob Attachments" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


- (void)deleteAttachmentData:(NSString *)uniqueID resultBlock:(VSAPIResultBlock)resultBlock {

	NSParameterAssert(!QSStringIsEmpty(uniqueID));
	NSParameterAssert(resultBlock != nil);

	NSString *relativeURL = [NSString stringWithFormat:@"/api/blobs/%@", uniqueID];
	NSMutableURLRequest *request = [self URLRequestWithRelativePath:relativeURL queryDictionary:nil];
	[request setHTTPMethod:@"DELETE"];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Delete Blob Attachment" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


#pragma mark - Tags

- (void)uploadTags:(NSArray *)JSONTags resultBlock:(VSAPIResultBlock)resultBlock {

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/tags" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request vs_addJSON:JSONTags];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Upload Tags" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


#pragma mark - Notes

- (void)uploadNotes:(NSArray *)JSONNotes syncToken:(NSString *)syncToken resultBlock:(VSAPIResultBlock)resultBlock {

	NSMutableURLRequest *request = [self URLRequestWithRelativePath:@"api/notes" queryDictionary:nil];
	[request setHTTPMethod:@"POST"];
	[request vs_addSyncToken:syncToken];
	[request vs_addJSON:JSONNotes];

	VSAPICall *apiCall = [self apiCallWithRequest:request taskDescription:@"Upload Notes" resultBlock:resultBlock];
	apiCall.setsAuthenticationToken = YES;
	[self addAPICall:apiCall];
}


#pragma mark - Utilities

- (NSURL *)URLWithRelativePath:(NSString *)relativePath queryDictionary:(NSDictionary *)queryDictionary {

	NSString *s = [NSString stringWithFormat:@"%@%@", VSAPIBaseURLString, relativePath];
	NSURL *URL = [NSURL URLWithString:s];

	if (!QSIsEmpty(queryDictionary)) {
		URL = [URL qs_URLByAppendingQueryDictionary:queryDictionary];
	}

	return URL;
}


- (NSMutableURLRequest *)URLRequestWithURL:(NSURL *)URL {

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];
	[request setValue:VSAPIAppString forHTTPHeaderField:@"x-zumo-application"];

	return request;
}


- (NSMutableURLRequest *)URLRequestWithRelativePath:(NSString *)relativePath queryDictionary:(NSDictionary *)queryDictionary {

	NSURL *URL = [self URLWithRelativePath:relativePath queryDictionary:queryDictionary];
	return [self URLRequestWithURL:URL];
}


- (void)addJSON:(id)obj toURLRequest:(NSMutableURLRequest *)request {

	NSError *error = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];

	NSAssert(error == nil, nil);

	[request setHTTPBody:data];
	[request setValue:QSHTTPContentTypeJSON forHTTPHeaderField:QSHTTPRequestHeaderContentType];
}


#pragma mark - Cancel

- (void)cancel {

	[[NSOperationQueue mainQueue] cancelAllOperations];
}


@end


@implementation NSMutableURLRequest (Vesper)

- (void)vs_addJSON:(id)obj {

	NSError *error = nil;
	NSData *data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:&error];

	NSAssert(error == nil, nil);
	if (error != nil) {
		NSLog(@"addJSON error: %@", error);
	}

	[self setHTTPBody:data];
	[self setValue:QSHTTPContentTypeJSON forHTTPHeaderField:QSHTTPRequestHeaderContentType];
}


- (void)vs_safeSetValue:(NSString *)value forHTTPHeaderField:(NSString *)key {
	
	if (!QSStringIsEmpty(value)) {
		[self setValue:value forHTTPHeaderField:key];
	}
}



- (void)vs_addSyncToken:(NSString *)syncToken {
	[self vs_safeSetValue:syncToken forHTTPHeaderField:@"x-vesper-synctoken"];
}


@end

