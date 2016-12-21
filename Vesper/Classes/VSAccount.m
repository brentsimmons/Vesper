//
//  VSAccount.m
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSAccount.h"
#import "VSAPICaller.h"
#import "VSAPIResult.h"
#import "VSSyncTagMerger.h"
#import "VSSyncNoteMerger.h"
#import "VSKeychain.h"
#import "VSAPICall.h"
#import "QSDateParser.h"
#import "QSMimeTypes.h"
#import "VSAttachmentStorage.h"
#import "VSAttachmentData.h"
#import "VSThumbnail.h"
#import "VSDateManager.h"

static NSString *VSDefaultsAllowEmailKey = @"allowEmail";
NSString *VSAccountUserDidSignInManuallyNotification = @"VSAccountUserDidSignInManuallyNotification";
NSString *VSAccountUserDidCreateAccountNotification = @"VSAccountUserDidCreateAccountNotification";


@interface VSAccount () <VSAPICallDelegate>

@property (nonatomic) NSManagedObjectContext *context;
@property (nonatomic) VSAPICaller *apiCaller;
@property (nonatomic, readwrite) NSString *username;
@property (nonatomic, readwrite) NSString *password;
@property (nonatomic) NSDate *lastSyncStartDate;
@property (nonatomic, readwrite) NSString *syncTokenForDeletedNotes;
@property (nonatomic, readwrite) NSString *syncTokenForNotes;
@property (nonatomic) NSDate *lastNotesFetchDate;
@property (nonatomic) NSString *authenticationToken;
@property (nonatomic, readwrite) BOOL loggedIn;
@property (nonatomic, readwrite) BOOL loginDidFailWithAuthenticationError;
@property (nonatomic) NSDate *syncExpirationDate;
@property (nonatomic) NSMutableSet *attachmentIDsBeingUploaded;
@property (nonatomic) NSMutableSet *attachmentIDsBeingDownloaded;
@property (nonatomic) NSMutableSet *attachmentIDsUploaded;
@property (nonatomic, readwrite) BOOL syncInProgress;

@end


@implementation VSAccount

#pragma mark - Class Methods

+ (instancetype)account {

	static id gMyInstance = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gMyInstance = [self new];
	});

	return gMyInstance;
}


#pragma mark - Init

- (instancetype)init {

	self = [super init];
	if (self == nil) {
		return nil;
	}

	_apiCaller = [VSAPICaller new];
	_apiCaller.delegate = self;
	
	_lastSyncStartDate = [NSDate distantPast];

	_attachmentIDsBeingDownloaded = [NSMutableSet set];
	_attachmentIDsBeingUploaded = [NSMutableSet set];
	_attachmentIDsUploaded = [NSMutableSet set];

//	[[VSAttachmentStorage sharedStorage] attachmentIDsSortedByFileSize:^(NSArray *diskAttachmentIDs) {
//
//		NSLog(@"diskAttachmentIDs: %@", diskAttachmentIDs);
//	}];

	/*Testing*/
//	self.password = @"123456789";

//	[self performSelectorOnMainThread:@selector(testCreateAccount) withObject:nil waitUntilDone:NO];

//	[self login:self.username password:self.password resultBlock:^(VSAPIResult *apiResult) {
////		[self downloadEmailUpdatesSetting:nil];
////		[self uploadEmailUpdatesSetting:YES resultBlock:nil];
////		[self changePassword:@"123456123456" resultBlock:nil];
////		[self testUploadTags];
////		[self testUploadDeletedNotes];
//
//////		[self performSelectorOnMainThread:@selector(testCreateAccount) withObject:nil waitUntilDone:NO];
//		[self testUploadAttachment];
////		[self testListBlobs];
////		[self testDownloadAttachment];
////		[self testDeleteAttachment];
//////		[self performSelectorOnMainThread:@selector(testDownloadAttachment) withObject:nil waitUntilDone:NO];
//////		[self performSelectorOnMainThread:@selector(listAttachments) withObject:nil waitUntilDone:NO];
//////		[self performSelectorOnMainThread:@selector(testDeleteAttachment) withObject:nil waitUntilDone:NO];
//	}];

	[self fetchPasswordFromKeychain];

	[self performSelectorOnMainThread:@selector(notifyOfAccountExistence) withObject:nil waitUntilDone:NO];

	if ([self hasUsernameAndPassword]) {
		[self performSelectorOnMainThread:@selector(loginIfNeeded) withObject:nil waitUntilDone:NO];
	}

//	[self performSelectorOnMainThread:@selector(testUploadNotes) withObject:nil waitUntilDone:NO];

#if TARGET_OS_IPHONE
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerSync:) name:UIApplicationDidBecomeActiveNotification object:nil];
#endif

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerSync:) name:VSNoteUserDidEditNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coalescedSync) name:VSAccountUserDidSignInManuallyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerSync:) name:VSAccountUserDidCreateAccountNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerSync:) name:VSDidCopyNoteNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidBegin:) name:VSSyncDidBeginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidComplete:) name:VSSyncDidCompleteNotification object:nil];

	return self;
}


