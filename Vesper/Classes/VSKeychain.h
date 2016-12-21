//
//  RSKeychain.h
//  Vesper
//
//  Created by Brent Simmons on 5/6/14.
//  Copyright (c) 2014 Q Branch LLC. All rights reserved.
//


BOOL VSKeychainGetPassword(NSString *username, NSString **password, NSError **error);
BOOL VSKeychainSetPassword(NSString *username, NSString *password, NSError **error);
BOOL VSKeychainDeletePassword(NSString *username, NSError **error);


