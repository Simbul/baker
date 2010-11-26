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
	
	NSURLConnection *connectionRef;
}

@property (nonatomic, retain) NSURLConnection *connectionRef;

- (Downloader *)initDownloader:(NSString *)observerName;
- (void)makeHTTPRequest:(NSString *)urlAddress;
- (void)cancelConnection;

@end