#pragma mark - Manual Tests

- (void)testForgotPassword {

	[self.apiCaller forgotPassword:self.username resultBlock:^(VSAPIResult *apiResult) {
		//		NSLog(@"testForgotPassword");
	}];
}


- (void)testDeleteAttachment {

	NSString *uniqueID = @"tutorial3";

	[self.apiCaller deleteAttachmentData:uniqueID resultBlock:^(VSAPIResult *apiResult) {

//		NSLog(@"apiResult: %@", apiResult.resultString);
	}];
}


- (void)testUploadAttachment {

	NSString *uniqueID = @"tutorial3";
	NSString *f = [[VSAttachmentStorage sharedStorage] filenameForImage:uniqueID imageQuality:VSImageQualityFull];

	[self.apiCaller uploadAttachmentData:f uniqueID:uniqueID mimeType:@"image/jpeg" resultBlock:^(VSAPIResult *apiResult) {

//		NSLog(@"apiResult: %@", apiResult.resultString);
	}];

}


- (void)testDownloadAttachment {
	NSString *uniqueID = @"tutorial3";

	[self.apiCaller downloadAttachmentData:uniqueID resultBlock:^(VSAPIResult *apiResult) {

		NSData *d = apiResult.data;
		[d writeToFile:@"/Users/brent/Desktop/foo" options:NSDataWritingAtomic error:nil];
	}];


}


- (void)testCreateAccount {

	[self.apiCaller createAccount:@"brent+9@ranchero.com" password:@"123456789" emailUpdates:NO resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {

			NSLog(@"account created");
		}

		else {
			NSLog(@"Create account failed.");
		}
	}];
}


- (void)testListBlobs {

	[self.apiCaller listAttachments:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
//			NSLog(@"listAttachments %@", apiResult.resultString);
		}
		else {
//			NSLog(@"listAttachments failed.");
		}
	}];
}


- (void)testUploadTags {

#if TARGET_OS_IPHONE

	@autoreleasepool {

		VSTag *tag0 = [[VSTag alloc] initWithName:@"Foo"];
		VSTag *tag1 = [[VSTag alloc] initWithName:@"Bar"];
		VSTag *tag2 = [[VSTag alloc] initWithName:@"BAZ"];
		VSTag *tag3 = [[VSTag alloc] initWithName:@"BAZingle"];
		VSTag *tag4 = [[VSTag alloc] initWithName:@"Forest"];
		VSTag *tag5 = [[VSTag alloc] initWithName:@"house work"];
		VSTag *tag6 = [[VSTag alloc] initWithName:@"WWDC"];
		VSTag *tag7 = [[VSTag alloc] initWithName:@"Office party"];
		VSTag *tag8 = [[VSTag alloc] initWithName:@"Redwoods"];
		VSTag *tag9 = [[VSTag alloc] initWithName:@"Roof"];
		VSTag *tag10 = [[VSTag alloc] initWithName:@"Floor"];
		VSTag *tag11 = [[VSTag alloc] initWithName:@"Tile"];
		VSTag *tag12 = [[VSTag alloc] initWithName:@"bear"];

		NSArray *tags = @[tag0, tag1, tag2, tag3, tag4, tag5, tag6, tag7, tag8, tag9, tag10, tag11, tag12];

		[self.apiCaller uploadTags:tags resultBlock:^(VSAPIResult *apiResult) {

			if (apiResult.succeeded) {
//				NSLog(@"%@", apiResult.parsedObject);//VSSyncMergeTags(apiResult.parsedObject);
			}
		}];
	}
#endif
}


