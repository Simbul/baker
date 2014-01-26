//
//  BakerAnalyticsEvents.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau
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

#import "BakerAnalyticsEvents.h"


@implementation BakerAnalyticsEvents


#pragma mark - Singleton

+ (BakerAnalyticsEvents *)sharedInstance {
    static dispatch_once_t once;
    static BakerAnalyticsEvents *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    
    self = [super init];
    
    // ****** Add here your analytics code
    // tracker = [[GAI sharedInstance] trackerWithTrackingId:@"ADD_HERE_YOUR_TRACKING_CODE"];
    
    
    // ****** Register to handle events
    [self registerEvents];
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark - Events

- (void)registerEvents {
    // Register the analytics event that are going to be tracked by Baker.
    
    NSArray *analyticEvents = [NSArray arrayWithObjects:
                               @"BakerApplicationStart",
                               @"BakerIssueDownload",
                               @"BakerIssueOpen",
                               @"BakerIssueClose",
                               @"BakerIssuePurchase",
                               @"BakerIssueArchive",
                               @"BakerSubscriptionPurchase",
                               @"BakerViewPage",
                               @"BakerViewIndexOpen",
                               @"BakerViewModalBrowser",
                               nil];
    
    for (NSString *eventName in analyticEvents) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receiveEvent:)
                                                     name:eventName
                                                   object:nil];
    }
    

}

- (void)receiveEvent:(NSNotification *)notification {
    //NSLog(@"[BakerAnalyticsEvent] Received event %@", [notification name]); // Uncomment this to debug
    
    // If you want, you can handle differently the various events
    if ([[notification name] isEqualToString:@"BakerApplicationStart"]) {
        // Track here when the Baker app opens
    } else if ([[notification name] isEqualToString:@"BakerIssueDownload"]) {
        // Track here when a issue download is requested
    } else if ([[notification name] isEqualToString:@"BakerIssueOpen"]) {
        // Track here when a issue is opened to be read
    } else if ([[notification name] isEqualToString:@"BakerIssueClose"]) {
        // Track here when a issue that was being read is closed
    } else if ([[notification name] isEqualToString:@"BakerIssuePurchase"]) {
        // Track here when a issue purchase is requested
    } else if ([[notification name] isEqualToString:@"BakerIssueArchive"]) {
        // Track here when a issue archival is requested
    } else if ([[notification name] isEqualToString:@"BakerSubscriptionPurchase"]) {
        // Track here when a subscription purchased is requested
    } else if ([[notification name] isEqualToString:@"BakerViewPage"]) {
        // Track here when a specific page is opened
        // BakerViewController *bakerview = [notification object]; // Uncomment this to get the BakerViewController object and get its properties
        //NSLog(@" - Tracking page %d", bakerview.currentPageNumber); // This is useful to check if it works
    } else if ([[notification name] isEqualToString:@"BakerViewIndexOpen"]) {
        // Track here the opening of the index and status bar
    } else if ([[notification name] isEqualToString:@"BakerViewModalBrowser"]) {
        // Track here the opening of the modal view
    } else {
        
    }
}


@end
