//
//  PPAppDelegate.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/5/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPAppDelegate.h"
#import "PPFlickrSearchViewController.h"
#import "PPAlterImageViewController.h"
#import "PPShowPhotosViewController.h"

NSString *const kCompletedFirstLaunch = @"Did complete first Launch";
NSString *const kLaunchDate = @"launch date";
NSString *const kDontShowSaveAlert = @"save alert";
NSString *const kSavedPhotos = @"saved photos";
NSString *const kDateKey = @"date key";
NSString *const kImageKey = @"image key";
NSString *const kThumbnailImageKey = @"thumbnail key";

@implementation PPAppDelegate

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication withSession:self.session];
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    _smc = [[PPSideMenuController alloc] initWithMenuWidth:150 numberOfFolds:3];
    [_smc setDelegate:self];
    [self.window setRootViewController:_smc];
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                             bundle: nil];
    //create showPhotosVC
    PPShowPhotosViewController *showPhotosVC =  (PPShowPhotosViewController*)[mainStoryboard
                                                                              instantiateViewControllerWithIdentifier: @"PPShowPhotosViewController"];
    [showPhotosVC setTitle:@"Show Photos"];
     UINavigationController *showPhotosNavController = [[UINavigationController alloc] initWithRootViewController:showPhotosVC];
    
    //create getPhotosVC
    PPFlickrSearchViewController *flickrSearchVC = (PPFlickrSearchViewController*)[mainStoryboard
                                                                         instantiateViewControllerWithIdentifier: @"PPFlickrSearchViewController"];
    [flickrSearchVC setTitle:@"Get Photos"];
    UINavigationController *flickerSearchNavController = [[UINavigationController alloc] initWithRootViewController:flickrSearchVC];
    
    
    NSMutableArray *viewControllers = [@[showPhotosNavController, flickerSearchNavController] mutableCopy];
    
    [_smc setViewControllers:viewControllers];
    
    [self setAppearanceProxies];
    [self setPreferenceDefaults];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [FBAppCall handleDidBecomeActiveWithSession:self.session];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [self.session close];
}

-(void)setAppearanceProxies
{
    UIImage *navBackgroundImage = [UIImage imageNamed:@"nice_nav_bar_image"];
    [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:222.0/255.0 green:204.0/255.0 blue:155.0/255.0 alpha:1.0], UITextAttributeTextColor,
                                                           [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8],UITextAttributeTextShadowColor,
                                                           [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                           UITextAttributeTextShadowOffset, nil]];
    
    [[UIBarButtonItem appearance] setTintColor:[UIColor blackColor]];
}

- (void)setPreferenceDefaults
{
    //use NSFileManager to retrieve plist of user preferences, located in documents directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"UserDefaults.plist"];
    
    //if file doesn't exist, create it
    if( ![fileManager fileExistsAtPath: path] ){
        
        //get current date
        NSDate *launchDate = [NSDate date];
        
        //add date, first launch boolean (NO), and save alert boolean (NO) to NSDictionary
        NSDictionary *newAppDefaults = @{ kCompletedFirstLaunch : @0, kDontShowSaveAlert : @0, kLaunchDate : launchDate, kSavedPhotos : @[]};
        [newAppDefaults writeToFile:path atomically:YES];
    }
    
    //load file and use it to register user defaults
    NSDictionary *appDefaults = [[NSDictionary alloc] initWithContentsOfFile:path];
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    //NSLog(@"NSUserDefaults at launch: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
}


@end