- (void)testUploadDeletedNotes {

	NSArray *deletedNotes = @[@(123), @(456), @(789), @(9007199254740992), @(9007188254740992)];

	[self.apiCaller uploadDeletedNotes:deletedNotes syncToken:nil resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
//			NSLog(@"%@", apiResult.parsedObject);//VSSyncMergeTags(apiResult.parsedObject);
		}
	}];
}


- (void)testUploadNotes {

#if TARGET_OS_IPHONE

	VSNote *note0 = [[VSNote alloc] initWithUniqueID:100];
	note0.text = @"This is a test note.";
	[note0 textDidChange];

	VSNote *note1 = [[VSNote alloc] initWithUniqueID:101];
	note1.text = @"apple.com";
	[note1 textDidChange];

	VSNote *note2 = [[VSNote alloc] initWithUniqueID:102];
	note2.text = @"This is a note with a link. http://inessential.com/ Yup.";
	[note2 textDidChange];
	note2.archived = NO;
	note2.archivedModificationDate = [[VSDateManager sharedManager] currentDate];

	VSNote *note3 = [[VSNote alloc] initWithUniqueID:103];
	note3.text = @"I like cats. Yup.";
	note3.textModificationDate = [[VSDateManager sharedManager] currentDate];
	[note3 textDidChange];

	NSArray *notes = @[note0, note1, note2, note3];

	[self.apiCaller uploadNotes:notes syncToken:nil resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
//			NSLog(@"testUploadNotes %@", apiResult.parsedObject);
		}
		else {
//			NSLog(@"testUploadNotes failed %@", apiResult.resultString);
		}
	}];

#endif
}


#pragma mark - Notifications

NSString *VSAccountExistsNotification = @"VSAccountExistsNotification";
NSString *VSAccountDoesNotExistNotification = @"VSAccountDoesNotExistNotification";

- (void)notifyOfAccountExistence {

	NSString *notificationName = VSAccountExistsNotification;

	if (QSStringIsEmpty(self.username) || QSStringIsEmpty(self.password)) {
		notificationName = VSAccountDoesNotExistNotification;
	}

	[[NSNotificationCenter defaultCenter] qs_postNotificationNameOnMainThread:notificationName object:self userInfo:nil];
}


- (void)triggerSync:(NSNotification *)note {

	if (![self hasUsernameAndPassword] || self.loginDidFailWithAuthenticationError) {

		return;
	}

	[self coalescedSync];
}


- (void)syncDidBegin:(NSNotification *)note {

	self.syncInProgress = YES;
}


- (void)syncDidComplete:(NSNotification *)note {

	[self coalescedSetLastSyncDate];
	self.syncInProgress = NO;
}


- (void)updateLastSyncDate {
	self.lastSyncDate = [NSDate date];
}


- (void)coalescedSetLastSyncDate {

	[self qs_performSelectorCoalesced:@selector(updateLastSyncDate) withObject:nil afterDelay:2.0];
}


#pragma mark - Password

- (void)fetchPasswordFromKeychain {

	if (QSStringIsEmpty(self.username)) {
		return;
	}

	NSError *error = nil;
	NSString *password = nil;
	if (VSKeychainGetPassword(self.username, &password, &error)) {
		self.password = password;
	}
}


- (void)savePasswordInKeychain {

	if (QSStringIsEmpty(self.username)) {
		return;
	}

	NSError *error = nil;

	if (QSStringIsEmpty(self.password)) {
		[self deletePasswordFromKeychain];
	}
	else {
		VSKeychainSetPassword(self.username, self.password, &error);
	}
}


- (void)deletePasswordFromKeychain {

	if (QSStringIsEmpty(self.username)) {
		return;
	}

	NSError *error = nil;
	VSKeychainDeletePassword(self.username, &error);
}


