//
//  IssueViewController.m
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

#import <QuartzCore/QuartzCore.h>

#import "BKRSettings.h"
#import "BKRIssueViewController.h"
#import "BKRZipArchive.h"
#import "BKRPurchasesManager.h"

#import "UIColor+BakerExtensions.h"
#import "UIScreen+BakerExtensions.h"
#import "BKRUtils.h"

@implementation BKRIssueViewController

#pragma mark - Init

- (id)initWithBakerIssue:(BKRIssue*)bakerIssue {
    self = [super init];
    if (self) {
        _issue = bakerIssue;
        _currentStatus = nil;

        purchaseDelayed = NO;

        if ([BKRSettings sharedSettings].isNewsstand) {
            purchasesManager = [BKRPurchasesManager sharedInstance];
            [self addPurchaseObserver:@selector(handleIssueRestored:) name:@"notification_issue_restored"];

            [self addIssueObserver:@selector(handleDownloadStarted:) name:self.issue.notificationDownloadStartedName];
            [self addIssueObserver:@selector(handleDownloadProgressing:) name:self.issue.notificationDownloadProgressingName];
            [self addIssueObserver:@selector(handleDownloadFinished:) name:self.issue.notificationDownloadFinishedName];
            [self addIssueObserver:@selector(handleDownloadError:) name:self.issue.notificationDownloadErrorName];
            [self addIssueObserver:@selector(handleUnzipError:) name:self.issue.notificationUnzipErrorName];
        }
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    CGSize cellSize = [BKRIssueViewController getIssueCellSizeForOrientation:self.interfaceOrientation];

    self.view.frame = CGRectMake(0, 0, cellSize.width, cellSize.height);
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 42;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferredContentSizeChanged:) name:UIContentSizeCategoryDidChangeNotification object:nil];

    UI ui = [BKRIssueViewController getIssueContentMeasures];

    self.issueCover = [UIButton buttonWithType:UIButtonTypeCustom];
    self.issueCover.frame = CGRectMake(ui.cellPadding, ui.cellPadding, ui.thumbWidth, ui.thumbHeight);

    self.issueCover.backgroundColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesCoverBackgroundColor];
    self.issueCover.adjustsImageWhenHighlighted = NO;
    self.issueCover.adjustsImageWhenDisabled = NO;

    self.issueCover.layer.shadowOpacity = 0.5;
    self.issueCover.layer.shadowOffset = CGSizeMake(0, 2);
    self.issueCover.layer.shouldRasterize = YES;
    self.issueCover.layer.rasterizationScale = [UIScreen mainScreen].scale;

    [self.issueCover addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.issueCover];

    // SETUP TITLE LABEL
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.textColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesTitleColor];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;

    [self.view addSubview:self.titleLabel];

    // SETUP INFO LABEL
    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.textColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesInfoColor];
    self.infoLabel.backgroundColor = [UIColor clearColor];
    self.infoLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.infoLabel.textAlignment = NSTextAlignmentLeft;

    [self.view addSubview:self.infoLabel];

    // SETUP ACTION BUTTON
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.backgroundColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionBackgroundColor];

    [self.actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];
    [self.actionButton setTitleColor:[UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionButtonColor] forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.actionButton];

    // SETUP ARCHIVE BUTTON
    self.archiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.archiveButton.backgroundColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesArchiveBackgroundColor];

    [self.archiveButton setTitle:NSLocalizedString(@"ARCHIVE_TEXT", nil) forState:UIControlStateNormal];
    [self.archiveButton setTitleColor:[UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesArchiveButtonColor] forState:UIControlStateNormal];

    if ([BKRSettings sharedSettings].isNewsstand) {
        [self.archiveButton addTarget:self action:@selector(archiveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.archiveButton];
    }

    // SETUP DOWN/LOADING SPINNER AND LABEL
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.color = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesLoadingSpinnerColor];
    self.spinner.backgroundColor = [UIColor clearColor];
    self.spinner.hidesWhenStopped = YES;

    self.loadingLabel = [[UILabel alloc] init];
    self.loadingLabel.textColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesLoadingLabelColor];
    self.loadingLabel.backgroundColor = [UIColor clearColor];
    self.loadingLabel.textAlignment = NSTextAlignmentLeft;
    self.loadingLabel.text = NSLocalizedString(@"DOWNLOADING_TEXT", nil);

    [self.view addSubview:self.spinner];
    [self.view addSubview:self.loadingLabel];

    // SETUP PROGRESS BAR
    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressBar.progressTintColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesProgressbarTintColor];

    [self.view addSubview:self.progressBar];

    if ([BKRSettings sharedSettings].isNewsstand) {
        // RESUME PENDING NEWSSTAND DOWNLOAD
        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        for (NKAssetDownload *asset in [nkLib downloadingAssets]) {
            if ([asset.issue.name isEqualToString:self.issue.ID]) {
                NSLog(@"[BakerShelf] Resuming abandoned Newsstand download: %@", asset.issue.name);
                [self.issue downloadWithAsset:asset];
            }
        }
    }
    
    [self refreshContentWithCache:NO];
}

