//
//  BKRSettings.h
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2014, Pieter Claerhout
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

#import <Foundation/Foundation.h>

@interface BKRSettings : NSObject

// Timeout for most network requests (in seconds)
@property (nonatomic, readonly) NSTimeInterval requestTimeout;

@property (nonatomic, readonly) BOOL isNewsstand;

// ----------------------------------------------------------------------------------------------------
// Mandatory - This constant defines where the JSON file containing all the publications is located.
// For more information on this file, see: https://github.com/Simbul/baker/wiki/Newsstand-shelf-JSON
// E.g. @"http://example.com/shelf.json"
@property (nonatomic, readonly) NSString *newsstandManifestUrl;

@property (nonatomic, readonly) BOOL newsstandLatestIssueCover;

// ----------------------------------------------------------------------------------------------------
// Optional - This constant specifies the URL to ping back when a user purchases an issue or a subscription.
// For more information, see: https://github.com/Simbul/baker/wiki/Baker-Server-API
// E.g. @"http://example.com/purchased"
@property (nonatomic, readonly) NSString *purchaseConfirmationUrl;

// ----------------------------------------------------------------------------------------------------
// Optional - This constant specifies a URL that will be used to retrieve the list of purchased issues.
// For more information, see: https://github.com/Simbul/baker/wiki/Baker-Server-API
// E.g. @"http://example.com/purchases"
@property (nonatomic, readonly) NSString *purchasesUrl;

// ----------------------------------------------------------------------------------------------------
// Optional - This constant specifies the URL to ping back when a user enables push notifications.
// For more information, see: https://github.com/Simbul/baker/wiki/Baker-Server-API
// E.g. @"http://example.com/post_apns_token"
@property (nonatomic, readonly) NSString *postApnsTokenUrl;

// ----------------------------------------------------------------------------------------------------
// Mandatory - The following two constants identify the subscriptions you set up in iTunesConnect.
// See: iTunes Connect -> Manage Your Application -> (Your application) -> Manage In App Purchases

// This constant identifies a free subscription.
// E.g. @"com.example.MyBook.subscription.free"
@property (nonatomic, readonly) NSString *freeSubscriptionProductId;

// This constant identifies one or more auto-renewable subscriptions.
@property (nonatomic, readonly) NSArray *autoRenewableSubscriptionProductIds;


// Background color for issues cover (before downloading the actual cover)
@property (nonatomic, readonly) NSString *issuesCoverBackgroundColor;

// Title for issues in the shelf
@property (nonatomic, readonly) NSString *issuesTitleFont;
@property (nonatomic, readonly) int issuesTitleFontSize;
@property (nonatomic, readonly) NSString *issuesTitleColor;

// Info text for issues in the shelf
@property (nonatomic, readonly) NSString *issuesInfoFont;
@property (nonatomic, readonly) int issuesInfoFontSize;
@property (nonatomic, readonly) NSString *issuesInfoColor;

@property (nonatomic, readonly) NSString *issuesPriceColor;

// Download/read button for issues in the shelf
@property (nonatomic, readonly) NSString *issuesActionFont;
@property (nonatomic, readonly) int issuesActionFontSize;
@property (nonatomic, readonly) NSString *issuesActionBackgroundColor;
@property (nonatomic, readonly) NSString *issuesActionButtonColor;

// Archive button for issues in the shelf
@property (nonatomic, readonly) NSString *issuesArchiveFont;
@property (nonatomic, readonly) int issuesArchiveFontSize;
@property (nonatomic, readonly) NSString *issuesArchiveBackgroundColor;
@property (nonatomic, readonly) NSString *issuesArchiveButtonColor;

// Text and spinner for issues that are being loaded in the shelf
@property (nonatomic, readonly) NSString *issuesLoadingLabelColor;
@property (nonatomic, readonly) NSString *issuesLoadingSpinnerColor;

// Progress bar for issues that are being downloaded in the shelf
@property (nonatomic, readonly) NSString *issuesProgressbarTintColor;

// Shelf background customization
@property (nonatomic, readonly) NSDictionary *issuesShelfOptions;

+ (BKRSettings*)sharedSettings;

@end