#pragma mark - Accessors

- (NSString *)username {
	return [[NSUserDefaults standardUserDefaults] stringForKey:VSDefaultsSyncUsernameKey];
}


- (void)setUsername:(NSString *)s {
	[[NSUserDefaults standardUserDefaults] setObject:s forKey:VSDefaultsSyncUsernameKey];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSString *)syncTokenForDeletedNotes {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"syncTokenDeletedNotes"];
}


- (void)setSyncTokenForDeletedNotes:(NSString *)syncToken {
	[[NSUserDefaults standardUserDefaults] setObject:syncToken forKey:@"syncTokenDeletedNotes"];
}


- (NSString *)syncTokenForNotes {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"syncTokenForNotes"];
}


- (void)setSyncTokenForNotes:(NSString *)syncToken {
	[[NSUserDefaults standardUserDefaults] setObject:syncToken forKey:@"syncTokenForNotes"];
}


- (NSDate *)lastNotesFetchDate {
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"syncLastNotesFetchDate"];
}


- (void)setLastNotesFetchDate:(NSDate *)lastNotesFetchDate {
	[[NSUserDefaults standardUserDefaults] setObject:lastNotesFetchDate forKey:@"syncLastNotesFetchDate"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


static NSString *syncExpirationDateKey = @"syncExpirationDate";

- (NSDate *)syncExpirationDate {
	return [[NSUserDefaults standardUserDefaults] objectForKey:syncExpirationDateKey];
}


- (void)setSyncExpirationDate:(NSDate *)d {

	if (!d) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:syncExpirationDateKey];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:d forKey:syncExpirationDateKey];
	}
}


- (BOOL)hasUsernameAndPassword {
	return !QSStringIsEmpty(self.username) && !QSStringIsEmpty(self.password);

}


- (BOOL)emailUpdates {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"accountEmailUpdates"];
}


- (void)setEmailUpdates:(BOOL)emailUpdates {
	[[NSUserDefaults standardUserDefaults] setBool:emailUpdates forKey:@"accountEmailUpdates"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


static NSString *VSAccountLastSyncDateKey = @"accountLastSync";

- (NSDate *)lastSyncDate {

	return [[NSUserDefaults standardUserDefaults] objectForKey:VSAccountLastSyncDateKey];
}


- (void)setLastSyncDate:(NSDate *)lastSyncDate {

	[self willChangeValueForKey:@"lastSyncDate"];
	if (!lastSyncDate) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:VSAccountLastSyncDateKey];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:lastSyncDate forKey:VSAccountLastSyncDateKey];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self didChangeValueForKey:@"lastSyncDate"];
}


#pragma mark - Account

NSString *VSAccountUserDidSignInNotification = @"VSAccountUserDidSignInNotification";

- (void)createAccount:(NSString *)username password:(NSString *)password emailUpdates:(BOOL)emailUpdates resultBlock:(VSAPIResultBlock)resultBlock {

	[self.apiCaller createAccount:username password:password emailUpdates:emailUpdates resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {

			self.emailUpdates = emailUpdates;
			self.username = username;
			self.password = password;
			[self savePasswordInKeychain];

			[self notifyOfAccountExistence];
		}

		QSCallBlockWithParameter(resultBlock, apiResult);
	}];
}


- (void)forgotPassword:(NSString *)username resultBlock:(VSAPIResultBlock)resultBlock {

	[self.apiCaller forgotPassword:username resultBlock:resultBlock];
}


NSString *VSLoginAuthenticationErrorNotification = @"VSLoginAuthenticationErrorNotification";
NSString *VSLoginAuthenticationSuccessfulNotification = @"VSLoginAuthenticationSuccessfulNotification";
NSString *VSAccountDidAttemptLoginNotification = @"VSAccountDidAttemptLoginNotification";


