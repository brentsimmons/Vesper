//
//  VSSyncConstants.m
//  Vesper
//
//  Created by Brent Simmons on 11/5/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//


/*These strings are shared with the server and shouldn't be changed.*/


NSString *VSSyncUniqueIDKey = @"uniqueID";


/*VSSyncDeletedObject*/

NSString *VSSyncObjectTypeKey = @"objectType";


/*VSSyncNote*/

NSString *VSSyncNoteIDKey = @"noteID";
NSString *VSSyncCreationDateKey = @"creationDate";
NSString *VSSyncTextKey = @"text";
NSString *VSSyncTextModificationDateKey = @"textModificationDate";
NSString *VSSyncArchivedKey = @"archived";
NSString *VSSyncArchivedModificationDateKey = @"archivedModificationDate";
NSString *VSSyncSortDateKey = @"sortDate";
NSString *VSSyncSortDateModificationDateKey = @"sortDateModificationDate";
NSString *VSSyncTagsModificationDateKey = @"tagsModificationDate";
NSString *VSSyncAttachmentsKey = @"attachments";
NSString *VSSyncAttachmentsModificationDateKey = @"attachmentsModificationDate";
NSString *VSSyncTagNamesKey = @"tags";

/*VSSyncTag*/

NSString *VSSyncTagIDKey = @"uniqueID";
NSString *VSSyncNameKey = @"name";
NSString *VSSyncNameModificationDateKey = @"nameModificationDate";


/*VSSyncAttachment*/

NSString *VSSyncMimeTypeKey = @"mimeType";
NSString *VSSyncHeightKey = @"height";
NSString *VSSyncWidthKey = @"width";


NSString *VSJSONArraySeparator = @"  ";


/*Accounts*/

NSString *VSAccountEmailUpdatesKey = @"emailUpdates";
NSString *VSAccountAuthenticationTokenKey = @"token";
NSString *VSDefaultsSyncUsernameKey = @"syncUsername";
NSString *VSAccountSyncExpirationDateKey = @"syncExpirationDate";
