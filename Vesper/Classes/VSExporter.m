//
//  VSExporter.m
//  Vesper
//
//  Created by Brent Simmons on 7/4/16.
//  Copyright © 2016 Q Branch LLC. All rights reserved.
//

#import "VSExporter.h"
#import "VSDataController.h"
#import "VSNote.h"
#import "VSAttachment.h"
#import "NSString+QSKit.h"


/*
 
 * Folder structure:

 Vesper Export
	Active Notes
		note.txt
		other_note.txt
		Pictures
			note.png
			other_note.png
	Archived Notes
		some_note.txt
		Pictures
			some_note.png

 Note that I’ve split it up into Active and Archived notes folders, and that each folder has its own Pictures subfolder.

 * Note file names

 The file name will derive from the note title. If the file name is not unique, it will add the note's id (a number) to the file name. If the file name is very long, it will truncate it.

 * Picture file names

 Picture file names will match the file name of the associated note, with an image suffix (.png, for example) instead.

 (This will make it easier for a human to match notes and pictures.)

 * Note text

 This is a note
 This is some more text. And more.

 Picture: this_is_a_note.png

 Tags: House, Cats, Song Lyrics

 Created: [localized date]
 Modified: [localized date]

*/


NSString *VSExportDidCompleteNotification = @"VSExportDidCompleteNotification";

static NSString *VSExportFolderName = @"Vesper Export ƒ";
static NSString *VSExportActiveNotesFolderName = @"Active Notes";
static NSString *VSExportArchivedNotesFolderName = @"Archived Notes";
static NSString *VSExportPicturesFolderName = @"Pictures";

@interface VSExporter ()

@property (nonatomic, readwrite) NSError *exportError;
@property (nonatomic) BOOL stoppedEarlyWithError;
@property (nonatomic) BOOL didPostStopNotification;
@property (nonatomic) VSDataController *dataController;
@property (nonatomic, readwrite) NSString *folder;
@property (nonatomic) NSString *activeNotesFolder;
@property (nonatomic) NSString *archivedNotesFolder;
@property (nonatomic) NSString *activePicturesFolder;
@property (nonatomic) NSString *archivedPicturesFolder;
@property (nonatomic) NSDateFormatter *dateFormatter;

@end


@implementation VSExporter


#pragma mark - Class Methods

+ (NSString *)folder:(NSString *)baseFolder byAppendingFolderName:(NSString *)folderName error:(NSError **)error {

	NSString *folder = [baseFolder stringByAppendingPathComponent:folderName];
	if (![self sureFolder:folder error:error]) {
		return nil;
	}
	return folder;

}


+ (BOOL)sureFolder:(NSString *)folder error:(NSError **)error {

	if (![[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:error]) {
		NSLog(@"sureFolder error: %@", *error);
		return NO;
	}

	return YES;
}

#pragma mark - API

- (void)exportNotesAndPictures {

	self.dateFormatter = [NSDateFormatter new];
	self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	self.dateFormatter.timeStyle = NSDateFormatterShortStyle;

	self.dataController = [VSDataController sharedController];

	NSError *error = nil;
	self.folder = [[self class] folder:QSDataFolder(nil) byAppendingFolderName:VSExportFolderName error:&error];
	if ([[NSFileManager defaultManager] fileExistsAtPath:self.folder]) {
		/*Remove old version of Vesper Export folder. Do a fresh export each time.*/
		if (![[NSFileManager defaultManager] removeItemAtPath:self.folder error:&error]) {
			[self stopWithError:error];
			return;
		}
	}
	if (!self.folder) {
		[self stopWithError:error];
		return;
	}

	self.activeNotesFolder = [[self class] folder:self.folder byAppendingFolderName:VSExportActiveNotesFolderName error:&error];
	if (!self.activeNotesFolder) {
		[self stopWithError:error];
		return;
	}

	self.archivedNotesFolder = [[self class] folder:self.folder byAppendingFolderName:VSExportArchivedNotesFolderName error:&error];
	if (!self.archivedNotesFolder) {
		[self stopWithError:error];
		return;
	}

	self.activePicturesFolder = [[self class] folder:self.activeNotesFolder byAppendingFolderName:VSExportPicturesFolderName error:&error];
	if (!self.activePicturesFolder) {
		[self stopWithError:error];
		return;
	}

	self.archivedPicturesFolder = [[self class] folder:self.archivedNotesFolder byAppendingFolderName:VSExportPicturesFolderName error:&error];
	if (!self.archivedPicturesFolder) {
		[self stopWithError:error];
		return;
	}

	dispatch_async(dispatch_get_main_queue(), ^{

		@autoreleasepool {
			[self exportActiveNotes];
			[self exportArchivedNotes];

		}
	});
}


#pragma mark - Private

- (void)stop {

	if (self.didPostStopNotification) {
		return;
	}
	self.didPostStopNotification = YES;

	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName:VSExportDidCompleteNotification object:self userInfo:nil];
	});
}