- (void)login:(NSString *)username password:(NSString *)password resultBlock:(VSAPIResultBlock)resultBlock {

	[self.apiCaller login:username password:password resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
			self.username = username;

			if (!self.password || ![self.password isEqualToString:password]) {
				self.password = password;
				[self savePasswordInKeychain];
			}

			NSDictionary *d = apiResult.JSONObject;
			self.authenticationToken = d[VSAccountAuthenticationTokenKey];
			self.emailUpdates = [d qs_boolForKey:VSAccountEmailUpdatesKey];

			NSString *syncExpirationDateString = d[VSAccountSyncExpirationDateKey];
			if (syncExpirationDateString) {
				self.syncExpirationDate = QSDateWithString(syncExpirationDateString);
			}
			
			self.loggedIn = YES;
			self.loginDidFailWithAuthenticationError = NO;

			[[NSNotificationCenter defaultCenter] postNotificationName:VSLoginAuthenticationSuccessfulNotification object:self];
		}
		else {

			self.loggedIn = NO;
			self.authenticationToken = nil;

			if (apiResult.statusCode == 401) {
				self.loginDidFailWithAuthenticationError = YES;
				[[NSNotificationCenter defaultCenter] postNotificationName:VSLoginAuthenticationErrorNotification object:self];
			}
			else {
				self.loginDidFailWithAuthenticationError = NO;
			}
		}

		[self notifyOfAccountExistence];
		[[NSNotificationCenter defaultCenter] postNotificationName:VSAccountDidAttemptLoginNotification object:self];

		QSCallBlockWithParameter(resultBlock, apiResult);
	}];
}


- (void)login:(VSAPIResultBlock)resultBlock {

	[self login:self.username password:self.password resultBlock:resultBlock];
}


- (void)loginIfNeeded {

	if (!self.authenticationToken && [self hasUsernameAndPassword]) {
		[self login:nil];
	}
}


- (void)changePassword:(NSString *)updatedPassword resultBlock:(VSAPIResultBlock)resultBlock {

	[self.apiCaller changePassword:updatedPassword resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
			self.password = updatedPassword;
			[self savePasswordInKeychain];
		}

		if (resultBlock) {
			resultBlock(apiResult);
		}
	}];
}

	 
NSString *VSAccountUserDidSignOutNotification = @"VSAccountUserDidSignOutNotification";

- (void)signOut {

	[self.apiCaller cancel];

	self.username = nil;
	self.password = nil;
	[self deletePasswordFromKeychain];

	self.loginDidFailWithAuthenticationError = NO;
	self.authenticationToken = nil;
	self.syncExpirationDate = nil;
	self.lastSyncDate = nil;
	self.loggedIn = NO;
	self.syncTokenForDeletedNotes = nil;
	self.syncTokenForNotes = nil;
	self.lastNotesFetchDate = nil;
	[self.attachmentIDsBeingUploaded removeAllObjects];
	[self.attachmentIDsBeingDownloaded removeAllObjects];
	[self.attachmentIDsUploaded removeAllObjects];

	[[NSUserDefaults standardUserDefaults] synchronize];
	
	[self notifyOfAccountExistence];

	[[NSNotificationCenter defaultCenter] postNotificationName:VSAccountUserDidSignOutNotification object:self];
}


#pragma mark - Sync


- (void)coalescedSync {

	[self qs_performSelectorCoalesced:@selector(sync) withObject:nil afterDelay:2.0];
}


- (void)sync {

	if (self.apiCaller.syncInProgress || ![self hasUsernameAndPassword]) {
//		NSLog(@"sync in progress %@ %@", self.username, self.password);
		return;
	}

//	NSLog(@"sync");
	[self uploadTags];
	[self uploadDeletedNotes];
	[self uploadNotes];
	[self syncAttachments];
}


#pragma mark - Email Updates

- (void)downloadEmailUpdatesSetting:(VSAPIResultBlock)resultBlock {

	if (![self hasUsernameAndPassword]) {
		QSCallBlockWithParameter(resultBlock, nil);
		return;
	}

	[self.apiCaller downloadEmailUpdatesSetting:self.authenticationToken resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
			self.emailUpdates = [apiResult.JSONObject[@"emailUpdates"] boolValue];
		}
		QSCallBlockWithParameter(resultBlock, apiResult);
	}];
}


