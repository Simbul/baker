//
//  ShelfViewController.h
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

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

#import "BakerIssue.h"
#import "IssuesManager.h"
#import "ShelfStatus.h"
#import "BakerAPI.h"
#ifdef BAKER_NEWSSTAND
#import "PurchasesManager.h"
#endif

@interface ShelfViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate, UIWebViewDelegate> {
    BakerAPI *api;
    IssuesManager *issuesManager;
    NSMutableArray *notRecognisedTransactions;
    __weak UIPopoverController *infoPopover;

    #ifdef BAKER_NEWSSTAND
    PurchasesManager *purchasesManager;
    #endif
}

@property (copy, nonatomic) NSArray *issues;
@property (copy, nonatomic) NSArray *supportedOrientation;

@property (retain, nonatomic) NSMutableArray *issueViewControllers;
@property (retain, nonatomic) ShelfStatus *shelfStatus;

@property (strong, nonatomic) UICollectionView *gridView;
@property (strong, nonatomic) UIImageView *background;
@property (strong, nonatomic) UIBarButtonItem *refreshButton;
@property (strong, nonatomic) UIBarButtonItem *subscribeButton;

@property (strong, nonatomic) UIActionSheet *subscriptionsActionSheet;
@property (strong, nonatomic) NSArray *subscriptionsActionSheetActions;
@property (strong, nonatomic) UIAlertView *blockingProgressView;

@property (copy, nonatomic) NSString *bookToBeProcessed;

#pragma mark - Init
- (id)init;
- (id)initWithBooks:(NSArray *)currentBooks;

#pragma mark - Shelf data source
#ifdef BAKER_NEWSSTAND
- (void)handleRefresh:(NSNotification *)notification;

#pragma mark - Store Kit
- (void)handleSubscription:(NSNotification *)notification;
#endif

#pragma mark - Navigation management
- (void)readIssue:(BakerIssue *)issue;
- (void)handleReadIssue:(NSNotification *)notification;
- (void)receiveBookProtocolNotification:(NSNotification *)notification;
- (void)handleBookToBeProcessed;
- (void)pushViewControllerWithBook:(BakerBook *)book;

#pragma mark - Buttons management
-(void)setrefreshButtonEnabled:(BOOL)enabled;
-(void)setSubscribeButtonEnabled:(BOOL)enabled;

#pragma mark - Helper methods
+ (int)getBannerHeight;

@end