- (void)stopWithError:(NSError *)error {

	self.stoppedEarlyWithError = YES;
	self.exportError = error;
	[self stop];
}


- (void)exportActiveNotes {

	[self.dataController activeNotes:^(NSArray *notes) {

		[self exportNotes:notes folder:self.activeNotesFolder picturesFolder:self.activePicturesFolder];
	}];
}


- (void)exportArchivedNotes {

	[self.dataController archivedNotes:^(NSArray *notes) {

		[self exportNotes:notes folder:self.archivedNotesFolder picturesFolder:self.archivedPicturesFolder];
		[self stop];
	}];
}


static NSString *VSExportNoteFileExtension = @".txt";

- (void)exportNotes:(NSArray *)notes folder:(NSString *)folder picturesFolder:(NSString *)picturesFolder {

	@autoreleasepool {
		NSDictionary *notesDictionary = [self notesDictionary:notes];

		for (NSString *oneKey in notesDictionary.allKeys) {

			if (self.stoppedEarlyWithError) {
				break;
			}

			NSString *oneFilename = [oneKey stringByAppendingString:VSExportNoteFileExtension];
			[self exportNote:notesDictionary[oneKey] filename:oneFilename folder:folder picturesFolder:picturesFolder];
		}
	}
}


- (void)exportNote:(VSNote *)note filename:(NSString *)filename folder:(NSString *)folder picturesFolder:(NSString *)picturesFolder {

	@autoreleasepool {

		NSString *noteText = [self noteText:note filename:filename picturesFolder:picturesFolder];

		NSError *error = nil;
		NSString *f = [folder stringByAppendingPathComponent:filename];

		if ([noteText writeToFile:f atomically:YES encoding:NSUTF8StringEncoding error:&error]) {

			NSMutableDictionary *attributes = [NSMutableDictionary new];
			if (note.creationDate) {
				attributes[NSFileCreationDate] = note.creationDate;
			}
			if (note.mostRecentModificationDate) {
				attributes[NSFileModificationDate] = note.mostRecentModificationDate;
			}
			if (attributes.count > 0) {
				(void)[[NSFileManager defaultManager] setAttributes:attributes ofItemAtPath:f error:nil];
			}
		}

		else {
			[self stopWithError:error];
		}
	}
}

- (NSString *)noteText:(VSNote *)note filename:(NSString *)filename picturesFolder:(NSString *)picturesFolder {

	/*
	 This is a note
	 This is some more text. And more.

	 Picture: this_is_a_note.png

	 Tags: House, Cats, Song Lyrics

	 Created: [localized date]
	 Modified: [localized date]
	 */


	@autoreleasepool {

		NSMutableString *s = [note.text mutableCopy];
		if (!s) {
			s = [NSMutableString stringWithString:@""];
		}

		[self pushSectionSeparatorOnText:s];

		if (note.firstImageAttachment) {
			if ([self pushAttachment:note.firstImageAttachment noteFilename:filename picturesFolder:picturesFolder onText:s]) {
				[self pushSectionSeparatorOnText:s];
			}
		}

		[self pushTagNames:note.tagNames onText:s];
		[self pushSectionSeparatorOnText:s];

		[self pushDate:note.creationDate label:@"Created" onText:s];
		[self pushDate:note.mostRecentModificationDate label:@"Modified" onText:s];

		return [s copy];
	}
}


static NSString *VSExportPNGFileExtension = @".png";
static NSString *VSExportJPEGFileExtension = @".jpg";
static NSString *VSExportGIFFileExtension = @".gif";
static NSString *VSExportTIFFFileExtension = @".tiff";

