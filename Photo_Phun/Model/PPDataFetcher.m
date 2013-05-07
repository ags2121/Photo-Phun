//
//  PPDataFetcher.m
//  Photo_Phun
//
//  Created by Alex Silva on 5/5/13.
//  Copyright (c) 2013 Alex Silva. All rights reserved.
//

#import "PPDataFetcher.h"
#import "FlickrPhoto.h"

//CONSTANTS
NSString* const kApiKey = @"c0bf885cdfc604151c11e481f9f1b897";
NSString* const kCachedDate = @"cachedDate";
NSString* const kResultsKey = @"results key";
int const kDaysSinceCacheUpdate = 3;

@interface PPDataFetcher ()

@property (strong, nonatomic) NSString *currentSearchTerm;

@end

@implementation PPDataFetcher

+ (PPDataFetcher*) sharedInstance {
    
    static dispatch_once_t _p;
    
    __strong static id _singleton = nil;
    
    dispatch_once(&_p, ^{
        _singleton = [[self alloc] init];
    });
    
    return _singleton;
}

+ (NSString *)flickrPhotoURLForFlickrPhoto:(FlickrPhoto *) flickrPhoto size:(NSString *) size
{
    if(!size)
    {
        size = @"m";
    }
    return [NSString stringWithFormat:@"http://farm%d.staticflickr.com/%d/%lld_%@_%@.jpg",flickrPhoto.farm,flickrPhoto.server,flickrPhoto.photoID,flickrPhoto.secret,size];
}

- (id)init
{
    self = [super init];
    
    if (self) {
        
        _resultsCache = [[NSCache alloc] init];
        NSLog(@"resultsCache after alloc init: %@", _resultsCache);
    }
    
    return self;
}

+ (NSString *)flickrSearchURLForSearchTerm:(NSString *) searchTerm
{
    searchTerm = [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&text=%@&per_page=20&format=json&nojsoncallback=1",kApiKey,searchTerm];
}

-(void)beginQuery: (NSString*)searchTerm
{
    //TODO: implement Activity Refresher
    //if (!tbvc.refreshControl.isRefreshing) [NSThread detachNewThreadSelector:@selector(showActivityViewer) toTarget:self withObject:nil];
    
    if( [self cacheNeedsToBeUpdated: searchTerm] ){
        NSLog(@"Cache needed to be updated");
        
        //set currentQueryURL to current query url, so we can use it as a key in the cache later
        self.currentSearchTerm = searchTerm;
        
        //use class method to return a formatted search url given a search term
        NSString *searchURL = [PPDataFetcher flickrSearchURLForSearchTerm:searchTerm];
        
        NSURL *url = [NSURL URLWithString: searchURL];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        GTMHTTPFetcher* myFetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [myFetcher beginFetchWithDelegate:self
                        didFinishSelector:@selector(fetchQuery:finishedWithData:error:)];
    }
    
    //else, send useCachedData notification
    else{
        NSLog(@"Cache DIDNT need to be updated");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"useCachedData" object:nil];
    }
    
    
}

- (void)fetchQuery:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)retrievedData error:(NSError *)error
{
    
    if (error != nil) {
        // failed; either an NSURLConnection error occurred, or the server returned
        // a status value of at least 300
        //
        // the NSError domain string for server status errors is kGTMHTTPFetcherStatusDomain
        
        NSLog(@"Connection error! NSURLConnection error occurred, or the server returned a status value of at least 300 Error code is: %d", [error code]);
        
        //TODO: more no-connection handling?
        
        //send message to present AlertView that connection could not be established.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CouldNotConnectToFeed"
                                                            object:nil];
        
    } else {
        
        NSDictionary *results = [NSJSONSerialization JSONObjectWithData:retrievedData options:kNilOptions error:&error];
        
        if(error != nil){
            NSLog(@"JSON parse error! Error code is: %d", [error code]);
            return;
        }
        
        //check Flickr stat value
        NSString * status = results[@"stat"];
        if ([status isEqualToString:@"fail"]) {
            NSError * error = [[NSError alloc] initWithDomain:@"FlickrSearch" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: results[@"message"]}];
            NSLog(@"Error reported in Flickr fetch! Error is: %@", error);
            return;
        }
        
        NSArray *objPhotos = results[@"photos"][@"photo"];
    
        //if no results were returned, post no data and break
        if( ![objPhotos count] > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NoDataInFeed"
                                                                object:nil];
            return;
        }
        
        NSMutableArray *flickrPhotos = [@[] mutableCopy];
        
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
        
            for(NSMutableDictionary *objPhoto in objPhotos)
            {
                //TODO: add more properties to the FlickrPhoto object?
                FlickrPhoto *photo = [[FlickrPhoto alloc] init];
                photo.farm = [objPhoto[@"farm"] intValue];
                photo.server = [objPhoto[@"server"] intValue];
                photo.secret = objPhoto[@"secret"];
                photo.photoID = [objPhoto[@"id"] longLongValue];
                
                NSString *searchURL = [PPDataFetcher flickrPhotoURLForFlickrPhoto:photo size:@"m"];
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                          options:0
                                                            error:nil];
                UIImage *image = [UIImage imageWithData:imageData];
                photo.thumbnail = image;
                
                [flickrPhotos addObject:photo];
            }
            
            NSDictionary *flickerPhotosAndCacheDate = @{ kCachedDate: [NSDate date], kResultsKey: flickrPhotos};
                                            
            
            [self.resultsCache setObject:flickerPhotosAndCacheDate forKey:self.currentSearchTerm];
            
            NSLog(@"retrieving cached date after setting it %@", [self.resultsCache objectForKey:self.currentSearchTerm][kCachedDate]);
            
            //NSLog(@"query Cache: %@", [self.resultsCache objectForKey:self.currentSearchTerm]);
            
            //send message to reload search VC
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidLoadNewData"
                                                                object:nil];
        });
        
    }
    
}

-(BOOL)cacheNeedsToBeUpdated:(NSString*)queryURL
{
    
    NSDate *dateOfCache = (NSDate*)[self.resultsCache objectForKey:self.currentSearchTerm][kCachedDate];
    
    if( ![self.resultsCache objectForKey:queryURL] )
        return YES;
    
    
    else if( [self hasBeenLongerThan: dateOfCache] ){
        return YES;
    }
    
    return NO;
    
}

-(BOOL)hasBeenLongerThan:(NSDate*)cachedDate
{
    NSLog(@"cachedDate: %@", cachedDate);
    
    NSUInteger unitFlags = NSDayCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:cachedDate toDate:[NSDate date] options:0];
    if ( ([components day] + 1) >= kDaysSinceCacheUpdate){
        NSLog(@"Days between dates: %d", ([components day] + 1));
        return YES;
    }
    
    return NO;
}


@end