- (void)refreshContentWithCache:(bool)cache {
    UIFont *titleFont = [UIFont fontWithName:[BKRSettings sharedSettings].issuesTitleFont
                                        size:[BKRSettings sharedSettings].issuesTitleFontSize
                         ];
    UIFont *infoFont = [UIFont fontWithName:[BKRSettings sharedSettings].issuesInfoFont
                                       size:[BKRSettings sharedSettings].issuesInfoFontSize
                        ];
    UIFont *actionFont = [UIFont fontWithName:[BKRSettings sharedSettings].issuesActionFont
                                         size:[BKRSettings sharedSettings].issuesActionFontSize
                          ];
    UIFont *archiveFont = [UIFont fontWithName:[BKRSettings sharedSettings].issuesArchiveFont
                                          size:[BKRSettings sharedSettings].issuesArchiveFontSize
                           ];

    UI ui = [BKRIssueViewController getIssueContentMeasures];
    int heightOffset = ui.cellPadding;
    uint textLineheight = [@"The brown fox jumps over the lazy dog" boundingRectWithSize:CGSizeMake(MAXFLOAT,MAXFLOAT)
                                                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
                                                                              attributes:@{NSFontAttributeName: infoFont}
                                                                                 context:nil].size.height;

    // SETUP COVER IMAGE
    [self.issue getCoverWithCache:cache andBlock:^(UIImage *image) {
        [self.issueCover setBackgroundImage:image forState:UIControlStateNormal];
    }];

    CGFloat labelWidth = self.view.frame.size.width - ui.contentOffset - 60;
    
    // SETUP TITLE LABEL
    self.titleLabel.font          = titleFont;
    self.titleLabel.frame         = CGRectMake(ui.contentOffset, heightOffset, labelWidth, 60);
    self.titleLabel.numberOfLines = 3;
    self.titleLabel.text          = self.issue.title;
    [self.titleLabel sizeToFit];

    heightOffset = heightOffset + self.titleLabel.frame.size.height + 5;

    // SETUP INFO LABEL
    self.infoLabel.font          = infoFont;
    self.infoLabel.frame         = CGRectMake(ui.contentOffset, heightOffset, labelWidth, 60);
    self.infoLabel.numberOfLines = 3;
    self.infoLabel.text          = self.issue.info;
    [self.infoLabel sizeToFit];

    heightOffset = heightOffset + self.infoLabel.frame.size.height + 5;

    heightOffset = 130 + textLineheight + 10;

    // SETUP ACTION BUTTON
    NSString *status = [self.issue getStatus];
    if ([status isEqualToString:@"remote"] || [status isEqualToString:@"purchasable"] || [status isEqualToString:@"purchased"]) {
        self.actionButton.frame = CGRectMake(ui.contentOffset, heightOffset, 110, 30);
    } else if ([status isEqualToString:@"downloaded"] || [status isEqualToString:@"bundled"]) {
        self.actionButton.frame = CGRectMake(ui.contentOffset, heightOffset, 80, 30);
    }
    self.actionButton.titleLabel.font = actionFont;

    // SETUP ARCHIVE BUTTON
    self.archiveButton.frame = CGRectMake(ui.contentOffset + 80 + 10, heightOffset, 80, 30);
    self.archiveButton.titleLabel.font = archiveFont;

    // SETUP DOWN/LOADING SPINNER AND LABEL
    self.spinner.frame = CGRectMake(ui.contentOffset, heightOffset, 30, 30);
    self.loadingLabel.frame = CGRectMake(ui.contentOffset + self.spinner.frame.size.width + 10, heightOffset, 135, 30);
    self.loadingLabel.font = actionFont;

    heightOffset = heightOffset + self.loadingLabel.frame.size.height + 5;

    // SETUP PROGRESS BAR
    self.progressBar.frame = CGRectMake(ui.contentOffset, 136, labelWidth, 30);
}

