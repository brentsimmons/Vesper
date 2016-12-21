//
//  VSDetailViewController.m
//  Vesper
//
//  Created by Brent Simmons on 11/18/12.
//  Copyright (c) 2012 Q Branch LLC. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "VSDetailViewController.h"
#import "VSNote.h"
#import "VSDetailView.h"
#import "VSAttachment.h"
#import "VSImagePickerController.h"
#import "VSPictureViewController.h"
#import "VSTagProxy.h"
#import "VSDetailNavbarView.h"
#import "VSDetailTextView.h"
#import "VSTagDetailScrollView.h"
#import "VSTag.h"
#import "VSIconGridPopover.h"
#import "VSTagButton.h"
#import "VSTagPopover.h"
#import "VSDetailTextStorage.h"
#import "VSTagSuggestionView.h"
#import "VSActivityPopover.h"
#import "QSAssets.h"
#import "VSTypographySettings.h"
#import "VSDetailToolbar.h"
#import "VSTimelineViewController.h"
#import "UIImageView+RSExtras.h"
#import "VSSearchBarContainerView.h"
#import "VSSearchResultsViewController.h"
#import "UIPanGestureRecognizer+QSKit.h"
#import "VSDataController.h"
#import "VSDetailStatusView.h"
#import "VSAttachmentStorage.h"


@interface VSDetailViewController () <UIGestureRecognizerDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong, readwrite) VSNote *note;
@property (nonatomic, strong) VSTag *tag;
@property (nonatomic, strong) NSString *backButtonTitle;
@property (nonatomic, strong) VSImagePickerController *imagePickerController;
@property (nonatomic, strong) NSDictionary *typingAttributesForTitle;
@property (nonatomic, strong) NSDictionary *typingAttributesForText;
@property (nonatomic, strong) NSDictionary *currentTypingAttributes;
@property (nonatomic, strong) NSTimer *saveNoteTimer;
@property (nonatomic, strong, readwrite) VSDetailView *detailView;
@property (nonatomic, strong, readwrite) VSDetailTextView *textView;
@property (nonatomic, strong, readwrite) VSTagDetailScrollView *tagsScrollView;
@property (nonatomic, strong) VSTagSuggestionView *tagSuggestionView;
@property (nonatomic, strong) VSActivityPopover *activityPopover;
@property (nonatomic, strong) VSActivityPopover *cameraPopover;
@property (nonatomic, strong) UIImage *initialFullSizeImage;
@property (nonatomic, assign) BOOL readonly;
@property (nonatomic, strong) VSTagPopover *tagPopover;
@property (nonatomic, strong) VSTagButton *tagButton;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *edgePanGestureRecognizer;
@property (nonatomic, strong) UIView *snapshotView;
@property (nonatomic, assign) CGSize previousContentSize;
@property (nonatomic, strong) UIImageView *timelineNoteDragImageView;
@property (nonatomic, assign) CGRect timelineCellFrame;
@property (nonatomic, strong) UIView *tableAnimationView;
@property (nonatomic, assign) CGFloat panbackOriginX;
@property (nonatomic, strong) UIView *searchBarAnimationView;
@property (nonatomic, strong) UIView *extraBorderView;

@end


@implementation VSDetailViewController


#pragma mark Init

- (id)initWithNote:(VSNote *)note tag:(VSTag *)tag backButtonTitle:(NSString *)backButtonTitle {
	
	self = [self init];
	if (self == nil) {
		return nil;
	}
	
	_note = note;
	if (_note != nil && _note.archived) {
		_readonly = YES;
	}
	
	_tag = tag;
	_backButtonTitle = backButtonTitle;
	
	UIFont *titleFont = app_delegate.typographySettings.titleFont;//[app_delegate.theme fontForKey:@"noteTitleFont"];
	if (note.archived)
		titleFont = app_delegate.typographySettings.titleFontArchived;
	
	UIFont *textFont = app_delegate.typographySettings.bodyFont;
	if (note.archived)
		textFont = app_delegate.typographySettings.bodyFontArchived;
	
	UIColor *titleColor = [app_delegate.theme colorForKey:@"noteTitleFontColor"];
	UIColor *textColor = [app_delegate.theme colorForKey:@"noteFontColor"];
	
	CGFloat lineHeightMultiple = 1.02f;
	CGFloat titleMarginBottom = [app_delegate.theme floatForKey:@"detailNoteTitleMarginBottom"];
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	paragraphStyle.paragraphSpacing = MIN(8, titleMarginBottom);
	paragraphStyle.lineHeightMultiple = lineHeightMultiple;
	
	_typingAttributesForTitle = @{NSForegroundColorAttributeName : titleColor, NSFontAttributeName : titleFont, NSParagraphStyleAttributeName : paragraphStyle};
	
	NSMutableParagraphStyle *textParagraphyStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	textParagraphyStyle.lineHeightMultiple = lineHeightMultiple;
	_typingAttributesForText = @{NSForegroundColorAttributeName : textColor, NSFontAttributeName : textFont, NSParagraphStyleAttributeName : textParagraphyStyle};
	
	[self addObserver:self forKeyPath:@"isFocusedViewController" options:0 context:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDeleted:) name:VSNotesDeletedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidEndEditing:) name:VSTagsDidEndEditingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidChangeNoteTags:) name:VSSyncNoteTagsDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncNotesDidChange:) name:VSSyncNotesDidChangeNotification object:nil];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if (_saveNoteTimer != nil) {
		[_saveNoteTimer qs_invalidateIfValid];
		_saveNoteTimer = nil;
	}
	
	[self removeObserver:self forKeyPath:@"isFocusedViewController"];
	
	_textView.delegate = nil;
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"isFocusedViewController"] && object == self) {
		self.textView.scrollsToTop = self.isFocusedViewController;
	}
}


#pragma mark - UIViewController

- (void)loadView {
	
	NSMutableArray *tagProxies = [NSMutableArray new];
	if ([self.note.tags count] < 1) {
		if (self.tag != nil)
			[tagProxies addObject:[VSTagProxy tagProxyWithTag:self.tag]];
	}
	else
		[tagProxies addObjectsFromArray:[VSTagProxy tagProxiesWithTags:self.note.tags]];
	
	CGSize imageSize = CGSizeZero;
	VSAttachment *imageAttachment = self.note.firstImageAttachment;
	if (imageAttachment != nil)
		imageSize = imageAttachment.size;
	
	CGRect rScreenBounds = [UIScreen mainScreen].bounds;
	rScreenBounds.origin.y = 0.0f;
	
	CGRect rView = rScreenBounds;
	self.view = [[VSDetailView alloc] initWithFrame:rView backButtonTitle:self.backButtonTitle imageSize:imageSize tagProxies:tagProxies readOnly:self.readonly];
	self.detailView = (VSDetailView *)(self.view);
	
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.textView = ((VSDetailView *)(self.view)).textView;
	self.textView.readonly = self.readonly;
	self.textView.delegate = self;
	
	((VSDetailTextStorage *)self.textView.textStorage).readOnly = self.readonly;
	((VSDetailTextStorage *)self.textView.textStorage).bodyAttributes = self.typingAttributesForText;
	((VSDetailTextStorage *)self.textView.textStorage).titleAttributes = self.typingAttributesForTitle;
	
	self.tagsScrollView = self.detailView.tagsScrollView;
	self.tagsScrollView.readonly = self.readonly;
	self.tagSuggestionView = self.detailView.tagSuggestionView;
	
	if (self.initialFullSizeImage != nil) {
		[self showImage:self.initialFullSizeImage];
		self.initialFullSizeImage = nil;
	}
	else
		[self fetchImageAttachment];
	
	self.title = @"";
	
	if (self.note != nil) {
		NSString *s = self.note.text;
		if (s == nil)
			s = @"";
		s = [s qs_stringByTrimmingWhitespace];
		NSAttributedString *attString = [[NSAttributedString alloc] initWithString:s];
		self.textView.attributedText = attString;
	}
	
	else {
		[(VSDetailNavbarView *)self.navbar displayKeyboardButton]; /*Editing mode right away.*/
	}
	
	self.detailView.navbar.readonly = self.readonly;
	
	[self.view bringSubviewToFront:self.navbar];
	[self.view layoutSubviews];
	[self.view setNeedsLayout];
	
	self.edgePanGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	self.edgePanGestureRecognizer.edges = UIRectEdgeLeft;
	self.edgePanGestureRecognizer.delegate = self;
	[self.view addGestureRecognizer:self.edgePanGestureRecognizer];
	
	[self updateNavbarButtons];
	
	self.automaticallyAdjustsScrollViewInsets = NO;
	
	[self updateStatusView];
}


