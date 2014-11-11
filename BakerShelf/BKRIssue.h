//
//  BakerIssue.h
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

#import <Foundation/Foundation.h>

#import <NewsstandKit/NewsstandKit.h>
#import "BKRPurchasesManager.h"

#import "BKRBook.h"

typedef enum transientStates {
    BakerIssueTransientStatusNone,
    BakerIssueTransientStatusDownloading,
    BakerIssueTransientStatusOpening,
    BakerIssueTransientStatusPurchasing,
    BakerIssueTransientStatusUnpriced
} BakerIssueTransientStatus;

@interface BKRIssue : NSObject <NSURLConnectionDownloadDelegate> {
    BKRPurchasesManager *purchasesManager;
}

@property (nonatomic, copy) NSString *ID;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *info;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSArray *categories;

@property (nonatomic, copy) NSString *coverPath;
@property (nonatomic, copy) NSURL *coverURL;

@property (nonatomic, copy) NSString *productID;
@property (nonatomic, copy) NSString *price;

@property (nonatomic, strong) BKRBook *bakerBook;

@property (nonatomic, assign) BakerIssueTransientStatus transientStatus;

@property (nonatomic, copy) NSString *notificationDownloadStartedName;
@property (nonatomic, copy) NSString *notificationDownloadProgressingName;
@property (nonatomic, copy) NSString *notificationDownloadFinishedName;
@property (nonatomic, copy) NSString *notificationDownloadErrorName;
@property (nonatomic, copy) NSString *notificationUnzipErrorName;

- (id)initWithBakerBook:(BKRBook*)bakerBook;
- (void)getCoverWithCache:(bool)cache andBlock:(void(^)(UIImage *img))completionBlock;
- (NSString*)getStatus;

- (id)initWithIssueData:(NSDictionary*)issueData;
- (void)download;
- (void)downloadWithAsset:(NKAssetDownload*)asset;

@end
