//
//  BakerIssue.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau, Pieter Claerhout
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

#import "BKRIssue.h"
#import "BKRBakerAPI.h"
#import "BKRSettings.h"

#import "BKRZipArchive.h"
#import "BKRReachability.h"
#import "BKRUtils.h"
#import "NSURL+BakerExtensions.h"
#import "NSObject+BakerExtensions.h"

@implementation BKRIssue

#pragma mark - Initialization

- (id)initWithBakerBook:(BKRBook*)book {
    self = [super init];
    if (self) {
        _ID         = book.ID;
        _title      = book.title;
        _info       = @"";
        _date       = book.date;
        _url        = [NSURL URLWithString:book.url];
        _path       = book.path;
        _categories = book.categories;
        _productID  = @"";
        _price      = nil;
        _bakerBook  = book;

        _coverPath = @"";
        if (book.cover == nil) {
            // TODO: set path to a default cover (right now a blank box will be displayed)
            NSLog(@"Cover not specified for %@, probably missing from book.json", book.ID);
        } else {
            _coverPath = [book.path stringByAppendingPathComponent:book.cover];
        }

        _transientStatus = BakerIssueTransientStatusNone;

        [self setNotificationDownloadNames];
    }
    return self;
}

- (void)setNotificationDownloadNames {
    self.notificationDownloadStartedName     = [NSString stringWithFormat:@"notification_download_started_%@", self.ID];
    self.notificationDownloadProgressingName = [NSString stringWithFormat:@"notification_download_progressing_%@", self.ID];
    self.notificationDownloadFinishedName    = [NSString stringWithFormat:@"notification_download_finished_%@", self.ID];
    self.notificationDownloadErrorName       = [NSString stringWithFormat:@"notification_download_error_%@", self.ID];
    self.notificationUnzipErrorName          = [NSString stringWithFormat:@"notification_unzip_error_%@", self.ID];
}

#pragma mark - Newsstand

- (id)initWithIssueData:(NSDictionary*)issueData {
    self = [super init];
    if (self) {
        self.ID         = issueData[@"name"];
        self.title      = issueData[@"title"];
        self.info       = issueData[@"info"];
        self.date       = issueData[@"date"];
        self.categories = issueData[@"categories"];
        self.coverURL   = [NSURL URLWithString:issueData[@"cover"]];
        self.url        = [NSURL URLWithString:issueData[@"url"]];
        if (issueData[@"product_id"] != [NSNull null]) {
            self.productID = issueData[@"product_id"];
        }
        self.price = nil;

        purchasesManager = [BKRPurchasesManager sharedInstance];

        self.coverPath = [self.bkrCachePath stringByAppendingPathComponent:self.ID];

        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        NKIssue *nkIssue = [nkLib issueWithName:self.ID];
        if (nkIssue) {
            self.path = [[nkIssue contentURL] path];
        } else {
            self.path = nil;
        }

        self.bakerBook = nil;

        self.transientStatus = BakerIssueTransientStatusNone;

        [self setNotificationDownloadNames];
    }
    return self;
}

- (NSString*)nkIssueContentStatusToString:(NKIssueContentStatus) contentStatus{
    if (contentStatus == NKIssueContentStatusNone) {
        return @"remote";
    } else if (contentStatus == NKIssueContentStatusDownloading) {
        return @"connecting";
    } else if (contentStatus == NKIssueContentStatusAvailable) {
        return @"downloaded";
    }
    return @"";
}

- (void)download {
    BKRReachability *reach = [BKRReachability reachabilityWithHostname:@"www.google.com"];
    if ([reach isReachable]) {
        BKRBakerAPI *api = [BKRBakerAPI sharedInstance];
        NSURLRequest *req = [api requestForURL:self.url method:@"GET"];

        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        NKIssue *nkIssue = [nkLib issueWithName:self.ID];

        NKAssetDownload *assetDownload = [nkIssue addAssetWithRequest:req];
        [self downloadWithAsset:assetDownload];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationDownloadErrorName object:self userInfo:nil];
    }
}

- (void)downloadWithAsset:(NKAssetDownload*)asset {
    [asset downloadWithDelegate:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationDownloadStartedName object:self userInfo:nil];
}