- (void)updateTagSuggestionViewWithText:(NSString *)text {
	
	NSArray *tagProxies = [self.tagsScrollView nonEditingTagProxies];
	
	NSMutableSet *currentTags = [NSMutableSet new];
	for (VSTagProxy *oneTagProxy in tagProxies) {
		NSString *oneTagName = oneTagProxy.name;
		if ([oneTagName length] > 0)
			[currentTags addObject:oneTagName];
	}
	
	self.tagSuggestionView.tagNamesForNote = [currentTags copy];
	self.tagSuggestionView.userTypedTag = [text copy];
}


#pragma mark - Notifications

- (void)notesDeleted:(NSNotification *)notification {
	
	/*If sync says a note was deleted, but it's currently being edited, then undelete the note.
	 That is, copy it with a new uniqueID and creationDate.*/
	
	BOOL userDidDelete = [[notification userInfo][VSUserDidDeleteKey] boolValue];
	if (userDidDelete) {
		return;
	}
	
	NSArray *uniqueIDs = [notification userInfo][VSUniqueIDsKey];
	if (![uniqueIDs containsObject:@(self.note.uniqueID)]) {
		return;
	}
	
	VSNote *note = [self.note copyWithNewUniqueIDAndCreationDate];
	//	NSLog(@"note mod %f", [note.modificationDate timeIntervalSince1970]);
	self.note = note;
	[self updateStatusView];
	
	/*Attachment *data* should already be saved. It doesn't need new uniqueIDs.*/
	
	[[VSDataController sharedController] saveNotesIncludingTagsAndAttachments:@[note]];
	[[NSNotificationCenter defaultCenter] postNotificationName:VSDidCopyNoteNotification object:self userInfo:@{VSNoteKey : note}];
}


- (void)tagsDidEndEditing:(NSNotification *)note {
	
	[self ensureNote];
	[self saveTextAndTags];
}


- (void)syncDidChangeNoteTags:(NSNotification *)notification {
	
	VSNote *note = notification.userInfo[VSNoteKey];
	if (!note || !self.note || note.uniqueID != self.note.uniqueID) {
		return;
	}
	
	/*Merge tags.*/
	
	NSArray *incomingTags = note.tags;
	if (!incomingTags) {
		incomingTags = [NSArray array];
	}
	
	NSArray *displayedTags = [self tagsForTagProxies];
	if (!displayedTags) {
		displayedTags = [NSArray array];
	}
	
	if ([incomingTags isEqualToArray:displayedTags]) {
		return;
	}
	
	NSMutableArray *tagsToAdd = [NSMutableArray new];
	for (VSTag *oneTag in displayedTags) {
		
		if (![incomingTags containsObject:oneTag]) {
			[tagsToAdd addObject:oneTag];
		}
	}
	
	if (tagsToAdd.count > 0) {
		NSMutableArray *tags = [note.tags mutableCopy];
		[tags addObjectsFromArray:tagsToAdd];
		[note userDidUpdateTags:tags];
	}
	
	[self.tagsScrollView updateWithTagProxies:[VSTagProxy tagProxiesWithTags:note.tags]];
}


- (void)syncNotesDidChange:(NSNotification *)notification {
	
	if (!self.note) {
		return;
	}
	
	NSArray *changedNotes = notification.userInfo[VSNotesKey];
	if (![changedNotes containsObject:self.note]) {
		return;
	}
	
	NSString *currentText = [self textFromTextView];
	if ([currentText isEqualToString:self.note.text]) {
		return;
	}
	
	[self.view endEditing:YES];
	[self.textView resignFirstResponder];
	
	[self.textView.textStorage replaceCharactersInRange:NSMakeRange(0, currentText.length) withString:self.note.text];
	[self.view setNeedsLayout];
}


#pragma mark - Navbar

- (VSDetailNavbarView *)navbar {
	return self.detailView.navbar;
}


- (void)updateNavbarButtons {
	
	((VSDetailNavbarView *)self.navbar).activityButton.enabled = [self hasTextOrPicture];
}


#pragma mark - Typing Attributes

- (NSDictionary *)typingAttributesAtIndex:(NSUInteger)index {
	
	if (index <= [self indexOfNewLine])
		return self.typingAttributesForTitle;
	
	return self.typingAttributesForText;
}


static BOOL typingAttributesAreEquivalent(NSDictionary *d1, NSDictionary *d2) {
	
	UIColor *color1 = d1[NSForegroundColorAttributeName];
	UIColor *color2 = d2[NSForegroundColorAttributeName];
	if (![color1 isEqual:color2])
		return NO;
	
	UIFont *font1 = d1[NSFontAttributeName];
	UIFont *font2 = d2[NSFontAttributeName];
	if (![font1 isEqual:font2])
		return NO;
	
	return YES;
}


- (void)updateTypingAttributes {
	
	NSRange selectedRange = self.textView.selectedRange;
	if (selectedRange.location == NSNotFound)
		return;
	NSDictionary *typingAttributes = [self typingAttributesAtIndex:selectedRange.location];
	NSDictionary *currentTypingAttributes = self.currentTypingAttributes;// self.textView.typingAttributes;
	
	if (!typingAttributesAreEquivalent(typingAttributes, currentTypingAttributes)) {
		self.currentTypingAttributes = typingAttributes;
		self.textView.typingAttributes = typingAttributes;
	}
}


#pragma mark - Tag Popover

- (void)cutTag:(id)sender {
	
	[self copyTag:sender];
	[self removeTag:sender];
	
}

- (void)copyTag:(id)sender {
	[UIPasteboard generalPasteboard].string = self.tagButton.title;
}


- (void)removeTag:(id)sender {
	[self.tagsScrollView deleteTagButton:self.tagButton];
	self.tagButton = nil;
}


- (void)showTagPopoverFromTagButton:(VSTagButton *)tagButton {
	
	[[NSNotificationCenter defaultCenter] postNotificationName:VSWillShowTagPopoverNotification object:self userInfo:@{VSButtonKey : tagButton}];
	
	self.tagButton = tagButton;
	
	self.tagPopover = [[VSTagPopover alloc] initWithPopoverSpecifier:@"tagPopover"];
	self.tagPopover.tagProxy = tagButton.tagProxy;
	
	self.tagPopover.arrowOnTop = NO;
	
	[self.tagPopover addItemWithTitle:NSLocalizedString(@"Copy Tag", @"Copy Tag") image:nil target:self action:@selector(copyTag:)];
	if (!self.readonly)
		[self.tagPopover addItemWithTitle:NSLocalizedString(@"Remove Tag", @"Remove Tag") image:nil target:self action:@selector(removeTag:)];
	
	CGPoint point = CGPointZero;
	point.x = CGRectGetMidX(tagButton.bounds);
	point.y = CGRectGetMinY(tagButton.bounds);
	point.y += [app_delegate.theme floatForKey:@"tagPopoverOffsetY"];
	
	point = [tagButton convertPoint:point toView:self.view];
	
	CGRect rBackground = self.view.bounds;
	rBackground.origin.y += RSNavbarPlusStatusBarHeight();
	rBackground.size.height -= RSNavbarPlusStatusBarHeight();
	
	[self.view bringSubviewToFront:self.tagPopover];
	
	[self.tagPopover showFromPoint:point inView:self.view backgroundViewRect:rBackground];
}


- (void)showOrHideTagPopoverFromTagButton:(VSTagButton *)tagButton {
	
	if (self.tagPopover.showing)
		return;
	
	[self showTagPopoverFromTagButton:tagButton];
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
	[self.detailView setNeedsLayout];
}


#pragma mark -

- (NSString *)currentText {
	return self.textView.text;
}


- (NSUInteger)indexOfNewLine {
	return [[self currentText] rs_indexOfCROrLF];
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	
	[self updateTypingAttributes];
	return YES;
}


