//
//  VSImagePickerController.h
//  Vesper
//
//  Created by Brent Simmons on 4/17/13.
//  Copyright (c) 2013 Q Branch LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Get a picture from the user and return it in a callback. The image will be resized down from the original image to a size suitable for syncing. The original image will also be saved to the user's camera roll.*/


@interface VSImagePickerController : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (instancetype)initWithViewController:(UIViewController *)viewController;

/*When the callback is called, it's safe to release this object. If user cancels, the callback will be called with a nil UIImage.*/

- (void)runImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType callback:(QSImageResultBlock)callback;

@end
