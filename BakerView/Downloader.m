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
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    NSLog(@"HTTP Request to %@", urlAddress);
    
    NSString *urlString = [urlAddress stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];    
    NSURL *url = [NSURL URLWithString:urlString];
    
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
            fakeProgress = 0.1;
            
            [self initProgress];
        }
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    // Connection error, inform the user
    [connection release];
    
    NSLog(@"Connection failed! Error - %@", [error localizedDescription]);
    [requestSummary setObject:[error localizedDescription] forKey:@"error"];
    
    [progressAlert dismissWithClickedButtonIndex:progressAlert.cancelButtonIndex animated:YES];
    [self performSelector:@selector(postNotification) withObject:nil afterDelay:0.1];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    // Append received data to receivedData.
    NSLog(@"Connection received %d bytes of data", [data length]);
    [receivedData appendData:data];
    
    if (expectedData > -1) {
        
        long long receivedDataLength = (long long)[receivedData length];
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
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
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