- (void)textViewDidBeginEditing:(UITextView *)textView {
	
	;
}


- (void)textViewDidEndEditing:(UITextView *)textView {
	
	;
}


- (void)textViewDidChange:(UITextView *)textView {
	
	[self updateTypingAttributes];
	[self coalescedSaveNote];
	[self updateNavbarButtons];
}


- (void)textViewDidChangeSelection:(UITextView *)textView {
	
	[self updateTypingAttributes];
}


- (void)layoutIfContentSizeChanged {
	
	CGSize contentSize = [self.textView vs_contentSize];
	
	if (!CGSizeEqualToSize(self.previousContentSize, contentSize)) {
		[self.view setNeedsLayout];
		self.previousContentSize = contentSize;
	}
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	
	[self performSelectorOnMainThread:@selector(layoutIfContentSizeChanged) withObject:nil waitUntilDone:NO];
	
	if ([text isEqualToString:@"-"] && range.location > 0) {
		
		NSRange rangeOfPreviousCharacter = NSMakeRange(range.location - 1, 1);
		NSString *previousCharacter = [[textView.textStorage string] substringWithRange:rangeOfPreviousCharacter];
		if ([previousCharacter isEqualToString:@"-"]) {
			
			[textView.textStorage replaceCharactersInRange:rangeOfPreviousCharacter withString:@"—"];
			return NO;
		}
	}
	
	return YES;
}


#pragma mark - UIImagePicker

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
	
	self.imagePickerController = [[VSImagePickerController alloc] initWithViewController:self];
	
	VSDetailViewController __weak *weakself = self;
	
	[self.imagePickerController runImagePickerForSourceType:sourceType callback:^(UIImage *image) {
		
		if (image != nil)
			[weakself userDidPickImage:image];
		weakself.imagePickerController = nil;
	}];
}


#pragma mark - Note Saving

- (BOOL)tagNames:(NSArray *)tagNames matchesTag:(VSTag *)tag {
	
	for (NSString *oneTagName in tagNames) {
		if ([oneTagName compare:tag.name options:NSCaseInsensitiveSearch] == NSOrderedSame)
			return YES;
	}
	
	return NO;
}


static BOOL equalArrays(NSArray *array1, NSArray *array2) {
	
	if (array1 == array2)
		return YES;
	if (array1 == nil || array2 == nil)
		return NO;
	
	return [array1 isEqualToArray:array2];
}


- (BOOL)noteTagsMatchesEditedTags:(VSNote *)note {
	
	NSArray *noteTags = note.tags;
	NSArray *editedTags = [self tagsForTagProxies];
	
	return equalArrays(noteTags, editedTags);
}


- (NSArray *)tagsForTagProxies {
	
	NSMutableArray *tags = [NSMutableArray new];
	
	for (VSTagProxy *oneTagProxy in self.tagsScrollView.nonEditingTagProxies) {
		[oneTagProxy createTagIfNeeded];
		[tags qs_safeAddObject:oneTagProxy.tag];
	}
	
	return [tags copy];
}


- (void)saveTextAndTags {
	
	if (self.readonly || !self.note) {
		return;
	}
	
	[self.note userDidUpdateText:[self textFromTextView]];
	[self.note userDidUpdateTags:[self tagsForTagProxies]];
	
	[[VSDataController sharedController] saveNotes:@[self.note]];
	[[VSDataController sharedController] saveTagsForNote:self.note];
	[self updateStatusView];
}


- (void)saveNewNote:(NSString *)text {
	
	if (self.readonly) {
		return;
	}
	
	VSNote *note = [VSNote new];
	self.note = note;
	[self saveTextAndTags];
}


- (void)saveExistingNote:(NSString *)text {
	
	if (self.readonly)
		return;
	[self saveTextAndTags];
}


- (NSString *)textFromTextView {
	return [[self.textView.attributedText string] copy];
}


- (void)saveNote {
	
	if (self.readonly)
		return;
	
	[self stopSaveNoteTimer];
	
	NSString *text = [self textFromTextView];
	if (self.textView.imageView.image == nil) {
		if ([text length] < 1 || ![text rs_hasNonWhitespaceAndNewlineCharacters])
			return;
	}
	
	if (self.note == nil)
		[self saveNewNote:text];
	else
		[self saveExistingNote:text];
}


- (void)ensureNote {
	
	if (self.readonly)
		return;
	/*If there isn't a note, create it and save in database.*/
	if (self.note == nil) {
		[self saveNewNote:[self textFromTextView]];
	}
}


- (void)stopSaveNoteTimer {
	if (self.saveNoteTimer != nil)
		[self.saveNoteTimer qs_invalidateIfValid];
	self.saveNoteTimer = nil;
}


- (void)timedSaveNote:(id)sender {
	
	if (self.readonly)
		return;
	[self stopSaveNoteTimer];
	[self saveNote];
}


- (void)coalescedSaveNote {
	
	if (self.readonly)
		return;
	
	[self stopSaveNoteTimer];
	self.saveNoteTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timedSaveNote:) userInfo:nil repeats:NO];
}


- (BOOL)textViewIsEmptyOrAllWhitespace {
	NSString *text = [self textFromTextView];
	BOOL isEmptyOrAllWhiteSpace = [text length] < 1 || ![text rs_hasNonWhitespaceAndNewlineCharacters];
	return isEmptyOrAllWhiteSpace;
}


- (BOOL)shouldDeleteNote {
	
	if (self.readonly) {
		return NO;
	}
	if ([self textViewIsEmptyOrAllWhitespace] && [self.note.attachments count] < 1) {
		return YES;
	}
	
	return NO;
}

- (void)deleteNote {
	
	if (self.note == nil || self.readonly) {
		return;
	}
	
	VSNote *note = [self.note copy];
	[[VSDataController sharedController] deleteNotes:@[@(note.uniqueID)] userDidDelete:YES];
	
	[self updateNavbarButtons];
}


- (void)deleteOrSaveNote {
	
	/*If note text is empty and there's no attachment, delete it. Otherwise save it.*/
	
	if (self.readonly)
		return;
	if ([self shouldDeleteNote])
		[self deleteNote];
	else
		[self saveNote];
}


#pragma mark - Actions

- (void)editTextViewIfNotEditing:(id)sender {
	[self.textView becomeFirstResponder];
}

- (void)plusButtonTapped:(id)sender {
	
	if (self.readonly)
		return;
	
	[self stopSaveNoteTimer];
	
	[self deleteOrSaveNote];
	
	[self animateToNewNote];
}


- (void)cameraButtonTapped:(id)sender {
	
	if (self.cameraPopover.showing) {
		[self.cameraPopover dismiss:nil];
		self.cameraPopover = nil;
		return;
	}
	
	VSSendUIEventHappenedNotification();
	[self.view endEditing:YES];
	[self.textView resignFirstResponder];
	
	self.cameraPopover = [[VSActivityPopover alloc] initWithPopoverSpecifier:@"detailPopover"];
	
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		[self.cameraPopover addItemWithTitle:NSLocalizedString(@"Camera", @"Camera") image:[UIImage imageNamed:@"activity-camera"] target:self action:@selector(openCamera:)];
	}
	
	[self.cameraPopover addItemWithTitle:NSLocalizedString(@"Library", @"Library") image:[UIImage imageNamed:@"activity-library"] target:self action:@selector(openPhotoLibrary:)];
	
	[self.cameraPopover addItemWithTitle:NSLocalizedString(@"Newest", @"Newest") image:[UIImage imageNamed:@"activity-newest"] target:self action:@selector(addNewestPhoto:)];
	
	
	if (self.textView.image != nil)
		[self.cameraPopover addItemWithTitle:NSLocalizedString(@"Remove", @"Remove") image:[UIImage imageNamed:@"activity-remove"] target:self action:@selector(pictureDetailDeleteAttachment:)];
	
	[self.cameraPopover showInView:self.view fromBehindBar:self.navbar animationDirection:VSDown];
}