- (BOOL)pushAttachment:(VSAttachment *)attachment noteFilename:(NSString *)noteFilename picturesFolder:(NSString *)picturesFolder onText:(NSMutableString *)s {

	NSString *filename = noteFilename;
	if ([filename hasSuffix:VSExportNoteFileExtension]) {
		// It should.
		filename = [filename substringToIndex:filename.length - VSExportNoteFileExtension.length];
	}
	
	NSString *mimeType = attachment.mimeType;
	NSString *fileExtension = nil;
	if ([mimeType isEqualToString:QSMimeTypePNG]) {
		fileExtension = VSExportPNGFileExtension;
	}
	else if ([mimeType isEqualToString:QSMimeTypeJPEG]) {
		fileExtension = VSExportJPEGFileExtension;
	}
	else if ([mimeType isEqualToString:QSMimeTypeGIF]) {
		fileExtension = VSExportGIFFileExtension;
	}
	else if ([mimeType isEqualToString:QSMimeTypeTIFF]) {
		fileExtension = VSExportTIFFFileExtension;
	}
	if (!fileExtension) {
		return NO;
	}
	filename = [filename stringByAppendingString:fileExtension];
	
	//Copy to new location in picturesFolder.
	//Push string on text.
	
	NSString *attachmentPath = attachment.path;
	if (QSStringIsEmpty(attachmentPath) || ![[NSFileManager defaultManager] fileExistsAtPath:attachmentPath]) {
		return NO;
	}
	
	NSString *destinationPath = [picturesFolder stringByAppendingPathComponent:filename];
	
	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] copyItemAtPath:attachmentPath toPath:destinationPath error:&error];
	
	if (success) {
		[s appendFormat:@"Picture: %@", filename];
	}
	
	return success;
}


- (void)pushDate:(NSDate *)date label:(NSString *)label onText:(NSMutableString *)s {

	if (!date) {
		return;
	}
	NSString *dateString = [self.dateFormatter stringFromDate:date];
	[s appendFormat:@"%@: %@\n", label, dateString];
}

- (void)pushSectionSeparatorOnText:(NSMutableString *)s {

	static NSString *VSExportNoteSectionSeparator = @"\n\n";
	[s appendString:VSExportNoteSectionSeparator];
}


- (void)pushTagNames:(NSArray *)tagNames onText:(NSMutableString *)s {

	[s appendString:@"Tags: "];

	NSUInteger ixTag = 0;
	for (NSString *oneTagName in tagNames) {

		[s appendString:oneTagName];
		if (ixTag < tagNames.count - 1) {
			[s appendString:@", "];
		}

		ixTag++;
	}
}


- (NSDictionary *)notesDictionary:(NSArray *)notes {

	/*Keys are unique file names based on note titles. Keys don’t have file extension. (Added later.)*/

	@autoreleasepool {
		NSMutableDictionary *d = [NSMutableDictionary new];

		for (VSNote *oneNote in notes) {

			NSString *oneFilename = [self filenameForNote:oneNote];
			if (d[oneFilename] != nil) {
				oneFilename = [self uniqueFilenameForNote:oneNote];
			}

			d[oneFilename] = oneNote;
		}

		return [d copy];
	}
}


- (NSString *)filenameForNote:(VSNote *)note {

	@autoreleasepool {
		NSString *title = [note.text rs_firstLine];
		if (QSStringIsEmpty(title)) {
			title = [NSString stringWithFormat:@"%lld", note.uniqueID];
		}
		title = [title qs_stringByTrimmingWhitespace];
		title = [title qs_stringWithCollapsedWhitespace];

		static NSString *space = @" ";

		NSMutableString *s = [title mutableCopy];

		static NSArray *charactersToReplace = nil;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			charactersToReplace = @[@"  ", @"\\", @"\t", @"\r", @"\n", @"\"", @"`", @"~", @"/", @":", @";", @"@", @"!", @"#", @"$", @"%", @"(", @")", @"*", @"+", @"—", @"^", @"&", @"=", @".", @",", @"?"];
		});

		for (NSString *oneCharacter in charactersToReplace) {
			[s replaceOccurrencesOfString:oneCharacter withString:@" " options:0 range:NSMakeRange(0, s.length)];
		}

		while ([s rangeOfString:@"  " options:0].location != NSNotFound) {
			[s replaceOccurrencesOfString:@"  " withString:space options:NSLiteralSearch range:NSMakeRange(0, [s length])];
		}

		[s replaceOccurrencesOfString:space withString:@"_" options:0 range:NSMakeRange(0, s.length)];

		/*Arbitrary file name length decision. Should be somewhat readable in Finder.*/

		if (s.length > 64) {
			return [s substringToIndex:64];
		}

		return s;
	}
}


- (NSString *)uniqueFilenameForNote:(VSNote *)note {

	/*When filenameForNote isn’t actually unique, add the note’s uniqueID to make sure it’s unique.*/

	NSString *s = [self filenameForNote:note];
	s = [s stringByAppendingFormat:@"-%lld", note.uniqueID];
	return s;
}


@end