- (void)preferredContentSizeChanged:(NSNotification*)notification {
    [self refreshContentWithCache:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)refresh {
    [self refresh:[self.issue getStatus]];
}

- (void)refresh:(NSString*)status {
    //NSLog(@"[BakerShelf] Shelf UI - Refreshing %@ item with status from <%@> to <%@>", self.issue.ID, self.currentStatus, status);
    if ([status isEqualToString:@"remote"]) {
        [self.actionButton setTitle:NSLocalizedString(@"FREE_TEXT", nil) forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.hidden  = NO;
        self.archiveButton.hidden = YES;
        self.progressBar.hidden   = YES;
        self.loadingLabel.hidden  = YES;
    } else if ([status isEqualToString:@"connecting"]) {
        NSLog(@"[BakerShelf] '%@' is Connecting...", self.issue.ID);
        [self.spinner startAnimating];

        self.actionButton.hidden  = YES;
        self.archiveButton.hidden = YES;
        self.progressBar.progress = 0;
        self.loadingLabel.text    = NSLocalizedString(@"CONNECTING_TEXT", nil);
        self.loadingLabel.hidden  = NO;
        self.progressBar.hidden   = YES;
    } else if ([status isEqualToString:@"downloading"]) {
        NSLog(@"[BakerShelf] '%@' is Downloading...", self.issue.ID);
        [self.spinner startAnimating];

        self.actionButton.hidden  = YES;
        self.archiveButton.hidden = YES;
        self.progressBar.progress = 0;
        self.loadingLabel.text    = NSLocalizedString(@"DOWNLOADING_TEXT", nil);
        self.loadingLabel.hidden  = NO;
        self.progressBar.hidden   = NO;
    } else if ([status isEqualToString:@"downloaded"]) {
        NSLog(@"[BakerShelf] '%@' is Ready to be Read.", self.issue.ID);
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.hidden  = NO;
        self.archiveButton.hidden = NO;
        self.loadingLabel.hidden  = YES;
        self.progressBar.hidden   = YES;
    } else if ([status isEqualToString:@"bundled"]) {
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.hidden  = NO;
        self.archiveButton.hidden = YES;
        self.loadingLabel.hidden  = YES;
        self.progressBar.hidden   = YES;
    } else if ([status isEqualToString:@"opening"]) {
        [self.spinner startAnimating];

        self.actionButton.hidden  = YES;
        self.archiveButton.hidden = YES;
        self.loadingLabel.text    = NSLocalizedString(@"OPENING_TEXT", nil);
        self.loadingLabel.hidden  = NO;
        self.progressBar.hidden   = YES;
    } else if ([status isEqualToString:@"purchasable"]) {
        [self.actionButton setTitle:self.issue.price forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.hidden  = NO;
        self.archiveButton.hidden = YES;
        self.progressBar.hidden   = YES;
        self.loadingLabel.hidden  = YES;
    } else if ([status isEqualToString:@"purchasing"]) {
        NSLog(@"[BakerShelf] '%@' is being Purchased...", self.issue.ID);
        [self.spinner startAnimating];

        self.loadingLabel.text = NSLocalizedString(@"BUYING_TEXT", nil);

        self.actionButton.hidden  = YES;
        self.archiveButton.hidden = YES;
        self.progressBar.hidden   = YES;
        self.loadingLabel.hidden  = NO;
    } else if ([status isEqualToString:@"purchased"]) {
        NSLog(@"[BakerShelf] '%@' is Purchased.", self.issue.ID);

        [self.actionButton setTitle:NSLocalizedString(@"ACTION_REMOTE_TEXT", nil) forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.hidden  = NO;
        self.archiveButton.hidden = YES;
        self.progressBar.hidden   = YES;
        self.loadingLabel.hidden  = YES;
    } else if ([status isEqualToString:@"unpriced"]) {
        [self.spinner startAnimating];

        self.loadingLabel.text = NSLocalizedString(@"RETRIEVING_TEXT", nil);

        self.actionButton.hidden  = YES;
        self.archiveButton.hidden = YES;
        self.progressBar.hidden   = YES;
        self.loadingLabel.hidden  = NO;
    }

    [self refreshContentWithCache:YES];

    self.currentStatus = status;
}

#pragma mark - Issue management

- (void)actionButtonPressed:(UIButton*)sender {
    NSString *status = [self.issue getStatus];
    if ([status isEqualToString:@"remote"] || [status isEqualToString:@"purchased"]) {
        if ([BKRSettings sharedSettings].isNewsstand) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerIssueDownload" object:self]; // -> Baker Analytics Event
            [self download];
        }
    } else if ([status isEqualToString:@"downloaded"] || [status isEqualToString:@"bundled"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerIssueOpen" object:self]; // -> Baker Analytics Event
        [self read];
    } else if ([status isEqualToString:@"downloading"]) {
        // TODO: assuming it is supported by NewsstandKit, implement a "Cancel" operation
    } else if ([status isEqualToString:@"purchasable"]) {
        if ([BKRSettings sharedSettings].isNewsstand) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerIssuePurchase" object:self]; // -> Baker Analytics Event
            [self buy];
        }
    }
}

- (void)download {
    [self.issue download];
}

- (void)buy {
    [self addPurchaseObserver:@selector(handleIssuePurchased:) name:@"notification_issue_purchased"];
    [self addPurchaseObserver:@selector(handleIssuePurchaseFailed:) name:@"notification_issue_purchase_failed"];

    if (![purchasesManager purchase:self.issue.productID]) {
        // Still retrieving SKProduct: delay purchase
        purchaseDelayed = YES;

        [self removePurchaseObserver:@"notification_issue_purchased"];
        [self removePurchaseObserver:@"notification_issue_purchase_failed"];

        [purchasesManager retrievePriceFor:self.issue.productID];

        self.issue.transientStatus = BakerIssueTransientStatusUnpriced;
        [self refresh];
    } else {
        self.issue.transientStatus = BakerIssueTransientStatusPurchasing;
        [self refresh];
    }
}

- (void)handleIssuePurchased:(NSNotification*)notification {
    SKPaymentTransaction *transaction = notification.userInfo[@"transaction"];

    if ([transaction.payment.productIdentifier isEqualToString:self.issue.productID]) {

        [self removePurchaseObserver:@"notification_issue_purchased"];
        [self removePurchaseObserver:@"notification_issue_purchase_failed"];

        [purchasesManager markAsPurchased:transaction.payment.productIdentifier];

        if ([purchasesManager finishTransaction:transaction]) {
            if (!transaction.originalTransaction) {
                // Do not show alert on restoring a transaction
                [BKRUtils showAlertWithTitle:NSLocalizedString(@"ISSUE_PURCHASE_SUCCESSFUL_TITLE", nil)
                                  message:[NSString stringWithFormat:NSLocalizedString(@"ISSUE_PURCHASE_SUCCESSFUL_MESSAGE", nil), self.issue.title]
                              buttonTitle:NSLocalizedString(@"ISSUE_PURCHASE_SUCCESSFUL_CLOSE", nil)];
            }
        } else {
            [BKRUtils showAlertWithTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_TITLE", nil)
                              message:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_CLOSE", nil)];
        }

        self.issue.transientStatus = BakerIssueTransientStatusNone;

        [purchasesManager retrievePurchasesFor:[NSSet setWithObject:self.issue.productID] withCallback:^(NSDictionary *purchases) {
            [self refresh];
        }];
    }
}

- (void)handleIssuePurchaseFailed:(NSNotification*)notification {
    SKPaymentTransaction *transaction = (notification.userInfo)[@"transaction"];

    if ([transaction.payment.productIdentifier isEqualToString:self.issue.productID]) {
        // Show an error, unless it was the user who cancelled the transaction
        if (transaction.error.code != SKErrorPaymentCancelled) {
            [BKRUtils showAlertWithTitle:NSLocalizedString(@"ISSUE_PURCHASE_FAILED_TITLE", nil)
                              message:[transaction.error localizedDescription]
                          buttonTitle:NSLocalizedString(@"ISSUE_PURCHASE_FAILED_CLOSE", nil)];
        }

        [self removePurchaseObserver:@"notification_issue_purchased"];
        [self removePurchaseObserver:@"notification_issue_purchase_failed"];

        self.issue.transientStatus = BakerIssueTransientStatusNone;
        [self refresh];
    }
}

- (void)handleIssueRestored:(NSNotification*)notification {
    SKPaymentTransaction *transaction = (notification.userInfo)[@"transaction"];

    if ([transaction.payment.productIdentifier isEqualToString:self.issue.productID]) {
        [purchasesManager markAsPurchased:transaction.payment.productIdentifier];

        if (![purchasesManager finishTransaction:transaction]) {
            NSLog(@"[BakerShelf] Could not confirm purchase restore with remote server for %@", transaction.payment.productIdentifier);
        }

        self.issue.transientStatus = BakerIssueTransientStatusNone;
        [self refresh];
    }
}

- (void)setPrice:(NSString*)price {
    self.issue.price = price;
    if (purchaseDelayed) {
        purchaseDelayed = NO;
        [self buy];
    } else {
        [self refresh];
    }
}

- (void)read {
    self.issue.transientStatus = BakerIssueTransientStatusOpening;
    [self refresh];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"read_issue_request" object:self];
}

#pragma mark - Newsstand download management

- (void)handleDownloadStarted:(NSNotification*)notification {
    [self refresh];
}

- (void)handleDownloadProgressing:(NSNotification*)notification {
    float bytesWritten = [(notification.userInfo)[@"totalBytesWritten"] floatValue];
    float bytesExpected = [(notification.userInfo)[@"expectedTotalBytes"] floatValue];

    if ([self.currentStatus isEqualToString:@"connecting"]) {
        self.issue.transientStatus = BakerIssueTransientStatusDownloading;
        [self refresh];
    }
    [self.progressBar setProgress:(bytesWritten / bytesExpected) animated:YES];
}

- (void)handleDownloadFinished:(NSNotification*)notification {
    self.issue.transientStatus = BakerIssueTransientStatusNone;
    [self refresh];
}

- (void)handleDownloadError:(NSNotification*)notification {
    [BKRUtils showAlertWithTitle:NSLocalizedString(@"DOWNLOAD_FAILED_TITLE", nil)
                      message:NSLocalizedString(@"DOWNLOAD_FAILED_MESSAGE", nil)
                  buttonTitle:NSLocalizedString(@"DOWNLOAD_FAILED_CLOSE", nil)];

    self.issue.transientStatus = BakerIssueTransientStatusNone;
    [self refresh];
}

- (void)handleUnzipError:(NSNotification*)notification {
    [BKRUtils showAlertWithTitle:NSLocalizedString(@"UNZIP_FAILED_TITLE", nil)
                      message:NSLocalizedString(@"UNZIP_FAILED_MESSAGE", nil)
                  buttonTitle:NSLocalizedString(@"UNZIP_FAILED_CLOSE", nil)];

    self.issue.transientStatus = BakerIssueTransientStatusNone;
    [self refresh];
}

#pragma mark - Newsstand archive management

- (void)archiveButtonPressed:(UIButton*)sender {
    UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ARCHIVE_ALERT_TITLE", nil)
                                                          message:NSLocalizedString(@"ARCHIVE_ALERT_MESSAGE", nil)
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"ARCHIVE_ALERT_BUTTON_CANCEL", nil)
                                                otherButtonTitles:NSLocalizedString(@"ARCHIVE_ALERT_BUTTON_OK", nil), nil
                                ];
    [updateAlert show];
}

- (void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerIssueArchive" object:self]; // -> Baker Analytics Event
        
        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        NKIssue *nkIssue = [nkLib issueWithName:self.issue.ID];
        NSString *name   = nkIssue.name;
        NSDate *date     = nkIssue.date;

        [nkLib removeIssue:nkIssue];

        nkIssue = [nkLib addIssueWithName:name date:date];
        self.issue.path = [[nkIssue contentURL] path];

        [self refresh];
    }
}

