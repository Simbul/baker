//
//  BakerIssue.m
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

#import "BakerIssue.h"

@implementation BakerIssue

@synthesize ID;
@synthesize title;
@synthesize info;
@synthesize date;
@synthesize url;
@synthesize path;
@synthesize bakerBook;
@synthesize coverPath;
@synthesize coverURL;
@synthesize productID;
@synthesize price;

-(id)initWithBakerBook:(BakerBook *)book {
    self = [super init];
    if (self) {
        self.ID = book.ID;
        self.title = book.title;
        self.info = @"";
        self.date = book.date;
        self.url = [NSURL URLWithString:book.url];
        self.path = book.path;
        self.productID = @"";
        self.price = nil;

        self.bakerBook = book;

        self.coverPath = @"";
        if (book.cover == nil) {
            // TODO: set path to a default cover (right now a blank box will be displayed)
            NSLog(@"Cover not specified for %@, probably missing from book.json", book.ID);
        } else {
            self.coverPath = [book.path stringByAppendingPathComponent:book.cover];
        }

        self.transientStatus = BakerIssueTransientStatusNone;
    }
    return self;
}

#ifdef BAKER_NEWSSTAND
-(id)initWithIssueData:(NSDictionary *)issueData {
    self = [super init];
    if (self) {
        self.ID = [issueData objectForKey:@"name"];
        self.title = [issueData objectForKey:@"title"];
        self.info = [issueData objectForKey:@"info"];
        self.date = [issueData objectForKey:@"date"];
        self.coverURL = [NSURL URLWithString:[issueData objectForKey:@"cover"]];
        self.url = [NSURL URLWithString:[issueData objectForKey:@"url"]];
        self.productID = [issueData objectForKey:@"product_id"];
        self.price = nil;

        purchasesManager = [PurchasesManager sharedInstance];

        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.coverPath = [cachePath stringByAppendingPathComponent:self.ID];

        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        NKIssue *nkIssue = [nkLib issueWithName:self.ID];
        if (nkIssue) {
            self.path = [[nkIssue contentURL] path];
        } else {
            self.path = nil;
        }

        self.bakerBook = nil;

        self.transientStatus = BakerIssueTransientStatusNone;
    }
    return self;
}
-(NSString *)nkIssueContentStatusToString:(NKIssueContentStatus) contentStatus{
    if (contentStatus == NKIssueContentStatusNone) {
        return @"remote";
    } else if (contentStatus == NKIssueContentStatusDownloading) {
        return @"connecting";
    } else if (contentStatus == NKIssueContentStatusAvailable) {
        return @"downloaded";
    }
    return @"";
}
-(void)downloadWithDelegate:(id < NSURLConnectionDownloadDelegate >)delegate {
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NKIssue *nkIssue = [nkLib issueWithName:self.ID];
    NSURLRequest *req = [NSURLRequest requestWithURL:self.url];
    NKAssetDownload *assetDownload = [nkIssue addAssetWithRequest:req];
    [assetDownload downloadWithDelegate:delegate];
}
#endif

-(void)getCover:(void(^)(UIImage *img))completionBlock {
    UIImage *image = [UIImage imageWithContentsOfFile:self.coverPath];
    if (image) {
        completionBlock(image);
    } else {
        NSLog(@"Cover not found for %@ at path '%@'", self.ID, self.coverPath);
        if (self.coverURL) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                NSLog(@"Downloading cover from %@ to %@", self.coverURL, self.coverPath);
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
-(NSString *)getStatus {
#ifdef BAKER_NEWSSTAND
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
        if ([purchasesManager isMarkedAsPurchased:self.productID]) {
            return @"purchased";
        } else if (self.price) {
            return @"purchasable";
        } else {
            return @"unpriced";
        }
    } else {
        return nkIssueStatus;
    }
#else
    return @"bundled";
#endif
}

-(void)dealloc {

}

@end
