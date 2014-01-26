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

#import "Constants.h"
#import <Foundation/Foundation.h>

#ifdef BAKER_NEWSSTAND
#import <NewsstandKit/NewsstandKit.h>
#import "PurchasesManager.h"
#endif

#import "BakerBook.h"

typedef enum transientStates {
    BakerIssueTransientStatusNone,
    BakerIssueTransientStatusDownloading,
    BakerIssueTransientStatusOpening,
    BakerIssueTransientStatusPurchasing,
    BakerIssueTransientStatusUnpriced
} BakerIssueTransientStatus;

#ifdef BAKER_NEWSSTAND
@interface BakerIssue : NSObject <NSURLConnectionDownloadDelegate> {
    PurchasesManager *purchasesManager;
}
#else
@interface BakerIssue : NSObject
#endif

@property (copy, nonatomic) NSString *ID;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *info;
@property (copy, nonatomic) NSString *date;
@property (copy, nonatomic) NSURL *url;
@property (copy, nonatomic) NSString *path;

@property (copy, nonatomic) NSString *coverPath;
@property (copy, nonatomic) NSURL *coverURL;

@property (copy, nonatomic) NSString *productID;
@property (copy, nonatomic) NSString *price;

@property (retain, nonatomic) BakerBook *bakerBook;

@property (assign, nonatomic) BakerIssueTransientStatus transientStatus;

@property (copy, nonatomic) NSString *notificationDownloadStartedName;
@property (copy, nonatomic) NSString *notificationDownloadProgressingName;
@property (copy, nonatomic) NSString *notificationDownloadFinishedName;
@property (copy, nonatomic) NSString *notificationDownloadErrorName;
@property (copy, nonatomic) NSString *notificationUnzipErrorName;

-(id)initWithBakerBook:(BakerBook *)bakerBook;
-(void)getCoverWithCache:(bool)cache andBlock:(void(^)(UIImage *img))completionBlock;
-(NSString *)getStatus;

#ifdef BAKER_NEWSSTAND
-(id)initWithIssueData:(NSDictionary *)issueData;
-(void)download;
-(void)downloadWithAsset:(NKAssetDownload *)asset;
#endif

@end