- (void)openPhotoLibrary:(id)sender {
	
	VSSendUIEventHappenedNotification();
	if (self.imagePickerController != nil)
		return;
	[self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}


- (void)openCamera:(id)sender {
	
	VSSendUIEventHappenedNotification();
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		[self openPhotoLibrary:sender];
		return;
	}
	
	[self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
}


- (void)addNewestPhoto:(id)sender {
	
	__weak VSDetailViewController *weakself = self;
	
	QSAssetsMostRecentPhoto(^(UIImage *image) {
		if (image != nil)
			[weakself userDidPickImage:image];
	});
}


- (void)detailViewEndEditing:(id)sender {
	[self.view endEditing:NO];
	VSSendUIEventHappenedNotification();
	self.tagSuggestionView.userTypedTag = nil;
	[self.textView resignFirstResponder];
}


- (void)detailViewDone:(id)sender {
	
	self.detailView.aboutToClose = YES;
	
	VSSendUIEventHappenedNotification();
	[self.view endEditing:YES];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self stopSaveNoteTimer];
	
	self.textView.delegate = nil;
	
	[self deleteOrSaveNote];
	
	[[self nextResponder] qs_performSelectorViaResponderChain:@selector(detailViewDone:) withObject:sender];
}


- (NSString *)currentTitle:(NSString *)text {
	if ([text length] < 1)
		return nil;
	
	return [text rs_firstLine];
}


- (NSString *)currentBody:(NSString *)text {
	
	if ([text length] < 1)
		return nil;
	
	NSString *title = [self currentTitle:text];
	if ([title length] < 1)
		return nil;
	
	NSString *s = [text qs_stringByStrippingPrefix:title caseSensitive:NO];
	s = [s qs_stringByTrimmingWhitespace];
	return s;
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	[self dismissViewControllerAnimated:YES completion:nil];
}


- (void)openMailComposer:(id)sender {
	
	if (![self hasTextToSendOrCopy] && ![self hasPictureToSendOrCopy])
		return;
	
	MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
	mailComposeViewController.mailComposeDelegate = self;
	
	NSString *text = [self textFromTextView];
	NSString *title = [self currentTitle:text];
	NSString *body = [self currentBody:text];
	if (title == nil)
		title = @"";
	if (body == nil)
		body = @"";
	
	[mailComposeViewController setSubject:title];
	[mailComposeViewController setMessageBody:body isHTML:NO];
	
	UIImage *image = self.textView.imageView.image;
	
	if (image != nil) {
		
		NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
		NSString *mimeType = QSMimeTypeJPEG;
		NSString *filename = @"ImageFromVesper.jpg";
		
		if (imageData == nil) {
			imageData = UIImagePNGRepresentation(image);
			mimeType = QSMimeTypePNG;
			filename = @"ImageFromVesper.png";
		}
		
		if (imageData != nil)
			[mailComposeViewController addAttachmentData:imageData mimeType:mimeType fileName:filename];
	}
	
	[self presentViewController:mailComposeViewController animated:YES completion:nil];
}


- (void)openSMSComposer:(id)sender {
	
	if (![self hasTextToSendOrCopy] && ![self hasPictureToSendOrCopy])
		return;
	
	MFMessageComposeViewController *textComposeViewController = [[MFMessageComposeViewController alloc] init];
	textComposeViewController.messageComposeDelegate = self;
	
	if ([self hasTextToSendOrCopy])
		textComposeViewController.body = [self textFromTextView];
	
	if ([self hasPictureToSendOrCopy]) {
		BOOL canSendSMSAttachment = [MFMessageComposeViewController canSendAttachments];
		BOOL canSendPNG = [MFMessageComposeViewController isSupportedAttachmentUTI:(NSString *)kUTTypePNG];
		BOOL canSendJPEG = [MFMessageComposeViewController isSupportedAttachmentUTI:(NSString *)kUTTypeJPEG];
		
		if (canSendSMSAttachment && (canSendJPEG || canSendPNG)) {
			
			NSData *imageData = nil;
			NSString *typeIdentifier = nil;
			NSString *filename = nil;
			UIImage *image = self.textView.imageView.image;
			
			if (canSendJPEG) {
				imageData = UIImageJPEGRepresentation(image, 1.0f);
				typeIdentifier = (NSString *)kUTTypeJPEG;
				filename = @"ImageFromVesper.jpg";
			}
			
			if (imageData == nil && canSendPNG) {
				imageData = UIImagePNGRepresentation(image);
				typeIdentifier = (NSString *)kUTTypePNG;
				filename = @"ImageFromVesper.png";
			}
			
			if (imageData != nil)
				[textComposeViewController addAttachmentData:imageData typeIdentifier:typeIdentifier filename:filename];
		}
	}
	
	[self presentViewController:textComposeViewController animated:YES completion:nil];
}


- (void)copyNote:(id)sender {
	
	NSMutableArray *pasteboardItems = [NSMutableArray new];
	
	if ([self hasTextToSendOrCopy]) {
		
		NSMutableDictionary *textItem = [NSMutableDictionary new];
		textItem[(__bridge NSString *)kUTTypePlainText] = [self textFromTextView];
		[pasteboardItems addObject:textItem];
	}
	
	if ([self hasPictureToSendOrCopy]) {
		
		NSData *imageData = UIImageJPEGRepresentation(self.textView.imageView.image, 1.0f);
		NSString *uti = (__bridge  NSString *)kUTTypeJPEG;
		if (imageData == nil) {
			imageData = UIImagePNGRepresentation(self.textView.imageView.image);
			uti = (__bridge NSString *)kUTTypePNG;
		}
		
		if (imageData != nil) {
			NSMutableDictionary *pictureItem = [NSMutableDictionary new];
			pictureItem[uti] = imageData;
			[pasteboardItems addObject:pictureItem];
		}
	}
	
	if ([pasteboardItems count] > 0) {
		[UIPasteboard generalPasteboard].items = pasteboardItems;
	}
}


- (BOOL)hasTextToSendOrCopy {
	return !QSStringIsEmpty([self textFromTextView]);
}


- (BOOL)hasPictureToSendOrCopy {
	return self.textView.imageView.image != nil;
}


- (BOOL)hasTextOrPicture {
	return [self hasTextToSendOrCopy] || [self hasPictureToSendOrCopy];
}


- (NSArray *)activityItems {
	
	NSMutableArray *items = [NSMutableArray new];
	
	[items qs_safeAddObject:[self textFromTextView]];
	[items qs_safeAddObject:self.textView.imageView.image];
	
	return [items copy];
}


- (void)detailActivityButtonTapped:(id)sender {
	
	[self.view endEditing:YES];
	[self.textView resignFirstResponder];
	
	VSSendUIEventHappenedNotification();
	
	NSArray *activityItems = [self activityItems];
	if (activityItems.count < 1) {
		return;
	}
	
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
	
	UIView *view = (UIView *)sender;
	CGRect r = view.bounds;
	r.origin.x = 0.0f;
	r.origin.y = 5.0f;
	activityViewController.popoverPresentationController.sourceView = view;
	activityViewController.popoverPresentationController.sourceRect = r;
	
	[self presentViewController:activityViewController animated:YES completion:^{
		
		;
	}];
}


- (void)pictureDetailViewDone:(VSPictureViewController *)sender {
	
	VSSendUIEventHappenedNotification();
	
	[self animateToDetailViewFromPictureView:sender];
}


- (void)pictureDetailDeleteAttachment:(id)sender {
	VSSendUIEventHappenedNotification();
	[self deleteAttachment];
}


- (void)cancelDeleteAttachment:(id)sender {
	VSSendUIEventHappenedNotification();
}


- (void)deleteNoteForcedAndReturnToTimeline:(id)sender {
	
	self.readonly = YES;
	if (self.note != nil) {
		VSNote *note = [self.note copy];
		[[VSDataController sharedController] deleteNotes:@[@(note.uniqueID)] userDidDelete:YES];
	}
	
	/*Give the action sheet time to disappear before dismissing detail view controller.*/
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		[self detailViewDone:self];
	});
}


- (void)didConfirmDeleteNote:(id)sender {
	
	[self deleteNoteForcedAndReturnToTimeline:sender];
}


- (void)cancelConfirmDeleteNote:(id)sender {
	;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex == 0) {
		[self didConfirmDeleteNote:nil];
	}
	else {
		[self cancelConfirmDeleteNote:nil];
	}
}


