//
//  PPAppDelegate.h
//  Photo_Phun
//
//  Created by Alex Silva on 5/5/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPSideMenuController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface PPAppDelegate : UIResponder <UIApplicationDelegate, PaperFoldMenuControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) PPSideMenuController *smc;
@property (strong, nonatomic) FBSession *session;

@end
