//
//  Downloader.m
//  Baker
//
//  Created by Xmas on 10/25/11.
//  Copyright 2010 Geeks. All rights reserved.
//

#import "Downloader.h"

#define DOWNLOAD_FEEDBACK_TITLE @"Downloading..."
#define DOWNLOAD_FEEDBACK_CANCEL @"Cancel"

@implementation Downloader

@synthesize connectionRef;

- (Downloader *)initDownloader:(NSString *)observerName {
	
	self = [super init];
	if (self) {
        notificationName = observerName;	
        requestSummary = [[NSMutableDictionary alloc] init];
        receivedData = [[NSMutableData alloc] init];
    }
	return self;
}
- (void)makeHTTPRequest:(NSString *)urlAddress {	    
    // create tempFile to make possible for recovery download.
    NSString *urlStr = [urlAddress lastPathComponent];
    NSString *tempPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingString:@"/"];
    tempFile = [[[tempPath stringByAppendingString:urlStr] stringByAppendingString:@".tmp"] retain];
    NSLog(@"tempFile is:%@",tempFile);
    
    [fileHandle closeFile];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFile]){
        // not first time download, so we can use this tempFile
        fileHandle = [[NSFileHandle fileHandleForWritingAtPath:tempFile] retain];
    } else {
        // tempFile not found yet, so we need to create it.
        [[NSFileManager defaultManager] createFileAtPath:tempFile contents:nil attributes:nil];
        fileHandle = [[NSFileHandle fileHandleForWritingAtPath:tempFile] retain];
    }
    offset = [fileHandle seekToEndOfFile];
    // preparing for recovery download
    NSString *range = [NSString stringWithFormat:@"bytes=%llu-",offset];
	
    NSLog(@"HTTP Request to %@", urlAddress);
    
	NSString *urlString = [urlAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];	
	NSURL *url = [NSURL URLWithString:urlString];
		
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    // tell Server that we are in state of recovery download
    [request addValue:range forHTTPHeaderField:@"Range"];
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
    //[receivedData setLength:0];
	
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
			
			expectedData = [response expectedContentLength]+offset;
			fakeProgress = 0.1;
			
			[self initProgress];
		}
	}
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	
    // Connection error, inform the user
	[connection release];
    // also we should close the tempFile
    [fileHandle closeFile];
	
    NSLog(@"Connection failed! Error - %@", [error localizedDescription]);
	[requestSummary setObject:[error localizedDescription] forKey:@"error"];
	
	[progressAlert dismissWithClickedButtonIndex:progressAlert.cancelButtonIndex animated:YES];
	[self performSelector:@selector(postNotification) withObject:nil afterDelay:0.1];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	
    // Append received data to tempFile.
	NSLog(@"Connection received %d bytes of data", [data length]);
	
    [fileHandle writeData:data];
    offset = [fileHandle offsetInFile];
	
	if (expectedData > -1) {
		
		long long receivedDataLength = offset;
		float progress = (float)receivedDataLength/(float)expectedData;
		progressBar.progress = progress;
	
	} else {
		
		progressBar.progress = progressBar.progress + fakeProgress;
		fakeProgress = fakeProgress/2;
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
    // Connection finished, do something with the data
	[connection release];
    
    // handle temp file and prepare the data
    [fileHandle closeFile];
    
    NSFileHandle *readHandle = [[NSFileHandle fileHandleForReadingAtPath:tempFile] retain];
    [receivedData appendData:[readHandle readDataToEndOfFile]];
    [readHandle closeFile];
    [readHandle release];
    // remove tempFile now
    [[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
	
    NSLog(@"Succeeded! Received %d bytes of data",[receivedData length]);
	[requestSummary setObject:receivedData forKey:@"data"];
	
	[progressAlert dismissWithClickedButtonIndex:progressAlert.cancelButtonIndex animated:YES];
	[self performSelector:@selector(postNotification) withObject:nil afterDelay:0.1];
}

- (void)initProgress {
	
	progressWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(124,45,37,37)];
	progressWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
	[progressWheel startAnimating];
	
	progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(30,95,225,9)];
	progressBar.progressViewStyle = UIProgressViewStyleBar;
	progressBar.progress = 0;
	
	progressAlert = [[UIAlertView alloc] initWithTitle:DOWNLOAD_FEEDBACK_TITLE
											   message:@"\n\n\n"
											  delegate:self
									 cancelButtonTitle:DOWNLOAD_FEEDBACK_CANCEL
									 otherButtonTitles:nil];
	
	[progressAlert addSubview:progressWheel];
	[progressAlert addSubview:progressBar];
	[progressAlert show];
	
	[progressWheel release];
	[progressBar release];
	[progressAlert release];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	[self cancelConnection];
	[self performSelector:@selector(postNotification) withObject:nil afterDelay:0.1];
}
- (void)postNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:requestSummary];
}
- (void)cancelConnection {
	
	[connectionRef cancel];
	[connectionRef release];
}

- (void)dealloc {
    [fileHandle closeFile];
    [fileHandle release];
    [tempFile release];
	[requestSummary release];
	[receivedData release];
	[super dealloc];
}

@end
