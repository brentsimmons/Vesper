//
//  VSAccount.h
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


#import "VSAPICaller.h"


extern NSString *VSAccountExistsNotification; /*If has both of local username/password; may not be loggedd-in.*/
extern NSString *VSAccountDoesNotExistNotification; /*If either of local username or password are empty.*/
extern NSString *VSAccountDidAttemptLoginNotification; /*Might have succeeded, might not. Called after properties are updated.*/

extern NSString *VSAccountUserDidSignOutNotification;

extern NSString *VSAccountUserDidSignInManuallyNotification;
extern NSString *VSAccountUserDidCreateAccountNotification;

extern NSString *VSLoginAuthenticationErrorNotification;
extern NSString *VSLoginAuthenticationSuccessfulNotification;

extern NSString *VSSyncDidDownloadNotesNotification; /*userInfo: VSNotesKey -- JSON version of notes from server.*/


@interface VSAccount : NSObject


+ (instancetype)account;

- (BOOL)hasUsernameAndPassword;

- (void)createAccount:(NSString *)username password:(NSString *)password emailUpdates:(BOOL)emailUpdates resultBlock:(VSAPIResultBlock)resultBlock;
- (void)login:(NSString *)username password:(NSString *)password resultBlock:(VSAPIResultBlock)resultBlock;
- (void)login:(VSAPIResultBlock)resultBlock;

- (void)signOut;

- (void)forgotPassword:(NSString *)username resultBlock:(VSAPIResultBlock)resultBlock;
- (void)changePassword:(NSString *)updatedPassword resultBlock:(VSAPIResultBlock)resultBlock;

- (void)downloadEmailUpdatesSetting:(VSAPIResultBlock)resultBlock;
- (void)uploadEmailUpdatesSetting:(VSAPIResultBlock)resultBlock;

- (void)sync;
- (void)cancelSync;

- (BOOL)usernameIsValid:(NSString *)username;
- (BOOL)passwordIsValid:(NSString *)password;

@property (nonatomic, assign) BOOL emailUpdates;
@property (nonatomic, assign, readonly) BOOL loggedIn; /*Observable*/
@property (nonatomic) NSDate *lastSyncDate;
@property (nonatomic, readonly) NSString *username;
@property (nonatomic, readonly) BOOL loginDidFailWithAuthenticationError;
@property (nonatomic, readonly) BOOL syncInProgress;

@end
