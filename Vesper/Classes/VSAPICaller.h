//
//  VSAPICaller.h
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSAPICall.h"


@interface VSAPICaller : NSObject


@property (nonatomic, assign, readonly) BOOL syncInProgress;
@property (nonatomic, weak) id<VSAPICallDelegate> delegate;


/*Account*/

- (void)createAccount:(NSString *)username password:(NSString *)password emailUpdates:(BOOL)emailUpdates resultBlock:(VSAPIResultBlock)resultBlock;
- (void)login:(NSString *)username password:(NSString *)password resultBlock:(VSAPIResultBlock)resultBlock;

- (void)forgotPassword:(NSString *)username resultBlock:(VSAPIResultBlock)resultBlock;

- (void)changePassword:(NSString *)updatedPassword resultBlock:(VSAPIResultBlock)resultBlock;


/*Email Updates*/

- (void)downloadEmailUpdatesSetting:(NSString *)authenticationToken resultBlock:(VSAPIResultBlock)resultBlock;
- (void)uploadEmailUpdatesSetting:(BOOL)emailUpdates resultBlock:(VSAPIResultBlock)resultBlock;


/*Sync*/

- (void)uploadDeletedNotes:(NSArray *)deletedNotes syncToken:(NSString *)syncToken resultBlock:(VSAPIResultBlock)resultBlock;
- (void)uploadTags:(NSArray *)JSONTags resultBlock:(VSAPIResultBlock)resultBlock;
- (void)uploadNotes:(NSArray *)JSONNotes syncToken:(NSString *)syncToken resultBlock:(VSAPIResultBlock)resultBlock;


/*Attachment data*/

- (void)uploadAttachmentData:(NSString *)attachmentDataPath uniqueID:(NSString *)uniqueID mimeType:(NSString *)mimeType resultBlock:(VSAPIResultBlock)resultBlock;
- (void)downloadAttachmentData:(NSString *)uniqueID resultBlock:(VSAPIResultBlock)resultBlock;
- (void)listAttachments:(VSAPIResultBlock)resultBlock;
- (void)deleteAttachmentData:(NSString *)uniqueID resultBlock:(VSAPIResultBlock)resultBlock;


/*Cancel*/

- (void)cancel;


@end
