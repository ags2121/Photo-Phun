//
//  PPSaveOptions.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/11/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPSaveOptions.h"

@implementation PPSaveOptions

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"Frame size from inside init method: %@", NSStringFromCGRect(frame));
    }
    return self;
}

- (IBAction)flickrButtonPressed:(id)sender
{
    NSLog(@"flickerBtn pressed");
    self.flickrBtn.enabled = NO;
}

- (IBAction)saveToLibraryButtonPressed:(id)sender
{
    NSLog(@"save to library btn pressed");
    [self saveImageToPhotoLibrary:self.image];
    self.saveBtn.enabled = NO;
}

-(void)saveImageToPhotoLibrary:(UIImage*)image
{
    // Save the image to the photolibrary in the background
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = UIImagePNGRepresentation(image);
        UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:data], nil, nil, nil);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"\n>>>>> Done saving in background...");//update UI here
        });
    });
}

- (void)saveToFlickr:(UIImage*)image
{
    
}

@end
