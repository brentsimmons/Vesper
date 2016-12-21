//
//  VSTestDataImporter.m
//  Vesper
//
//  Created by Brent Simmons on 3/16/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import "VSTestDataImporter.h"


#if TESTING_DATABASE

#import "VSNote.h"
#import "VSDataController.h"
#import "RSDateParser.h"
#import "VSAttachment.h"


@interface VSTestDataImporter : NSObject

@property (nonatomic, strong, readonly) VSDataController *dataController;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@end


@implementation VSTestDataImporter


#pragma mark - Class Methods

+ (instancetype)testDataImporterWithDataController:(VSDataController *)dataController {
	
	return [[self alloc] initWithDataController:dataController];
	
}


#pragma mark - Init

- (instancetype)initWithDataController:(VSDataController *)dataController {
	
	self = [super init];
	if (self == nil)
		return nil;
	
	_dataController = dataController;
	_managedObjectContext = dataController.mainThreadContext;
	
	srandom((unsigned int)time(NULL));
	
	return self;
}



- (NSData *)imageDataForImageName:(NSString *)imageName {
	
	static NSMutableDictionary *imageDataCache = nil;
	if (imageDataCache == nil)
		imageDataCache = [NSMutableDictionary new];
	
	NSData *cachedData = imageDataCache[imageName];
	if (cachedData != nil)
		return cachedData;
	
	NSString *f = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
	
	NSData *imageData = [NSData dataWithContentsOfFile:f];
	
	imageDataCache[imageName] = imageData;
	
	return imageData;
	
}


- (UIImage *)imageForImageName:(NSString *)imageName {
	return [UIImage imageNamed:imageName];
}


- (BOOL)randomIsArchived {
	NSUInteger randomNumber = (NSUInteger)(random() % 10L);
	return randomNumber == 0;
}


- (NSString *)randomImageNameAttach {
	
	NSArray *imageNames = @[@"015flowerpink.jpg", @"049floweryellow.jpg", @"052flowerpink.jpg", @"IMG_1303.JPG", @"IMG_1410.jpg", @"IMG_1538.jpg", @"IMG_1667.JPG", @"IMG_1859.jpg", @"IMG_1900.JPG", @"IMG_1976.JPG", @"IMG_2337.JPG", @"IMG_2416.JPG", @"IMG_2433.JPG", @"IMG_2511.JPG", @"IMG_2518.jpg"];
	NSUInteger numberOfImages = [imageNames count];
	NSUInteger indexOfImage = (NSUInteger)(random() % (long)numberOfImages);
	
	NSString *imageName = imageNames[indexOfImage];
	
	return imageName;
}


- (BOOL)shouldAttachImage {
	
	static NSUInteger imagesAttached = 0;
	
	NSUInteger randomNumber = (random() % 11);
	BOOL shouldAttach = (randomNumber == 0);
	if (shouldAttach)
		imagesAttached++;
	
	return shouldAttach;
}


- (void)addAttachmentToNoteIfShouldAttachImage:(VSNote *)note {
	
	if (![self shouldAttachImage])
		return;
	
	@autoreleasepool {
		
		NSString *imageName = [self randomImageNameAttach];
		UIImage *image = [UIImage imageNamed:imageName];
		CGSize imageSize = image.size;
		
		NSString *attachmentUniqueID = [[NSUUID UUID] UUIDString];
		NSString *mimeType = saveImageAttachmentAndCreateThumbnail(image, attachmentUniqueID);
		
		(void)[VSAttachment insertAttachmentWithUniqueID:attachmentUniqueID mimeType:mimeType height:(SInt32)(imageSize.height) width:(SInt32)(imageSize.width) note:note managedObjectContext:self.managedObjectContext];
	}
}


