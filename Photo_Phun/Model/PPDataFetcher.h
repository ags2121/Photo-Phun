//
//  PPDataFetcher.h
//  Photo_Phun
//
//  Created by Alex Silva on 5/5/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTMHTTPFetcher.h"

@class FlickrPhoto;

extern NSString* const kApiKey;
extern NSString * const kCachedDate;
extern NSString* const kResultsKey;
extern int const kDaysSinceCacheUpdate;

@interface PPDataFetcher : NSObject

@property (strong, nonatomic) NSCache *resultsCache;

+ (PPDataFetcher*) sharedInstance;
+ (NSString *)flickrPhotoURLForFlickrPhoto:(FlickrPhoto *) flickrPhoto size:(NSString *) size;
-(void)beginQuery: (NSString*)queryURL;
-(void)fetchQuery:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error;
-(BOOL)cacheNeedsToBeUpdated:(NSString*)queryURL;

@end