- (void)uploadEmailUpdatesSetting:(BOOL)emailUpdates resultBlock:(VSAPIResultBlock)resultBlock {

	[self.apiCaller uploadEmailUpdatesSetting:emailUpdates resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
			self.emailUpdates = emailUpdates;
		}

		QSCallBlockWithParameter(resultBlock, apiResult);
	}];
}


- (void)uploadEmailUpdatesSetting:(VSAPIResultBlock)resultBlock {

	[self uploadEmailUpdatesSetting:self.emailUpdates resultBlock:resultBlock];
}


#pragma mark - Deleted Objects

- (void)uploadDeletedNotes {

	[[VSDataController sharedController] uniqueIDsInDeletedNotesTable:^(NSArray *fetchedDeletedNoteIDs) {

		[self.apiCaller uploadDeletedNotes:fetchedDeletedNoteIDs syncToken:nil resultBlock:^(VSAPIResult *apiResult) {

			if (!apiResult.succeeded) {
				return;
			}

			[[VSDataController sharedController] deleteNotes:apiResult.JSONObject userDidDelete:NO];
			[[VSDataController sharedController] removeUniqueIDsFromDeletedNotesTable:fetchedDeletedNoteIDs];

			self.syncTokenForDeletedNotes = apiResult.responseSyncToken;
			[self coalescedSetLastSyncDate];
		}];
	}];
}


#pragma mark - Tags

- (void)uploadTags {

	NSArray *tags = [VSDataController sharedController].allTags;
	NSArray *JSONTags = [QSAPIObject JSONArrayWithObjects:tags];
	
	[self.apiCaller uploadTags:JSONTags resultBlock:^(VSAPIResult *apiResult) {

		if (apiResult.succeeded) {
			VSSyncMergeTags(apiResult.JSONObject, [VSDataController sharedController], nil);
			[self coalescedSetLastSyncDate];
		}
	}];
}


#pragma mark - Notes

NSString *VSSyncDidDownloadNotesNotification = @"VSSyncDidDownloadNotesNotification";

- (void)uploadNotes {

	NSDate *lastNotesFetchDate = self.lastNotesFetchDate;
	lastNotesFetchDate = [lastNotesFetchDate dateByAddingTimeInterval:-10]; /*There is a case where undeleting a note can give a note a mod date right before lastNotesFetchDate.*/
	NSDate *now = [NSDate date];

	[[VSDataController sharedController] JSONNotesModifiedSinceDate:lastNotesFetchDate fetchResultsBlock:^(NSArray *JSONNotes) {

//		NSLog(@"JSONNotesModifiedSinceDate: %@", JSONNotes);

		[self.apiCaller uploadNotes:JSONNotes syncToken:self.syncTokenForNotes resultBlock:^(VSAPIResult *apiResult) {

			if (!apiResult.succeeded) {
				return;
			}

//			NSLog(@"notes from server: %@", apiResult.JSONObject);
			VSSyncMergeNotes(apiResult.JSONObject, [VSDataController sharedController], ^(void) {

				self.syncTokenForNotes = apiResult.responseSyncToken;
				self.lastNotesFetchDate = now;

				[self coalescedSetLastSyncDate];

				NSArray *serverNotes = apiResult.JSONObject;
				if (serverNotes.count > 0) {
					[[NSNotificationCenter defaultCenter] postNotificationName:VSSyncDidDownloadNotesNotification object:self userInfo:@{VSNotesKey : serverNotes}];
				}
			});
		}];
	}];
}


#pragma mark - Attachment Data

- (void)uploadAttachmentData:(NSString *)attachmentDataPath uniqueID:(NSString *)uniqueID resultBlock:(VSAPIResultBlock)resultBlock {

	NSString *mimeType = QSMimeTypeForFile(attachmentDataPath);
	[self.apiCaller uploadAttachmentData:attachmentDataPath uniqueID:uniqueID mimeType:mimeType resultBlock:resultBlock];
}


- (void)downloadAttachmentData:(NSString *)uniqueID resultBlock:(VSAPIResultBlock)resultBlock {

	[self.apiCaller downloadAttachmentData:uniqueID resultBlock:resultBlock];
}


