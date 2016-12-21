//
//  VSImagePickerController.m
//  Vesper
//
//  Created by Brent Simmons on 4/17/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "VSImagePickerController.h"
#import "VSImageUtilities.h"
#import "QSAssets.h"


@interface VSImagePickerController ()

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, copy) QSImageResultBlock imageResultCallback;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) UIImagePickerControllerCameraFlashMode flashMode;
@end


@implementation VSImagePickerController


static NSString *kDefaultsFlashModeKey = @"cameraFlashMode";


#pragma mark - Init

- (instancetype)initWithViewController:(UIViewController *)viewController {
	self = [super init];
	if (self == nil)
		return nil;
	_viewController = viewController;
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:@{kDefaultsFlashModeKey : @(UIImagePickerControllerCameraFlashModeOff)}];
	_flashMode = [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultsFlashModeKey];
	
	return self;
}


#pragma mark - Dealloc

- (void)dealloc {
	_imagePickerController.delegate = nil;
}


#pragma mark - UIImagePickerControllerDelegate

//+ (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
//	if (error != nil)
//		NSLog(@"Error saving image: %@", error);
//}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
		self.flashMode = picker.cameraFlashMode;
		[[NSUserDefaults standardUserDefaults] setInteger:picker.cameraFlashMode forKey:@"cameraFlashMode"];
	}
	
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	
	if (UTTypeConformsTo((__bridge CFStringRef)mediaType, kUTTypeImage)) {
		
		if (picker.sourceType == UIImagePickerControllerSourceTypeCamera && [info objectForKey:UIImagePickerControllerOriginalImage] != nil) {
			
			//			UIImageWriteToSavedPhotosAlbum([info objectForKey:UIImagePickerControllerOriginalImage], [self class], @selector(image:didFinishSavingWithError:contextInfo:), nil);
			
			QSSaveImageToAlbum([info objectForKey:UIImagePickerControllerOriginalImage], @"Vesper", ^(NSError *error) {
				if (error) {
					NSLog(@"Error saving image: %@", error);
				}
			});
		}
		
		[self userDidPickImage:info];
	}
	
	[self.viewController dismissViewControllerAnimated:YES completion:NULL];
	self.imageResultCallback(self.image);
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[self.viewController dismissViewControllerAnimated:YES completion:NULL];
	self.imageResultCallback(nil);
}


#pragma mark - API

- (void)runImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType callback:(QSImageResultBlock)callback {
	
	self.imageResultCallback = callback;
	self.imagePickerController = [[UIImagePickerController alloc] init];
	self.imagePickerController.delegate = self;
	self.imagePickerController.sourceType = sourceType;
	
	if (sourceType == UIImagePickerControllerSourceTypeCamera)
		self.imagePickerController.cameraFlashMode = self.flashMode;
	
	self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
	
	self.imagePickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self.viewController presentViewController:self.imagePickerController animated:YES completion:NULL];
}


#pragma mark - Image

static const CGFloat kImageResolutionMax = 1136.0f;

- (void)userDidPickImage:(NSDictionary *)imageInfo {
	
	UIImage *image = [imageInfo objectForKey:UIImagePickerControllerOriginalImage];
	if (image == nil) {
		NSLog(@"image returned from image picker is nil.");
		return;
	}
	
	self.image = VSScaleAndRotateImageToMaxResolution(image, kImageResolutionMax);
}


@end
