//
//  RSKeychain.m
//  Vesper
//
//  Created by Brent Simmons on 5/6/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


#import "VSKeychain.h"
#if TARGET_OS_IPHONE
#import "SFHFKeychainUtils.h"
#endif


static NSString *VSServiceName = @"Vesper";


#pragma mark - iOS

#if TARGET_OS_IPHONE

BOOL VSKeychainGetPassword(NSString *username, NSString **password, NSError **error) {

 	*password = [SFHFKeychainUtils getPasswordForUsername:username andServiceName:VSServiceName error:error];

	return *error == nil;
}


BOOL VSKeychainSetPassword(NSString *username, NSString *password, NSError **error) {

	return [SFHFKeychainUtils storeUsername:username andPassword:password forServiceName:VSServiceName updateExisting:YES error:error];
}


BOOL VSKeychainDeletePassword(NSString *username, NSError **error) {

	return [SFHFKeychainUtils deleteItemForUsername:username andServiceName:VSServiceName error:error];
}



#else

#pragma mark - Mac

@interface Keychain : NSObject

+ (NSString *)fetchPasswordFromKeychain;
+ (void)storePasswordInKeychain:(NSString *)password;

@end

BOOL VSKeychainGetPassword(NSString *username, NSString **password, NSError **error) {

	*password = [Keychain fetchPasswordFromKeychain];
	return YES;
}


BOOL VSKeychainSetPassword(NSString *username, NSString *password, NSError **error) {

	[Keychain storePasswordInKeychain:password];
	return YES;
}


BOOL VSKeychainDeletePassword(NSString *username, NSError **error) {

	[Keychain storePasswordInKeychain:@""];
	return YES;
}



@implementation Keychain


+ (NSString *)fetchPasswordFromKeychain {

	SecKeychainItemRef keychainItem = NULL;
	const char *serviceName = VSServiceName.UTF8String;
	char *passwordData = NULL;
	UInt32 passwordLength = 0;

	OSStatus err = SecKeychainFindGenericPassword (nil, (UInt32)strlen(serviceName), serviceName, 0, nil, &passwordLength, (void **)&passwordData, &keychainItem);

	NSString *password = nil;
	if (err == noErr && passwordData && passwordLength > 0) {
		password = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
	}

	if (passwordData) {
		SecKeychainItemFreeContent(nil, passwordData);
	}
	if (keychainItem) {
		CFRelease(keychainItem);
	}

	return password;
}


+ (void)storePasswordInKeychain:(NSString *)password {

	if (!password) {
		return;
	}

	UInt32 passwordLength = 0;
	char *passwordData = nil;
	SecKeychainItemRef keychainItem = NULL;
	const char *serviceName = VSServiceName.UTF8String;

	SecKeychainFindGenericPassword (nil, (UInt32)strlen(serviceName), serviceName, 0, nil, &passwordLength, (void**)&passwordData, &keychainItem);

	if (!keychainItem) {
		SecKeychainAddGenericPassword (nil, (UInt32)strlen(serviceName), serviceName, 0, nil, (UInt32)strlen(password.UTF8String), password.UTF8String, nil);
	}

	else {
		BOOL update = YES;
		if (passwordLength > 0 && passwordData) {
			NSString *foundPassword = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
			if ([password isEqualToString:foundPassword])
				update = NO;
		}
		if (update) {
			SecKeychainItemModifyContent(keychainItem, nil, (UInt32)strlen(password.UTF8String), password.UTF8String);
		}
	}


	if (passwordData) {
		SecKeychainItemFreeContent(nil, passwordData);
	}
	if (keychainItem) {
		CFRelease(keychainItem);
	}
}

@end

#endif