- (void)listAttachments:(VSAPIResultBlock)resultBlock {

	[self.apiCaller listAttachments:resultBlock];
}


- (void)uploadAttachment:(NSString *)attachmentID {

	if ([attachmentID hasPrefix:@"tutorial"]) {
		return;
	}

	if ([self.attachmentIDsBeingUploaded containsObject:attachmentID]) {
		return;
	}
	if ([self.attachmentIDsUploaded containsObject:attachmentID]) {
		return;
	}

	NSString *path =  [[VSAttachmentStorage sharedStorage] pathForAttachmentID:attachmentID];


	BOOL isDirectory = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
		return;
	}

	[self.attachmentIDsBeingUploaded addObject:attachmentID];
	[self uploadAttachmentData:path uniqueID:attachmentID resultBlock:^(VSAPIResult *apiResult) {

		[self.attachmentIDsBeingUploaded removeObject:attachmentID];
		[self.attachmentIDsUploaded addObject:attachmentID];
	}];
}


- (void)downloadAttachment:(NSString *)attachmentID {

#if TARGET_OS_IPHONE

	if ([attachmentID hasPrefix:@"tutorial"]) {
		return;
	}
	if ([self.attachmentIDsBeingDownloaded containsObject:attachmentID]) {
		return;
	}

	NSString *path = [[VSAttachmentStorage sharedStorage] pathForAttachmentID:attachmentID];
	BOOL isDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
		return;
	}

	[self.attachmentIDsBeingDownloaded addObject:attachmentID];

	[self downloadAttachmentData:attachmentID resultBlock:^(VSAPIResult *apiResult) {

		[self.attachmentIDsBeingDownloaded removeObject:attachmentID];

		if (apiResult.succeeded) {

			if ([apiResult.data qs_dataIsImage]) {

				[QS_IMAGE qs_imageWithData:apiResult.data imageResultBlock:^(UIImage *image) {

					[[VSAttachmentStorage sharedStorage] saveImageAttachment:image attachmentID:attachmentID];
				}];
			}
			else {

				[[VSAttachmentStorage sharedStorage] saveAttachmentData:apiResult.data attachmentID:attachmentID];
			}
		}
	}];

#endif
}


- (BOOL)attachmentID:(NSString *)attachmentID isInAttachmentIDs:(NSArray *)attachmentIDs {

	if ([attachmentIDs containsObject:attachmentID]) {
		return YES;
	}

	/*Deal with @"-low"-suffixed attachment IDs.*/

	if ([attachmentID hasSuffix:VSLowQualityImageExtension]) {

		attachmentID = [attachmentID substringToIndex:attachmentID.length - VSLowQualityImageExtension.length];

		if ([attachmentIDs containsObject:attachmentID]) {
			return YES;
		}
	}

	return NO;
}


- (BOOL)attachmentID:(NSString *)attachmentID matchesImageQuality:(VSImageQuality)imageQuality {

	BOOL isLowQuality = [attachmentID hasSuffix:VSLowQualityImageExtension];

	if (isLowQuality) {
		return imageQuality == VSImageQualityLow;
	}
	return imageQuality == VSImageQualityFull;
}


- (void)uploadAttachments:(NSArray *)referencedAttachmentIDs serverAttachmentIDs:(NSArray *)serverAttachmentIDs diskAttachmentIDs:(NSArray *)diskAttachmentIDs imageQuality:(VSImageQuality)imageQuality {

	for (NSString *oneDiskAttachmentID in diskAttachmentIDs) {

		if ([oneDiskAttachmentID hasPrefix:@"tutorial"]) {
			continue;
		}
		
		/*Is wrong quality level?*/

		if (![self attachmentID:oneDiskAttachmentID matchesImageQuality:imageQuality]) {
			continue;
		}

		/*On server already?*/

		if ([serverAttachmentIDs containsObject:oneDiskAttachmentID]) {
			continue;
		}

		/*Referenced by a note?*/

		if (![self attachmentID:oneDiskAttachmentID isInAttachmentIDs:referencedAttachmentIDs]) {
			continue;
		}

		[self uploadAttachment:oneDiskAttachmentID];
	}
}