#pragma mark - Helper methods

- (void)addPurchaseObserver:(SEL)notificationSelector name:(NSString*)notificationName {
    if ([BKRSettings sharedSettings].isNewsstand) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:notificationSelector
                                                     name:notificationName
                                                   object:purchasesManager];
    }
}

- (void)removePurchaseObserver:(NSString*)notificationName {
    if ([BKRSettings sharedSettings].isNewsstand) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:notificationName
                                                      object:purchasesManager];
    }
}

- (void)addIssueObserver:(SEL)notificationSelector name:(NSString*)notificationName {
    if ([BKRSettings sharedSettings].isNewsstand) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:notificationSelector
                                                     name:notificationName
                                                   object:nil];
    }
}

+ (UI)getIssueContentMeasures {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UI iPad = {
            .cellPadding   = 30,
            .thumbWidth    = 135,
            .thumbHeight   = 180,
            .contentOffset = 184
        };
        return iPad;
    } else {
        UI iPhone = {
            .cellPadding   = 22,
            .thumbWidth    = 87,
            .thumbHeight   = 116,
            .contentOffset = 128
        };
        return iPhone;
    }
}

+ (int)getIssueCellHeight {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 240;
    } else {
        return 190;
    }
}

+ (CGSize)getIssueCellSizeForOrientation:(UIInterfaceOrientation)orientation {
    
    CGFloat screenWidth = [[UIScreen mainScreen] bkrWidthForOrientation:orientation];
    int cellHeight      = [BKRIssueViewController getIssueCellHeight];
    
    if (screenWidth > 700) {
        return CGSizeMake(screenWidth/2, cellHeight);
    } else {
        return CGSizeMake(screenWidth, cellHeight);
    }
    
    /*
    CGRect screenRect   = [UIScreen mainScreen].bounds;
    CGFloat screenWidth = screenRect.size.width;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake(screenWidth / 2, [IssueViewController getIssueCellHeight]);
        //return CGSizeMake((MIN(screenRect.size.width, screenRect.size.height) - 10) / 2, [IssueViewController getIssueCellHeight]);
    } else {
        if (screenWidth > 700) {
            return CGSizeMake((screenWidth - 10) / 2, [IssueViewController getIssueCellHeight]);
        } else {
            return CGSizeMake(MIN(screenRect.size.width, screenRect.size.height) - 10, [IssueViewController getIssueCellHeight]);
        }
    }
    */
    
}

@end