- (void)confirmDeleteNote:(id)sender {
	
	VSSendUIEventHappenedNotification();
	
	self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:NSLocalizedString(@"Delete Note", nil) otherButtonTitles:nil];
	
	[self.actionSheet showFromToolbar:((VSDetailView *)(self.view)).toolbar];
}


- (void)archiveNote:(id)sender {
	
	if (self.note == nil)
		return;
	
	VSTimelineNote *timelineNote = [[VSDataController sharedController] timelineNoteWithUniqueID:self.note.uniqueID];
	[self qs_performSelectorViaResponderChain:@selector(markTimelineNoteAsArchived:) withObject:timelineNote];
	
	self.readonly = YES;
	[self detailViewDone:self];
}


- (void)restoreNote:(id)sender {
	
	if (self.note == nil)
		return;
	
	VSTimelineNote *timelineNote = [[VSDataController sharedController] timelineNoteWithUniqueID:self.note.uniqueID];
	[self qs_performSelectorViaResponderChain:@selector(markTimelineNoteAsRestored:) withObject:timelineNote];
	
	self.readonly = YES;
	[self detailViewDone:self];
}


#pragma mark - Pan Back

- (void)setPanbackViewAlpha:(CGFloat)alpha {
	
	self.textView.alpha = alpha;
	self.tagsScrollView.alpha = alpha;
}


- (void)setPanbackOriginX:(CGFloat)originX {
	
	if (_panbackOriginX == originX)
		return;
	_panbackOriginX = originX;
	
	UIView *textViewBackingView = ((VSDetailView *)(self.view)).backingViewForTextView;
	CGRect rBackingView = textViewBackingView.frame;
	rBackingView.origin.x = originX;
	[textViewBackingView qs_setFrameIfNotEqual:rBackingView];
	
	UIToolbar *toolbar = ((VSDetailView *)(self.view)).toolbar;
	CGRect rToolbar = toolbar.frame;
	rToolbar.origin.x = originX;
	[toolbar qs_setFrameIfNotEqual:rToolbar];
	
	UIView *borderView = ((VSDetailView *)(self.view)).leftBorderView;
	CGRect rBorderView = borderView.frame;
	rBorderView.origin.x = originX - CGRectGetWidth(rBorderView);
	[borderView qs_setFrameIfNotEqual:rBorderView];
	
	CGRect rTagsScrollView = self.tagsScrollView.frame;
	rTagsScrollView.origin.x = originX;
	[self.tagsScrollView qs_setFrameIfNotEqual:rTagsScrollView];
	
	CGRect rExtraBorderView = self.extraBorderView.frame;
	rExtraBorderView.origin.x = originX - 0.5f;
	[self.extraBorderView qs_setFrameIfNotEqual:rExtraBorderView];
}


- (void)updatePanBackTimelineWithPercentDragged:(CGFloat)percentDragged {
	
	CGFloat timelineStartAlpha = [app_delegate.theme floatForKey:@"detailPan.timelineStartAlpha"];
	CGFloat totalAlphaChange = 1.0f - timelineStartAlpha;
	CGFloat alphaChange = totalAlphaChange * percentDragged;
	CGFloat timelineAlpha = timelineStartAlpha + alphaChange;
	self.tableAnimationView.alpha = timelineAlpha;
	self.searchBarAnimationView.alpha = timelineAlpha;
	
	CGFloat timelineStartScale = [app_delegate.theme floatForKey:@"detailPan.timelineStartScale"];
	CGFloat totalScaleChange = 1.0f - timelineStartScale;
	CGFloat scaleChange = totalScaleChange * percentDragged;
	CGFloat timelineScale = timelineStartScale + scaleChange;
	CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, timelineScale, timelineScale);
	self.tableAnimationView.transform = transform;
	self.searchBarAnimationView.transform = transform;
}


- (void)updatePanBackAnimationPositions:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	self.view.opaque = NO;
	self.view.backgroundColor = [UIColor clearColor];
	
	self.parentTimelineViewController.tableView.hidden = YES;
	
	if (![self.tableAnimationView isDescendantOfView:self.parentTimelineViewController.view]) {
		[self.parentTimelineViewController.view addSubview:self.tableAnimationView];
		
		CGRect rTableAnimationView = self.parentTimelineViewController.tableView.frame;
		[self.tableAnimationView qs_setFrameIfNotEqual:rTableAnimationView];
		
		[self.parentTimelineViewController.view bringSubviewToFront:self.timelineNoteDragImageView];
		[self.parentTimelineViewController.view bringSubviewToFront:self.view];
		[self.view bringSubviewToFront:self.navbar];
	}
	
	CGPoint translation = [panGestureRecognizer translationInView:self.textView];
	CGFloat originX = translation.x;
	if (originX < 0.0f)
		originX = 0.0f;
	CGFloat maximumDrag = CGRectGetWidth(self.view.frame);
	if (originX > maximumDrag)
		originX = maximumDrag;
	CGFloat percentDragged = originX / maximumDrag;
	
	self.panbackOriginX = originX;
	
	CGFloat alpha = 1.0f - percentDragged;
	[self setPanbackViewAlpha:alpha];
	
	((VSDetailNavbarView *)(self.navbar)).panbackPercent = percentDragged;
	
	[self updatePanBackTimelineWithPercentDragged:percentDragged];
	
	CGRect rTimelineNote = [self.parentTimelineViewController.view convertRect:self.timelineCellFrame fromView:self.parentTimelineViewController.tableView];
	[self.timelineNoteDragImageView qs_setFrameIfNotEqual:rTimelineNote];
	
}


- (void)updateTimelineDragImageForPanBackAnimation {
	
	VSTimelineNote *draggedNote = self.parentTimelineViewController.draggedNote;
	
	UIImage *timelineNoteDragImage = [self.parentTimelineViewController dragImageForNote:self.note];
	UIImageView *timelineNoteDragImageView = nil;
	
	if (timelineNoteDragImage != nil) {
		timelineNoteDragImageView = [[UIImageView alloc] initWithImage:timelineNoteDragImage];
		timelineNoteDragImageView.contentMode = UIViewContentModeTopLeft;
		timelineNoteDragImageView.opaque = NO;
		[self.parentTimelineViewController.view addSubview:timelineNoteDragImageView];
	}
	
	self.timelineNoteDragImageView = timelineNoteDragImageView;
	
	self.parentTimelineViewController.draggedNote = draggedNote;
}

- (void)animateToNormalDetailView:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		
		CGRect rView = self.view.frame;
		rView.origin.x = 0.0f;
		[self.view qs_setFrameIfNotEqual:rView];
		
		self.panbackOriginX = 0.0f;
		self.timelineNoteDragImageView.alpha = 0.0f;
		
		((VSDetailNavbarView *)(self.navbar)).panbackPercent = 0.0f;
		[self setPanbackViewAlpha:1.0f];
		
	} completion:^(BOOL finished) {
		
		[self panBackCleanup];
	}];
	
}


- (void)animateToTimelineView:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		
		self.panbackOriginX = CGRectGetWidth(self.view.frame);
		
		self.tableAnimationView.alpha = 1.0f;
		self.tableAnimationView.transform = CGAffineTransformIdentity;
		
		((VSDetailNavbarView *)(self.navbar)).panbackPercent = 1.0f;
		
		self.searchBarAnimationView.alpha = 1.0f;
		self.searchBarAnimationView.transform = CGAffineTransformIdentity;
		
		[self setPanbackViewAlpha:0.0f];
		
	} completion:^(BOOL finished) {
		
		[self panBackCleanup];
		
		[self qs_performSelectorViaResponderChain:@selector(detailViewDoneViaPanBackAnimation:) withObject:self];
		
	}];
	
}