#pragma mark - Newsstand download management

- (void)connection:(NSURLConnection*)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
    NSDictionary *userInfo = @{@"totalBytesWritten": @(totalBytesWritten),
                              @"expectedTotalBytes": @(expectedTotalBytes)};
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationDownloadProgressingName object:self userInfo:userInfo];
}

- (void)connectionDidFinishDownloading:(NSURLConnection*)connection destinationURL:(NSURL*)destinationURL {
    if ([BKRSettings sharedSettings].isNewsstand) {
        [self unpackAssetDownload:connection.newsstandAssetDownload toURL:destinationURL];
    }
}

- (void)unpackAssetDownload:(NKAssetDownload*)newsstandAssetDownload toURL:(NSURL*)destinationURL {

    UIApplication *application = [UIApplication sharedApplication];
    NKIssue *nkIssue           = newsstandAssetDownload.issue;
    NSString *destinationPath  = [[nkIssue contentURL] path];

    __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"[BakerShelf] Newsstand - File is being unzipped to %@", destinationPath);
        BOOL unzipSuccessful = NO;
        unzipSuccessful = [BKRZipArchive unzipFileAtPath:[destinationURL path] toDestination:destinationPath];
        if (!unzipSuccessful) {
            NSLog(@"[BakerShelf] Newsstand - Unable to unzip file: %@. The file may not be a valid HPUB archive.", [destinationURL path]);
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationUnzipErrorName object:self userInfo:nil];
            });
        }

        NSLog(@"[BakerShelf] Newsstand - Removing temporary downloaded file %@", [destinationURL path]);
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSError *error;
        if ([fileMgr removeItemAtPath:[destinationURL path] error:&error] != YES){
            NSLog(@"[BakerShelf] Newsstand - Unable to delete file: %@", [error localizedDescription]);
        }

        if (unzipSuccessful) {
            // Notification and UI update have to be handled on the main thread
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationDownloadFinishedName object:self userInfo:nil];
            });
        }

        [self updateNewsstandIcon];

        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    });
}

- (void)updateNewsstandIcon {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];

    UIImage *coverImage = [UIImage imageWithContentsOfFile:self.coverPath];
    if (coverImage) {
        [[UIApplication sharedApplication] setNewsstandIconImage:coverImage];
    }
}

- (void)connectionDidResumeDownloading:(NSURLConnection*)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes {
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"Connection error when trying to download %@: %@", [connection currentRequest].URL, [error localizedDescription]);

    [connection cancel];

    NSDictionary *userInfo = @{@"error": error};
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationDownloadErrorName object:self userInfo:userInfo];
}

- (void)getCoverWithCache:(bool)cache andBlock:(void(^)(UIImage *img))completionBlock {
    UIImage *image = [UIImage imageWithContentsOfFile:self.coverPath];
    if (cache && image) {
        completionBlock(image);
    } else {
        if (self.coverURL) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                NSData *imageData = [NSData dataWithContentsOfURL:self.coverURL];
                UIImage *image = [UIImage imageWithData:imageData];
                if (image) {
                    [imageData writeToFile:self.coverPath atomically:YES];
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        completionBlock(image);
                    });
                }
            });
        }
    }
}

- (NSString*)getStatus {
    if ([BKRSettings sharedSettings].isNewsstand) {
        switch (self.transientStatus) {
            case BakerIssueTransientStatusDownloading:
                return @"downloading";
                break;
            case BakerIssueTransientStatusOpening:
                return @"opening";
                break;
            case BakerIssueTransientStatusPurchasing:
                return @"purchasing";
                break;
            default:
                break;
        }

        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        NKIssue *nkIssue = [nkLib issueWithName:self.ID];
        NSString *nkIssueStatus = [self nkIssueContentStatusToString:[nkIssue status]];
        if ([nkIssueStatus isEqualToString:@"remote"] && self.productID) {
            if ([purchasesManager isPurchased:self.productID]) {
                return @"purchased";
            } else if (self.price) {
                return @"purchasable";
            } else {
                return @"unpriced";
            }
        } else {
            return nkIssueStatus;
        }
    } else {
        return @"bundled";
    }
}

@end
