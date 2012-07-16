//
//  Downloader.h
//  Baker
//
//  Created by Xmas on 10/25/11.
//  Copyright 2010 Geeks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Downloader : NSObject {
    
    NSString *notificationName;
    NSMutableDictionary *requestSummary;
    
    long long expectedData;
    NSMutableData *receivedData;
    float fakeProgress;
    
    NSURLConnection *connectionRef;
    
    UIActivityIndicatorView * progressWheel;
    UIProgressView *progressBar;
    UIAlertView *progressAlert;
}

@property (nonatomic, retain) NSURLConnection *connectionRef;

- (Downloader *)initDownloader:(NSString *)observerName;
- (void)makeHTTPRequest:(NSString *)urlAddress;

- (void)initProgress;
- (void)postNotification;
- (void)cancelConnection;

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;

@end