- (void)panBackCleanup {
	
	self.parentTimelineViewController.draggedNote = nil;
	
	[self.timelineNoteDragImageView removeFromSuperview];
	self.timelineNoteDragImageView = nil;
	
	[self.tableAnimationView removeFromSuperview];
	self.tableAnimationView = nil;
	
	self.parentTimelineViewController.tableView.hidden = NO;
	
	[self.searchBarAnimationView removeFromSuperview];
	self.searchBarAnimationView = nil;
	self.parentTimelineViewController.searchBarContainerView.hidden = NO;
	
	self.view.opaque = YES;
	self.view.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	self.navbar.opaque = YES;
	self.navbar.backgroundColor = [(__kindof UIView *)[self.navbar class] backgroundColor];
	
	self.detailView.toolbar.userInteractionEnabled = YES;
	((VSDetailNavbarView *)(self.navbar)).userInteractionEnabled = YES;
	self.tagsScrollView.userInteractionEnabled = YES;
	
	((VSDetailNavbarView *)(self.navbar)).backButton.hidden = NO;
	((VSDetailNavbarView *)(self.navbar)).panbackLabel.hidden = YES;
	((VSDetailNavbarView *)(self.navbar)).panbackChevron.hidden = YES;
	self.navbar.titleField.hidden = YES;
}


- (void)panGestureEnded:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	CGFloat commitThreshold = [app_delegate.theme floatForKey:@"detailPan.commitThresholdX"];
	CGFloat commitVelocity = [app_delegate.theme floatForKey:@"detailPan.commitVelocity"];
	UIRectEdge direction = [panGestureRecognizer qs_leftOrRightDirectionInView:self.textView commitThreshold:commitThreshold commitVelocity:commitVelocity];
	
	if (direction == UIRectEdgeLeft)
		[self animateToNormalDetailView:panGestureRecognizer];
	else
		[self animateToTimelineView:panGestureRecognizer];
}


- (void)handlePanGesture:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	/*TODO: make sure everything gets saved on pan-back.*/
	
	if (self.parentSearchResultsViewController != nil) {
		[self handleSearchResultsPanGesture:panGestureRecognizer];
		return;
	}
	
	switch (panGestureRecognizer.state) {
			
		case UIGestureRecognizerStateBegan:
			
			[self ensureNote];
			[self saveTextAndTags];
			
			[self.navbar layoutSubviews];
			
			((VSDetailNavbarView *)(self.navbar)).backButton.hidden = YES;
			((VSDetailNavbarView *)(self.navbar)).panbackLabel.hidden = NO;
			((VSDetailNavbarView *)(self.navbar)).panbackChevron.hidden = NO;
			self.navbar.titleField.hidden = NO;
			
			self.detailView.toolbar.userInteractionEnabled = NO;
			((VSDetailNavbarView *)(self.navbar)).userInteractionEnabled = NO;
			self.tagsScrollView.userInteractionEnabled = NO;
			
			[self.textView resignFirstResponder];
			self.timelineCellFrame = [self.parentTimelineViewController frameOfCellForNote:self.note];
			
			[self updateTimelineDragImageForPanBackAnimation];
			[self.parentTimelineViewController prepareForPanBackAnimationWithNote:self.note];
			self.tableAnimationView = [self.parentTimelineViewController tableAnimationView:YES];
			
			self.searchBarAnimationView = (UIView *)[UIImageView rs_imageViewWithSnapshotOfView:self.parentTimelineViewController.searchBarContainerView clearBackground:YES];
			[self.parentTimelineViewController.view insertSubview:self.searchBarAnimationView belowSubview:self.parentTimelineViewController.navbar];
			CGRect rSearchBar = self.parentTimelineViewController.searchBarContainerView.frame;
			rSearchBar = [self.parentTimelineViewController.view convertRect:rSearchBar fromView:self.parentTimelineViewController.searchBarContainerView.superview];
			
			self.searchBarAnimationView.frame = rSearchBar;
			self.parentTimelineViewController.searchBarContainerView.hidden = YES;
			
			[self updatePanBackAnimationPositions:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateChanged:
			[self updatePanBackAnimationPositions:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateEnded:
			[self panGestureEnded:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateFailed:
		case UIGestureRecognizerStateCancelled:
			[self animateToNormalDetailView:panGestureRecognizer];
			break;
			
		default:
			break;
	}
}


#pragma mark - Pan Back - Search Results

- (void)updateSearchResultsPanBackAnimationPositions:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	self.view.opaque = NO;
	self.view.backgroundColor = [UIColor clearColor];
	
	self.parentSearchResultsViewController.tableView.hidden = YES;
	
	if (![self.tableAnimationView isDescendantOfView:self.parentTimelineViewController.view]) {
		[self.parentTimelineViewController.view addSubview:self.tableAnimationView];
		[self.parentTimelineViewController.view addSubview:self.timelineNoteDragImageView];
		
		CGRect rTableAnimationView = [UIScreen mainScreen].bounds;
		[self.tableAnimationView qs_setFrameIfNotEqual:rTableAnimationView];
		
		[self.parentTimelineViewController.view bringSubviewToFront:self.timelineNoteDragImageView];
		[self.parentTimelineViewController.view bringSubviewToFront:self.view];
		[self.view bringSubviewToFront:self.navbar];
	}
	
	CGPoint translation = [panGestureRecognizer translationInView:self.textView];
	CGFloat originX = translation.x;
	if (originX < 0.0f)
		originX = 0.0f;
	CGFloat maximumDrag = CGRectGetWidth(self.view.frame);
	if (originX > maximumDrag)
		originX = maximumDrag;
	CGFloat percentDragged = originX / maximumDrag;
	
	self.panbackOriginX = originX;
	
	CGFloat alpha = 1.0f - percentDragged;
	[self setPanbackViewAlpha:alpha];
	
	CGFloat navbarDistance = CGRectGetHeight(self.navbar.frame);
	CGFloat navbarChange = navbarDistance * percentDragged;
	CGRect rNavbar = self.navbar.frame;
	rNavbar.origin.y = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) - VSNormalStatusBarHeight();
	rNavbar.origin.y -= navbarChange;
	[self.navbar qs_setFrameIfNotEqual:rNavbar];
	
	[self updatePanBackTimelineWithPercentDragged:percentDragged];
	
	CGRect rTimelineNote = [self.parentSearchResultsViewController.tableView convertRect:self.timelineCellFrame toView:self.parentTimelineViewController.view];
	[self.timelineNoteDragImageView qs_setFrameIfNotEqual:rTimelineNote];
}


- (void)updateSearchResultsTimelineDragImageForPanBackAnimation {
	
	VSTimelineNote *draggedNote = self.parentSearchResultsViewController.draggedNote;
	if (draggedNote != nil) {
		self.parentSearchResultsViewController.draggedNote = nil;
		[self.parentSearchResultsViewController.tableView reloadData];
	}
	
	UIImage *timelineNoteDragImage = [self.parentSearchResultsViewController dragImageForNote:self.note];
	UIImageView *timelineNoteDragImageView = nil;
	
	if (timelineNoteDragImage != nil) {
		timelineNoteDragImageView = [[UIImageView alloc] initWithImage:timelineNoteDragImage];
		timelineNoteDragImageView.contentMode = UIViewContentModeTopLeft;
		timelineNoteDragImageView.opaque = NO;
		[self.parentSearchResultsViewController.view addSubview:timelineNoteDragImageView];
	}
	
	self.timelineNoteDragImageView = timelineNoteDragImageView;
	
	self.parentSearchResultsViewController.draggedNote = draggedNote;
}


- (void)searchResultsAnimateToNormalDetailView:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		
		CGRect rView = self.view.frame;
		rView.origin.x = 0.0f;
		[self.view qs_setFrameIfNotEqual:rView];
		[self.view setNeedsLayout];
		[self.view layoutIfNeeded];
		
		self.panbackOriginX = 0.0f;
		self.timelineNoteDragImageView.alpha = 0.0f;
		[self setPanbackViewAlpha:1.0f];
		
	} completion:^(BOOL finished) {
		
		[self searchResultsPanBackCleanup];
	}];
	
}


- (void)searchResultsAnimateToTimelineView:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		
		self.panbackOriginX = CGRectGetWidth(self.view.frame);
		
		[self setPanbackViewAlpha:0.0f];
		
		self.tableAnimationView.alpha = 1.0f;
		self.tableAnimationView.transform = CGAffineTransformIdentity;
		
		CGRect rNavbar = self.navbar.frame;
		rNavbar.origin.y = -(CGRectGetHeight(rNavbar));
		[self.navbar qs_setFrameIfNotEqual:rNavbar];
		
		self.searchBarAnimationView.alpha = 1.0f;
		self.searchBarAnimationView.transform = CGAffineTransformIdentity;
		
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
	} completion:^(BOOL finished) {
		
		[self searchResultsPanBackCleanup];
		[self qs_performSelectorViaResponderChain:@selector(detailViewDoneViaPanBackAnimation:) withObject:self];
		
	}];
	
}


