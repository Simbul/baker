//
//  Downloader.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//  Neither the name of the Baker Framework nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
