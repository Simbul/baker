//
//  Downloader.m
//  Baker
//
//  Created by Xmas on 10/25/11.
//  Copyright 2010 Geeks. All rights reserved.
//

#import "Downloader.h"

@implementation Downloader

@synthesize connectionRef;

- (Downloader *)initDownloader:(NSString *)observerName {
	
	[super init];
	
	notificationName = observerName;
	
	requestSummary = [[NSMutableDictionary alloc] init];
	receivedData = [[NSMutableData alloc] init];
	
	return self;
}

- (void)makeHTTPRequest:(NSString *)urlAddress {
	
	NSLog(@"HTTP Request to %@", urlAddress);
	
	urlAddress = [urlAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *url = [NSURL URLWithString:urlAddress];
		
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setTimeoutInterval:30.0];
	[request setHTTPMethod:@"GET"];
		
	connectionRef = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	[request release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
	
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
	
	NSLog(@"Connection received response");
    [receivedData setLength:0];
	
	if ([response respondsToSelector:@selector(statusCode)]) {
		
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		NSLog(@"Response status code: %d", statusCode);
		
		if (statusCode >= 400) {
			
			[connection cancel];
			
			NSString *errorString = [NSString stringWithFormat:@"server returned status code %d",statusCode];
			NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
			NSError *statusError = [NSError errorWithDomain:@"Response error" code:statusCode userInfo:errorInfo];
			
			[self connection:connection didFailWithError:statusError];
			
		} else {
			
			expectedData = [response expectedContentLength];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
    // Connection error, inform the user
	[connection release];
	
    NSLog(@"Connection failed! Error - %@", [error localizedDescription]);
	[requestSummary setObject:[error localizedDescription] forKey:@"error"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:requestSummary];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
    // Append received data to receivedData.
	NSLog(@"Connection received %d bytes of data", [data length]);
	[receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
    // Connection finished, do something with the data
	[connection release];
	
    NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	[requestSummary setObject:receivedData forKey:@"data"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:requestSummary];
}

- (void)cancelConnection {
	
	[connectionRef cancel];
	[connectionRef release];
}

- (void)dealloc {
	
	[requestSummary release];
	[receivedData release];
	[super dealloc];
}

@end