- (void)searchResultsPanGestureEnded:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	CGFloat commitThreshold = [app_delegate.theme floatForKey:@"detailPan.commitThresholdX"];
	CGFloat commitVelocity = [app_delegate.theme floatForKey:@"detailPan.commitVelocity"];
	UIRectEdge direction = [panGestureRecognizer qs_leftOrRightDirectionInView:self.textView commitThreshold:commitThreshold commitVelocity:commitVelocity];
	
	if (direction == UIRectEdgeLeft)
		[self searchResultsAnimateToNormalDetailView:panGestureRecognizer];
	else
		[self searchResultsAnimateToTimelineView:panGestureRecognizer];
}


- (void)searchResultsPanBackCleanup {
	
	[self.timelineNoteDragImageView removeFromSuperview];
	self.timelineNoteDragImageView = nil;
	self.parentSearchResultsViewController.draggedNote = nil;
	
	[self.tableAnimationView removeFromSuperview];
	self.tableAnimationView = nil;
	
	self.parentSearchResultsViewController.tableView.hidden = NO;
	
	[self.searchBarAnimationView removeFromSuperview];
	self.searchBarAnimationView = nil;
	self.parentTimelineViewController.searchBarContainerView.hidden = NO;
	
	self.view.opaque = YES;
	self.view.backgroundColor = [app_delegate.theme colorForKey:@"notesBackgroundColor"];
	
	[self.extraBorderView removeFromSuperview];
	self.extraBorderView = nil;
	
	self.detailView.toolbar.userInteractionEnabled = YES;
	((VSDetailNavbarView *)(self.navbar)).userInteractionEnabled = YES;
	self.tagsScrollView.userInteractionEnabled = YES;
}


- (void)handleSearchResultsPanGesture:(UIScreenEdgePanGestureRecognizer *)panGestureRecognizer {
	
	switch (panGestureRecognizer.state) {
			
		case UIGestureRecognizerStateBegan: {
			
			self.detailView.toolbar.userInteractionEnabled = NO;
			((VSDetailNavbarView *)(self.navbar)).userInteractionEnabled = NO;
			self.tagsScrollView.userInteractionEnabled = NO;
			
			[self.textView resignFirstResponder];
			self.timelineCellFrame = [self.parentSearchResultsViewController frameOfCellForNote:self.note];
			
			self.parentSearchResultsViewController.draggedNote = [VSTimelineNote timelineNoteWithNote:self.note];
			self.tableAnimationView = [self.parentSearchResultsViewController tableAnimationView];
			self.parentSearchResultsViewController.draggedNote = nil;
			[self.parentSearchResultsViewController.tableView reloadData];
			
			[self updateSearchResultsTimelineDragImageForPanBackAnimation];
			
			self.searchBarAnimationView = (UIView *)[UIImageView rs_imageViewWithSnapshotOfView:self.parentTimelineViewController.searchBarContainerView clearBackground:YES];
			[self.parentTimelineViewController.view insertSubview:self.searchBarAnimationView belowSubview:self.view];
			CGRect rSearchBar = self.parentTimelineViewController.searchBarContainerView.frame;
			rSearchBar = [self.parentTimelineViewController.view convertRect:rSearchBar fromView:self.parentTimelineViewController.searchBarContainerView.superview];
			
			self.searchBarAnimationView.frame = rSearchBar;
			self.parentTimelineViewController.searchBarContainerView.hidden = YES;
			
			CGRect rExtraBorderView = RSNavbarRect();
			CGFloat borderWidth = [app_delegate.theme floatForKey:@"detailPan.detailBorderWidth"];
			rExtraBorderView.origin.x -= borderWidth;
			rExtraBorderView.size.width += borderWidth;
			self.extraBorderView = [[UIView alloc] initWithFrame:rExtraBorderView];
			self.extraBorderView.opaque = YES;
			self.extraBorderView.backgroundColor = self.detailView.backgroundColor;
			
			CGRect rBorderView = rExtraBorderView;
			rBorderView.origin.x = 0.0f;
			rBorderView.origin.y = 0.0f;
			rBorderView.size.width = borderWidth;
			UIColor *borderColor = [app_delegate.theme colorForKey:@"detailPan.detailBorderColor"];
			borderColor = [borderColor colorWithAlphaComponent:[app_delegate.theme floatForKey:@"detailPan.detailBorderColorAlpha"]];
			UIView *borderView = [[UIView alloc] initWithFrame:rBorderView];
			borderView.backgroundColor = borderColor;
			borderView.opaque = NO;
			[self.extraBorderView addSubview:borderView];
			
			[self.parentTimelineViewController.view insertSubview:self.extraBorderView belowSubview:self.view];
			
			[self updateSearchResultsPanBackAnimationPositions:panGestureRecognizer];
			[self.parentSearchResultsViewController.tableView reloadData];
		}
			
			break;
			
		case UIGestureRecognizerStateChanged:
			[self updateSearchResultsPanBackAnimationPositions:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateEnded:
			[self searchResultsPanGestureEnded:panGestureRecognizer];
			break;
			
		case UIGestureRecognizerStateFailed:
		case UIGestureRecognizerStateCancelled:
			[self searchResultsAnimateToNormalDetailView:panGestureRecognizer];
			break;
			
		default:
			break;
	}
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	
	if (gestureRecognizer != self.edgePanGestureRecognizer)
		return NO;
	
	CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer translationInView:self.textView];
	if (fabs(translation.y) > fabs(translation.x))
		return NO;
	
	CGPoint point = [gestureRecognizer locationInView:self.detailView];
	if (CGRectContainsPoint(self.detailView.toolbar.frame, point))
		return NO;
	if (CGRectContainsPoint(self.navbar.frame, point))
		return NO;
	
	return YES;
}


#pragma mark - Animation - Detail to Picture

- (void)animateToPictureView:(UIImage *)image {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	UIImageView *animatingImageView = [[UIImageView alloc] initWithImage:image];
	animatingImageView.contentMode = UIViewContentModeScaleAspectFill;
	animatingImageView.clipsToBounds = YES;
	
	CGRect rImageView = self.textView.imageView.frame;
	rImageView = [self.view convertRect:rImageView fromView:self.textView];
	animatingImageView.frame = rImageView;
	
	[animatingImageView setNeedsDisplay];
	
	self.textView.imageView.alpha = 0.0f;
	
	VSPictureViewController *pictureViewController = [[VSPictureViewController alloc] initWithImage:image];
	pictureViewController.readonly = self.readonly;
	[self pushViewController:pictureViewController];
	[self postFocusedViewControllerDidChangeNotification:pictureViewController];
	(void)pictureViewController.view;
	pictureViewController.scrollView.alpha = 0.0f;
	pictureViewController.scrollView.imageView.alpha = 0.0f;
	[pictureViewController.navbar setAlphaForSubviews:0.0f];
	pictureViewController.navbar.alpha = 0.0f;
	
	[self.view addSubview:animatingImageView];
	[self.view bringSubviewToFront:animatingImageView];
	[self.view bringSubviewToFront:self.navbar];
	
	[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		[[NSNotificationCenter defaultCenter] postNotificationName:VSAppShouldHideStatusBarNotification object:self];
		
		//        animatingImageView.contentMode = UIViewContentModeScaleAspectFit;
		CGRect rImageViewDest = self.view.bounds;
		CGSize imageSize = QSScaledSizeForImageFittingSize(image.size, self.view.bounds.size);
		rImageViewDest.size = imageSize;
		rImageViewDest.origin.y = CGRectGetMidY(self.view.bounds) - (rImageViewDest.size.height / 2.0f);
		rImageViewDest.origin.x = (self.view.bounds.size.width - rImageViewDest.size.width) / 2.0f;
		
		animatingImageView.frame = rImageViewDest;
		pictureViewController.scrollView.alpha = 1.0f;
		[self.navbar setAlphaForSubviews:0.0f];
		self.navbar.alpha = 0.0f;
		
	} completion:^(BOOL finished) {
		
		pictureViewController.scrollView.imageView.alpha = 1.0f;
		pictureViewController.navbar.alpha = 1.0f;
		[self.view insertSubview:self.navbar belowSubview:pictureViewController.view];
		
		[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
			
			[pictureViewController.navbar setAlphaForSubviews:1.0f];
			;//pictureViewController.scrollView.alpha = 1.0f;
			
		} completion:^(BOOL finished2) {
			
			self.textView.imageView.alpha = 1.0f;
			[animatingImageView removeFromSuperview];
			[self.navbar setAlphaForSubviews:1.0f];
			self.navbar.alpha = 1.0f;
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		}];
	}];
	
}