- (void)importDFLinkedListFromFile:(NSString *)f {
	
	@autoreleasepool {
		
		NSError *fileReadingError = nil;
		NSData *fileData = [NSData dataWithContentsOfFile:f options:NSDataReadingUncached error:&fileReadingError];
		
		NSError *jsonCreationError = nil;
		id jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&jsonCreationError];
		
		NSArray *posts = (NSArray *)jsonObject;
		
		for (NSDictionary *onePost in posts) {
			@autoreleasepool {
				
				VSNote *note = [VSNote insertNote:self.managedObjectContext];
				
				note.uniqueID = [[NSUUID UUID] UUIDString];
				
				@autoreleasepool {
					NSString *body = onePost[@"Body"];
					NSString *title = onePost[@"Title"];
					body = RSStringReplaceAll(body, @"\\n>", @"\n");
					body = RSStringReplaceAll(body, @"\\n >", @"\n");
					body = RSStringReplaceAll(body, @"\\n", @"\n");
					body = RSStringReplaceAll(body, @"\n>", @"\n");
					body = RSStringReplaceAll(body, @" > ", @"");
					body = RSStringReplaceAll(body, @" >", @"");
					body = RSStringReplaceAll(body, @"> ", @"");
					body = RSStringReplaceAll(body, @"\n\n", @"\r");
					body = RSStringReplaceAll(body, @"\n", @" ");
					body = RSStringReplaceAll(body, @"\r", @"\n\n");
					body = RSStringReplaceAll(body, @"\n ", @"\n");
					body = RSStringReplaceAll(body, @"\n ", @"\n");
					body = RSStringReplaceAll(body, @"\n ", @"\n");
					
					NSString *link = onePost[@"Link"];
					if (!QSStringIsEmpty(link)) {
						if ([body rangeOfString:link options:NSCaseInsensitiveSearch].length < 1)
							body = [NSString stringWithFormat:@"%@\n\n%@", body, link];
					}
					
					NSMutableString *bodyTrimmed = [body mutableCopy];
					CFStringTrimWhitespace((__bridge CFMutableStringRef)bodyTrimmed);
					
					NSString *text = [NSString stringWithFormat:@"%@\n%@", title, bodyTrimmed];
					note.text = text;
				}
				
				static NSDateFormatter *dateFormatter = nil;
				if (dateFormatter == nil) {
					dateFormatter = [[NSDateFormatter alloc] init];
					[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"EST"]];
					[dateFormatter setDateFormat:@"MM'/'dd'/'yyyy hh':'mm':'ss a"];
				}
				
				NSDate *creationDate = [dateFormatter dateFromString:onePost[@"Date"]];
				note.creationDate = creationDate;
				note.sortDate = note.creationDate;
				
				NSMutableArray *tagNames = [NSMutableArray new];
				if (!QSIsEmpty(onePost[@"Tags"]))
					[tagNames addObjectsFromArray:onePost[@"Tags"]];
				
				static NSCalendar *calendar = nil;
				if (calendar == nil)
					calendar = [NSCalendar currentCalendar];
				NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit fromDate:note.creationDate];
				NSInteger year = dateComponents.year;
				NSString *yearTagName = [NSString stringWithFormat:@"%ld", (long)year];
				[tagNames qs_safeAddObject:yearTagName];
				
				NSMutableArray *tags = [NSMutableArray new];
				for (NSString *oneTagName in tagNames) {
					VSTag *oneTag = [self.dataController tagWithName:oneTagName];
					[tags qs_safeAddObject:oneTag];
				}
				
				note.tags = [NSOrderedSet orderedSetWithArray:tags];
				
				if (year >= 2013)
					[self addAttachmentToNoteIfShouldAttachImage:note];
				
				note.archived = [self randomIsArchived];
			}
		}
	}
}


static NSString *stringTruncatedAfterNumberOfWords:(NSString *s, NSUInteger numberOfWords) {
	
	NSArray *stringComponents = [s componentsSeparatedByString:@" "];
	if ([stringComponents count] < numberOfWords)
		return s;
	
	NSUInteger i = 0;
	NSMutableString *truncatedString = [NSMutableString stringWithString:@""];
	for (i = 0; i < numberOfWords; i++) {
		[truncatedString appendString:stringComponents[i]];
		if (i < numberOfWords - 1)
			[truncatedString appendString:@" "];
	}
	
	return [truncatedString copy];
}