- (void)downloadAttachments:(NSArray *)serverAttachmentIDs diskAttachmentIDs:(NSArray *)diskAttachmentIDs imageQuality:(VSImageQuality)imageQuality {

	for (NSString *oneServerAttachmentID in serverAttachmentIDs) {

		if (![self attachmentID:oneServerAttachmentID matchesImageQuality:imageQuality]) {
			continue;
		}

		if (![diskAttachmentIDs containsObject:oneServerAttachmentID]) {
			[self downloadAttachment:oneServerAttachmentID];
		}
	}
}


- (void)syncAttachments {

	[self listAttachments:^(VSAPIResult *apiResult) {

		if (!apiResult.succeeded) {
			return;
		}

		NSArray *attachmentsOnServer = apiResult.JSONObject;
		if (!QSIsEmpty(attachmentsOnServer)) {
			attachmentsOnServer = [attachmentsOnServer valueForKey:@"name"];
		}

		[[VSDataController sharedController] attachmentIDsInLookupTable:^(NSArray *referencedAttachmentIDs) {

			[[VSAttachmentStorage sharedStorage] attachmentIDsSortedByFileSize:^(NSArray *diskAttachmentIDs) {

				[self uploadAttachments:referencedAttachmentIDs serverAttachmentIDs:attachmentsOnServer diskAttachmentIDs:diskAttachmentIDs imageQuality:VSImageQualityLow];
				[self downloadAttachments:attachmentsOnServer diskAttachmentIDs:diskAttachmentIDs imageQuality:VSImageQualityLow];

				[self uploadAttachments:referencedAttachmentIDs serverAttachmentIDs:attachmentsOnServer diskAttachmentIDs:diskAttachmentIDs imageQuality:VSImageQualityFull];
				[self downloadAttachments:attachmentsOnServer diskAttachmentIDs:diskAttachmentIDs imageQuality:VSImageQualityFull];
			}];
		}];
	}];
}

#pragma mark - Cancel


- (void)cancelSync {

	[self.apiCaller cancel];
}


#pragma mark - Validating

- (BOOL)usernameIsValid:(NSString *)username {

	/*Must be a valid email address.*/

	if (QSStringIsEmpty(username)) {
		return NO;
	}

	if ([username rangeOfString:@"."].length < 1) {
		return NO;
	}
	if ([username rangeOfString:@"@"].length < 1) {
		return NO;
	}

	if ([username length] < 5) {
		return NO;
	}
	if ([username length] > 200) {
		return NO;
	}

	NSRange rangeOfWhitespaceCharacter = [username rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (rangeOfWhitespaceCharacter.location != NSNotFound) {
		return NO;
	}
	NSRange rangeOfControlCharacter = [username rangeOfCharacterFromSet:[NSCharacterSet controlCharacterSet]];
	if (rangeOfControlCharacter.location != NSNotFound) {
		return NO;
	}

	return YES;
}


- (BOOL)passwordIsValid:(NSString *)password {

	if (QSStringIsEmpty(password)) {
		return NO;
	}

	if ([password length] < 7) {
		return NO;
	}
	if ([password length] > 200) {
		return NO;
	}

	NSRange rangeOfControlCharacter = [password rangeOfCharacterFromSet:[NSCharacterSet controlCharacterSet]];
	if (rangeOfControlCharacter.location != NSNotFound) {
		return NO;
	}

	return YES;
}


#pragma mark - VSAPICallDelegate

- (void)authenticationToken:(QSObjectResultBlock)resultBlock {

	if (![self hasUsernameAndPassword]) {
		QSCallBlockWithParameter(resultBlock, nil);
		return;
	}

	if (self.authenticationToken) {
		QSCallBlockWithParameter(resultBlock, self.authenticationToken);
		return;
	}

	[self login:^(VSAPIResult *apiResult) {
		
		QSCallBlockWithParameter(resultBlock, self.authenticationToken);
	}];
}


- (void)authenticationTokenIsInvalid:(NSString *)authenticationToken {

	if ([authenticationToken isEqualToString:self.authenticationToken]) {
		self.authenticationToken = nil;
	}
}


@end