#pragma mark - Animation - Picture to Detail

- (void)animateToDetailViewFromPictureView:(VSPictureViewController *)pictureViewController {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	pictureViewController.scrollView.closing = YES;
	
	UIImageView *imageView = pictureViewController.scrollView.imageView;
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	imageView.autoresizingMask = UIViewAutoresizingNone;
	[imageView removeFromSuperview];
	[self.view addSubview:imageView];
	CGRect r = imageView.frame;
	r = [pictureViewController.scrollView convertRect:r toView:self.view];
	imageView.clipsToBounds = YES;
	
	[imageView qs_setFrameIfNotEqual:r];
	
	self.textView.imageView.alpha = 0.0f;
	self.navbar.alpha = 0.0f;
	[self.view bringSubviewToFront:self.navbar];
	
	[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		
		[[NSNotificationCenter defaultCenter] postNotificationName:VSAppShouldShowStatusBarNotification object:self];
		pictureViewController.view.alpha = 0.0f;
		CGRect rImage = self.textView.imageView.frame;
		rImage = [self.textView convertRect:rImage toView:self.view];
		imageView.frame = rImage;
		self.navbar.alpha = 1.0f;
		//        imageView.alpha = 0.0f;
		
	} completion:^(BOOL finished) {
		
		self.textView.imageView.alpha = 1.0f;
		[imageView removeFromSuperview];
		[self popViewController:pictureViewController];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		[self postFocusedViewControllerDidChangeNotification:self];
		
	}];
}


#pragma mark - Animation - New Note

- (UIImage *)textViewSnapshot {
	
	UIGraphicsBeginImageContextWithOptions(self.textView.frame.size, NO, [UIScreen mainScreen].scale);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0, -(self.textView.contentOffset.y));
	
	UIColor *backgroundColor = self.textView.backgroundColor;
	self.textView.backgroundColor = [UIColor clearColor];
	[self.textView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self.textView.backgroundColor = backgroundColor;
	
	return image;
}


- (UIView *)textViewSnapshotViewForPanGesture {
	
	CGFloat textViewHeight = [self.textView vs_contentSize].height;
	textViewHeight += (self.textView.contentInset.top + self.textView.contentInset.bottom);
	
	CGSize size = self.textView.frame.size;
	size.height = MIN(textViewHeight, self.textView.frame.size.height);
	UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0, -(self.textView.contentOffset.y));
	
	UIColor *backgroundColor = self.textView.backgroundColor;
	self.textView.backgroundColor = [UIColor clearColor];
	[self.textView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	self.textView.backgroundColor = backgroundColor;
	
	return [[UIImageView alloc] initWithImage:image];
}


- (void)doNewNoteAnimations {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	UIImage *textViewImageOld = [self textViewSnapshot];
	
	UIImageView *imageView = [[UIImageView alloc] initWithImage:textViewImageOld];
	[self.view addSubview:imageView];
	CGRect rImage = self.textView.frame;
	rImage.origin.y = RSNavbarPlusStatusBarHeight();
	imageView.frame = rImage;
	
	self.note = nil;
	NSAttributedString *attString = [[NSAttributedString alloc] initWithString:@""];
	self.textView.attributedText = attString;
	
	
	UIImageView *userImageView = nil;
	if (self.textView.imageView.image != nil) {
		userImageView = [[UIImageView alloc] initWithImage:self.textView.imageView.image];
		userImageView.contentMode = self.textView.imageView.contentMode;
		[self.view addSubview:userImageView];
		userImageView.clipsToBounds = YES;
		
		CGRect rImageView = [self.textView convertRect:self.textView.imageView.frame toView:self.view];
		rImageView.size.width = self.view.bounds.size.width;
		rImageView.origin.x = 0.0f;
		userImageView.frame = rImageView;
		self.textView.imageView.alpha = 0.0f;
	}
	
	[self.view bringSubviewToFront:userImageView];
	
	[UIView animateWithDuration:0.25f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.detailView.image = nil;
		[self.textView layoutSubviews];
		imageView.alpha = 0.0f;
		//        self.tagsScrollView.alpha = 1.0f;
		userImageView.alpha = 0.0f;
		[self.textView becomeFirstResponder];
		
	} completion:^(BOOL finished) {
		
		self.textView.imageView.alpha = 1.0f;
		[imageView removeFromSuperview];
		[userImageView removeFromSuperview];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		[self updateTypingAttributes];
		[self updateNavbarButtons];
	}];
}


- (void)dismissPopoverThenRunNewNoteAnimation:(id)popover {
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[popover dismiss:^(id dismissedPopover) {
		[self doNewNoteAnimations];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
}


- (void)animateToNewNote {
	
	if (self.tagPopover.showing)
		[self dismissPopoverThenRunNewNoteAnimation:self.tagPopover];
	
	else if (self.cameraPopover.showing)
		[self dismissPopoverThenRunNewNoteAnimation:self.cameraPopover];
	
	else
		[self doNewNoteAnimations];
}


#pragma mark - Attachments

- (void)setInitialFullSizeImage:(UIImage *)image {
	_initialFullSizeImage = image;
	if (_initialFullSizeImage != nil && [self isViewLoaded])
		[self showImage:_initialFullSizeImage];
}


- (void)userDidPickImage:(UIImage *)image {
	
	if (image == nil) {
		return;
	}
	
	[self showImage:image];
	
	[self ensureNote];
	[self.note userDidReplaceAllAttachmentsWithImage:image];
	
	[self saveTextAndTags];
	[self updateNavbarButtons];
}


- (void)deleteAttachment {
	
	if (self.readonly || self.note == nil)
		return;
	
	[self showImage:nil];
	
	[self.note userDidRemoveAllAttachments];
	[self saveTextAndTags];
	
	[self updateNavbarButtons];
}


- (void)imageViewTapped:(id)sender {
	
	[self detailViewEndEditing:sender];
	
	UIImage *image = self.textView.imageView.image;
	if (image == nil)
		return;
	
	[self animateToPictureView:image];
}


- (void)fetchImageAttachment {
	
	NSString *attachmentID = self.note.firstImageAttachment.uniqueID;
	if (attachmentID == nil) {
		return;
	}
	
	VSDetailViewController __weak *weakself = self;
	
	[[VSAttachmentStorage sharedStorage] fetchBestImageAttachment:attachmentID callback:^(UIImage *image) {
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (![attachmentID isEqualToString:weakself.note.firstImageAttachment.uniqueID]) {
				return;
			}
			[self showImage:image];
		});
	}];
	
	[self updateNavbarButtons];
}


- (void)showImage:(UIImage *)image {
	self.detailView.image = image;
	[self updateNavbarButtons];
}


#pragma mark - Editing

- (BOOL)editing {
	return self.detailView.keyboardShowing;
}


#pragma mark - Status View

- (void)updateStatusView {
	
	NSString *s = [self textFromTextView];
	if (!s) {
		s = @"";
	}
	
	VSDetailStatusView *statusView = ((VSDetailView *)(self.view)).toolbar.statusView;
	
	statusView.characterCount = [s length];
	
	__block NSUInteger wordCount = 0;
	[s enumerateSubstringsInRange:NSMakeRange(0, s.length) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
		
		wordCount++;
	}];
	
	statusView.wordCount = wordCount;
	
	if (self.note) {
		
		statusView.creationDate = self.note.creationDate;
		statusView.modificationDate = self.note.mostRecentModificationDate;
	}
	else {
		
		statusView.creationDate = nil;
		statusView.modificationDate = nil;
	}
}


@end



