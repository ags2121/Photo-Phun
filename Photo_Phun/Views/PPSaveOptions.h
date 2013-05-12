//
//  PPSaveOptions.h
//  Photo_Phun
//
//  Created by Alex Silva on 5/11/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPSaveOptions : UIView

- (IBAction)flickrButtonPressed:(id)sender;
- (IBAction)saveToLibraryButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *flickrBtn;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) UIImage *image;

-(void)saveImageToPhotoLibrary:(UIImage*)image;
-(void)saveImageToFlickr:(UIImage*)image;

@end
