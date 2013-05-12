//
//  PPSaveOptions.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/11/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPAppDelegate.h"
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
    if (FBSession.activeSession.isOpen) {
        
        // Yes, we are open, so lets make a request for user details so we can get the user name.
        [self promptUserWithAccountNameForUploadPhoto];
        
    } else {
        
        // We don't have an active session in this app, so lets open a new
        // facebook session with the appropriate permissions!
        
        // Firstly, construct a permission array.
        // you can find more "permissions strings" at http://developers.facebook.com/docs/authentication/permissions/
        // In this example, we will just request a publish_stream which is required to publish status or photos.
        
        NSArray *permissions = [[NSArray alloc] initWithObjects:
                                @"publish_stream",
                                nil];
        // OPEN Session!
        
        [FBSession openActiveSessionWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
                  // if login fails for any reason, we alert
            if (error) {
              
              // show error to user.
              
            }
            else if (FB_ISSESSIONOPENWITHSTATE(status)) {
              
              // no error, so we proceed with requesting user details of current facebook session.
              
              [self promptUserWithAccountNameForUploadPhoto];
            }
            }];
    }
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

- (void)saveImageToFacebook:(UIImage*)image
{

}

-(void)promptUserWithAccountNameForUploadPhoto {

    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         if (!error) {
             
             UIAlertView *tmp = [[UIAlertView alloc]
                                 initWithTitle:@"Upload to FB?"
                                 message:[NSString stringWithFormat:@"Upload to ""%@"" Account?", user.name]
                                 delegate:self
                                 cancelButtonTitle:nil
                                 otherButtonTitles:@"No",@"Yes", nil];
             tmp.tag = 100; // to upload
             [tmp show];
             
         }

     }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex==1) { // yes answer
        
        // did the alert responded to is the one prompting about user name? if so, upload!
        if (alertView.tag==100) {
            // then upload
            
            // Here is where the UPLOADING HAPPENS!
            [FBRequestConnection startForUploadPhoto:self.image completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
               if (!error) {
                   UIAlertView *tmp = [[UIAlertView alloc]
                                       initWithTitle:@"Success"
                                       message:@"Photo Uploaded"
                                       delegate:self
                                       cancelButtonTitle:nil
                                       otherButtonTitles:@"Ok", nil];
                   
                   [tmp show];

               } else {
                   UIAlertView *tmp = [[UIAlertView alloc]
                                       initWithTitle:@"Error"
                                       message:@"Some error happened"
                                       delegate:self
                                       cancelButtonTitle:nil
                                       otherButtonTitles:@"Ok", nil];
                   
                   [tmp show];

               }
               

           }];
            
        }
        
    }
    
}




@end