- (void)importTweetsFromFile:(NSString *)f {
	
	@autoreleasepool {
		NSError *fileReadingError = nil;
		NSData *fileData = [NSData dataWithContentsOfFile:f options:NSDataReadingUncached error:&fileReadingError];
		
		NSError *jsonCreationError = nil;
		id jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&jsonCreationError];
		
		NSArray *tweets = (NSArray *)jsonObject;
		for (NSDictionary *oneTweet in tweets) {
			
			
			@autoreleasepool {
				
				VSNote *note = [VSNote insertNote:self.managedObjectContext];
				note.uniqueID = [[NSUUID UUID] UUIDString];
				
				NSString *text = oneTweet[@"text"];
				NSDictionary *entities = oneTweet[@"entities"];
				NSArray *urls = entities[@"urls"];
				
				for (NSDictionary *oneURLDictionary in urls) {
					NSString *originalURL = oneURLDictionary[@"url"];
					NSString *expandedURL = oneURLDictionary[@"expanded_url"];
					text = RSStringReplaceAll(text, originalURL, expandedURL);
				}
				
				NSRange rangeOfLineFeed = [text rangeOfString:@"\n"];
				if (rangeOfLineFeed.length == 0) {
					NSString *truncatedText = stringTruncatedAfterNumberOfWords(text, 5);
					if ([text isEqualToString:truncatedText])
						truncatedText = stringTruncatedAfterNumberOfWords(text, 3);
					if (![text isEqualToString:truncatedText]) {
						
						NSMutableString *textForReplacement = [truncatedText mutableCopy];
						CFStringTrimWhitespace((__bridge CFMutableStringRef)textForReplacement);
						[textForReplacement appendString:@"\n"];
						
						text = RSStringReplaceAll(text, truncatedText, textForReplacement);
					}
				}
				
				NSMutableArray *tags = [NSMutableArray new];
				
				NSArray *userMentions = entities[@"user_mentions"];
				for (NSDictionary *oneUserMention in userMentions) {
					
					VSTag *oneTag = [self.dataController tagWithName:oneUserMention[@"screen_name"]];
					[tags qs_safeAddObject:oneTag];
				}
				
				NSArray *hashTags = entities[@"hashtags"];
				for (NSDictionary *oneHashTag in hashTags) {
					
					VSTag *oneTag = [self.dataController tagWithName:oneHashTag[@"text"]];
					[tags qs_safeAddObject:oneTag];
				}
				
				note.creationDate = RSTwitterTimelineDateWithString(oneTweet[@"created_at"]);
				note.sortDate = note.creationDate;
				static NSCalendar *calendar = nil;
				if (calendar == nil)
					calendar = [NSCalendar currentCalendar];
				
				NSDateComponents *dateComponents = [calendar components:NSYearCalendarUnit fromDate:note.creationDate];
				NSInteger year = dateComponents.year;
				NSString *yearTagName = [NSString stringWithFormat:@"%ld", (long)year];
				VSTag *yearTag = [self.dataController tagWithName:yearTagName];
				[tags qs_safeAddObject:yearTag];
				
				note.tags = [NSOrderedSet orderedSetWithArray:tags];
				
				note.text = text;
				
				if (year >= 2013)
					[self addAttachmentToNoteIfShouldAttachImage:note];
				
			}
		}
		
	}
}

@end

void importTweets(VSDataController *dataController);
void importDaringFireball(VSDataController *dataController);


void importTweets(VSDataController *dataController) {
	
	@autoreleasepool {
		
		VSTestDataImporter *importer = [VSTestDataImporter testDataImporterWithDataController:dataController];
		NSString *folder = [[NSBundle mainBundle] pathForResource:@"tweets" ofType:nil];
		NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil];
		
		for (NSString *oneFileName in fileNames) {
			
			if (![oneFileName hasSuffix:@".js"])
				continue;
			
			NSString *f = [folder stringByAppendingPathComponent:oneFileName];
			[importer performSelectorOnMainThread:@selector(importTweetsFromFile:) withObject:f waitUntilDone:NO];
		}
	}
}


void importDaringFireball(VSDataController *dataController) {
	@autoreleasepool {
		
		VSTestDataImporter *importer = [VSTestDataImporter testDataImporterWithDataController:dataController];
		NSString *f = [[NSBundle mainBundle] pathForResource:@"df-linked-list-archive-complete" ofType:@"json"];
		
		[importer performSelectorOnMainThread:@selector(importDFLinkedListFromFile:) withObject:f waitUntilDone:NO];
	}
}


#endif
