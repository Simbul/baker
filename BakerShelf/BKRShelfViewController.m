//
//  ShelfViewController.m
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

#import "BKRShelfViewController.h"
#import "BKRCustomNavigationBar.h"

#import "BKRBookViewController.h"
#import "BKRIssueViewController.h"
#import "BKRShelfHeaderView.h"
#import "BKRShelfViewLayout.h"
#import "BKRSettings.h"

#import "NSData+BakerExtensions.h"
#import "NSString+BakerExtensions.h"
#import "BKRUtils.h"

#import "MBProgressHUD.h"

@interface BKRShelfViewController ()

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;

@end

@implementation BKRShelfViewController

#pragma mark - Init

- (id)init {
    self = [super init];
    if (self) {
        if ([BKRSettings sharedSettings].isNewsstand) {
            purchasesManager = [BKRPurchasesManager sharedInstance];
            [self addPurchaseObserver:@selector(handleProductsRetrieved:)
                                 name:@"notification_products_retrieved"];
            [self addPurchaseObserver:@selector(handleProductsRequestFailed:)
                                 name:@"notification_products_request_failed"];
            [self addPurchaseObserver:@selector(handleSubscriptionPurchased:)
                                 name:@"notification_subscription_purchased"];
            [self addPurchaseObserver:@selector(handleSubscriptionFailed:)
                                 name:@"notification_subscription_failed"];
            [self addPurchaseObserver:@selector(handleSubscriptionRestored:)
                                 name:@"notification_subscription_restored"];
            [self addPurchaseObserver:@selector(handleRestoreFailed:)
                                 name:@"notification_restore_failed"];
            [self addPurchaseObserver:@selector(handleMultipleRestores:)
                                 name:@"notification_multiple_restores"];
            [self addPurchaseObserver:@selector(handleRestoredIssueNotRecognised:)
                                 name:@"notification_restored_issue_not_recognised"];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(receiveBookProtocolNotification:)
                                                         name:@"notification_book_protocol"
                                                       object:nil];

            [[SKPaymentQueue defaultQueue] addTransactionObserver:purchasesManager];
        }

        api                       = [BKRBakerAPI sharedInstance];
        issuesManager             = [BKRIssuesManager sharedInstance];
        notRecognisedTransactions = [[NSMutableArray alloc] init];

        _shelfStatus = [[BKRShelfStatus alloc] init];
        _issueViewControllers = [[NSMutableArray alloc] init];
        _supportedOrientation = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
        _bookToBeProcessed    = nil;

        if ([BKRSettings sharedSettings].isNewsstand) {
            [self handleRefresh:nil];
        }
    }
    return self;
}

- (id)initWithBooks:(NSArray*)currentBooks {
    self = [self init];
    if (self) {
        self.issues = currentBooks;

        NSMutableArray *controllers = [NSMutableArray array];
        for (BKRIssue *issue in self.issues) {
            BKRIssueViewController *controller = [self createIssueViewControllerWithIssue:issue];
            [controllers addObject:controller];
        }
        self.issueViewControllers = [NSMutableArray arrayWithArray:controllers];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"SHELF_NAVIGATION_TITLE", nil);
    
    self.layout = [[BKRShelfViewLayout alloc] initWithSticky:[[BKRSettings sharedSettings].issuesShelfOptions[@"headerSticky"] boolValue]
                                                     stretch:[[BKRSettings sharedSettings].issuesShelfOptions[@"headerStretch"] boolValue]];

    [self.layout setHeaderReferenceSize:[self getBannerSize]];
    self.layout.minimumInteritemSpacing = 0;
    self.layout.minimumLineSpacing      = 0;
    
    self.gridView = [[UICollectionView alloc] initWithFrame:self.view.frame collectionViewLayout:self.layout];
    self.gridView.dataSource       = self;
    self.gridView.delegate         = self;
    self.gridView.backgroundColor  = [UIColor clearColor];
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    [self.gridView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellIdentifier"];
    [self.gridView registerClass:[BKRShelfHeaderView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"headerIdentifier"];
    
    NSString *backgroundFillStyle = [BKRSettings sharedSettings].issuesShelfOptions[@"backgroundFillStyle"];
    if([backgroundFillStyle isEqualToString:@"Gradient"]) {
        self.gradientLayer = [BKRUtils gradientLayerFromHexString:[BKRSettings sharedSettings].issuesShelfOptions[@"backgroundFillGradientStart"]
                                                                  toHexString:[BKRSettings sharedSettings].issuesShelfOptions[@"backgroundFillGradientStop"]];
        self.gradientLayer.frame = self.gridView.bounds;
        self.gridView.backgroundColor = [UIColor clearColor];
        self.gridView.backgroundView = [[UIView alloc] init];
        [self.gridView.backgroundView.layer insertSublayer:self.gradientLayer atIndex:0];
        self.gridView.backgroundColor = [BKRUtils colorWithHexString:[BKRSettings sharedSettings].issuesShelfOptions[@"backgroundFillColor"]];
    }else if([backgroundFillStyle isEqualToString:@"Image"]) {
        UIImage *backgroundImage = [UIImage imageNamed:@"shelf-background"];
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
        self.gridView.backgroundView = backgroundView;
    }else if([backgroundFillStyle isEqualToString:@"Pattern"]) {
        self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"shelf-background"]];
    }else if([backgroundFillStyle isEqualToString:@"Color"]) {
        self.gridView.backgroundColor = [BKRUtils colorWithHexString:[BKRSettings sharedSettings].issuesShelfOptions[@"backgroundFillColor"]];
    }
    
    [self.view addSubview:self.gridView];

    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    [self.gridView reloadData];

    if ([BKRSettings sharedSettings].isNewsstand) {
        self.refreshButton = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                           target:self
                                           action:@selector(handleRefresh:)];

        self.subscribeButton = [[UIBarButtonItem alloc]
                                 initWithTitle: NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil)
                                 style:UIBarButtonItemStylePlain
                                 target:self
                                 action:@selector(handleSubscribeButtonPressed:)];
        
        self.categoryItem = [[BKRCategoryFilterItem alloc] initWithCategories:issuesManager.categories delegate:self];

        self.blockingProgressView = [[UIAlertView alloc]
                                     initWithTitle:@"Processing..."
                                     message:@"\n"
                                     delegate:nil
                                     cancelButtonTitle:nil
                                     otherButtonTitles:nil];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.center = CGPointMake(139.5, 75.5); // .5 so it doesn't blur
        [self.blockingProgressView addSubview:spinner];
        [spinner startAnimating];

        NSMutableSet *subscriptions = [NSMutableSet setWithArray:[BKRSettings sharedSettings].autoRenewableSubscriptionProductIds];
        if ([[BKRSettings sharedSettings].freeSubscriptionProductId length] > 0 && ![purchasesManager isPurchased:[BKRSettings sharedSettings].freeSubscriptionProductId]) {
            [subscriptions addObject:[BKRSettings sharedSettings].freeSubscriptionProductId];
        }
        [purchasesManager retrievePricesFor:subscriptions andEnableFailureNotifications:NO];

    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];

    for (BKRIssueViewController *controller in self.issueViewControllers) {
        controller.issue.transientStatus = BakerIssueTransientStatusNone;
        [controller refresh];
    }

    if ([BKRSettings sharedSettings].isNewsstand) {

        NSMutableArray *buttonItems = [NSMutableArray arrayWithObject:self.refreshButton];
        if ([purchasesManager hasSubscriptions] || [issuesManager hasProductIDs]) {
            [buttonItems addObject:self.subscribeButton];
        }
        self.navigationItem.leftBarButtonItems = buttonItems;
        
        // Remove limbo transactions
        // take current payment queue
        SKPaymentQueue* currentQueue = [SKPaymentQueue defaultQueue];
        // finish ALL transactions in queue
        [currentQueue.transactions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [currentQueue finishTransaction:(SKPaymentTransaction*)obj];
        }];
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:purchasesManager];
    }
    
    // Add info button
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self action:@selector(handleInfoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.infoItem = [[UIBarButtonItem alloc] initWithCustomView:infoButton];

    // Remove file info.html if you don't want the info button to be added to the shelf navigation bar
    NSString *infoPath = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html" inDirectory:@"info"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
        self.navigationItem.rightBarButtonItem = self.infoItem;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.bookToBeProcessed) {
        [self handleBookToBeProcessed];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [self.supportedOrientation indexOfObject:[NSString bkrStringFromInterfaceOrientation:interfaceOrientation]] != NSNotFound;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    realInterfaceOrientation = toInterfaceOrientation;
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

    // Update label widths
    [self.issueViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [(BKRIssueViewController*)obj refreshContentWithCache:NO];
    }];
}

- (void)viewDidLayoutSubviews {
    // Update gradient background (if set)
    if(self.gradientLayer) {
        [self.gradientLayer setFrame:self.gridView.bounds];
    }
    
    // Update header size
    [self.layout setHeaderReferenceSize:[self getBannerSize]];
    
    // Invalidate layout
    [self.layout invalidateLayout];
    
}

- (BKRIssueViewController*)createIssueViewControllerWithIssue:(BKRIssue*)issue {
    BKRIssueViewController *controller = [[BKRIssueViewController alloc] initWithBakerIssue:issue];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReadIssue:) name:@"read_issue_request" object:controller];
    return controller;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

#pragma mark - Shelf data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.issueViewControllers count];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    CGSize cellSize = [BKRIssueViewController getIssueCellSizeForOrientation:self.interfaceOrientation];
    CGRect cellFrame = CGRectMake(0, 0, cellSize.width, cellSize.height);

    static NSString *cellIdentifier = @"cellIdentifier";
    UICollectionViewCell* cell = [self.gridView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
	if (cell == nil) {
		UICollectionViewCell* cell = [[UICollectionViewCell alloc] initWithFrame:cellFrame];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor             = [UIColor clearColor];
	}
    
    BKRIssueViewController *controller = (self.issueViewControllers)[indexPath.row];
    UIView *removableIssueView = [cell.contentView viewWithTag:42];
    if (removableIssueView) {
        [removableIssueView removeFromSuperview];
    }
    [cell.contentView addSubview:controller.view];

    return cell;
}


- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [BKRIssueViewController getIssueCellSizeForOrientation:realInterfaceOrientation];
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    if (!self.headerView) {
        self.headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"headerIdentifier" forIndexPath:indexPath];
    }
    return self.headerView;
}

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return [self getBannerSize];
}

- (void)handleRefresh:(NSNotification*)notification {
    [self setrefreshButtonEnabled:NO];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Loading", @"");
    
    [issuesManager refresh:^(BOOL status) {
        if(status) {

            // Set dropdown categories
            self.categoryItem.categories = issuesManager.categories;
            
            // Show / Hide category button
            if(issuesManager.categories.count == 0) {
                self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.infoItem, nil];
            }else{
                self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.infoItem, self.categoryItem, nil];
            }

            // Set issues
            self.issues = issuesManager.issues;
            
            // Refresh issue list
            [self refreshIssueList];
            
        } else {
            [BKRUtils showAlertWithTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_TITLE", nil)
                              message:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_CLOSE", nil)];
            
            [self setrefreshButtonEnabled:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            });
            
        }
    }];
}

- (BKRIssueViewController*)issueViewControllerWithID:(NSString*)ID {
    __block BKRIssueViewController* foundController = nil;
    [self.issueViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BKRIssueViewController *ivc = (BKRIssueViewController*)obj;
        if ([ivc.issue.ID isEqualToString:ID]) {
            foundController = ivc;
            *stop = YES;
        }
    }];
    return foundController;
}

- (BKRIssue*)bakerIssueWithID:(NSString*)ID {
    __block BKRIssue *foundIssue = nil;
    [self.issues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BKRIssue *issue = (BKRIssue*)obj;
        if ([issue.ID isEqualToString:ID]) {
            foundIssue = issue;
            *stop = YES;
        }
    }];
    return foundIssue;
}

- (void)refreshIssueList {
    
    // Filter issues
    __block NSMutableArray *filteredIssues = [NSMutableArray array];
    [issuesManager.issues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        BKRIssue *issue = (BKRIssue *)obj;
        
        // Test if category exists
        if([self.categoryItem.title isEqualToString:NSLocalizedString(@"ALL_CATEGORIES_TITLE", nil)] || [issue.categories containsObject:self.categoryItem.title]) {
            [filteredIssues addObject:issue];
        }
    }];
    
    // Assign filtered issues
    self.issues = [filteredIssues copy];
    
    [self.shelfStatus load];
    for (BKRIssue *issue in self.issues) {
        issue.price = [self.shelfStatus priceFor:issue.productID];
    }
    
    void (^updateIssues)() = ^{
        // Step 1: remove controllers for issues that no longer exist
        __weak NSMutableArray *discardedControllers = [NSMutableArray array];
        [self.issueViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            BKRIssueViewController *ivc = (BKRIssueViewController*)obj;
            
            if (![self bakerIssueWithID:ivc.issue.ID]) {
                [discardedControllers addObject:ivc];
                [self.gridView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:idx inSection:0]]];
            }
        }];
        [self.issueViewControllers removeObjectsInArray:discardedControllers];
        
        // Step 2: add controllers for issues that did not yet exist (and refresh the ones that do exist)
        [self.issues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            // NOTE: this block changes the issueViewController array while looping
            BKRIssue *issue = (BKRIssue*)obj;
            
            BKRIssueViewController *existingIvc = [self issueViewControllerWithID:issue.ID];
            
            if (existingIvc) {
                existingIvc.issue = issue;
            } else {
                BKRIssueViewController *newIvc = [self createIssueViewControllerWithIssue:issue];
                [self.issueViewControllers insertObject:newIvc atIndex:idx];
                [self.gridView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:idx inSection:0]] ];
            }
        }];
        
        [self.gridView reloadData];
    };
    
    // When first launched, the grid is not initialised, so we can't
    // call in the "batch update" method of the grid view
    if (self.gridView) {
        [self.gridView performBatchUpdates:updateIssues completion:nil];
    }
    else {
        updateIssues();
    }
    
    [purchasesManager retrievePurchasesFor:[issuesManager productIDs] withCallback:^(NSDictionary *purchases) {
        // List of purchases has been returned, so we can refresh all issues
        [self.issueViewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [(BKRIssueViewController*)obj refreshWithCache:NO];
        }];
        [self setrefreshButtonEnabled:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        });
    }];
    
    [purchasesManager retrievePricesFor:issuesManager.productIDs andEnableFailureNotifications:NO];
}

#pragma mark - Store Kit
- (void)handleSubscribeButtonPressed:(NSNotification*)notification {
    if (self.subscriptionsActionSheet.visible) {
        [self.subscriptionsActionSheet dismissWithClickedButtonIndex:(self.subscriptionsActionSheet.numberOfButtons - 1) animated:YES];
    } else {
        self.subscriptionsActionSheet = [self buildSubscriptionsActionSheet];
        [self.subscriptionsActionSheet showFromBarButtonItem:self.subscribeButton animated:YES];
    }
}

- (UIActionSheet*)buildSubscriptionsActionSheet {
    NSString *title;
    if ([api canGetPurchasesJSON]) {
        if (purchasesManager.subscribed) {
            title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_SUBSCRIBED", nil);
        } else {
            title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_NOT_SUBSCRIBED", nil);
        }
    } else {
        title = NSLocalizedString(@"SUBSCRIPTIONS_SHEET_GENERIC", nil);
    }

    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:title
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles: nil];
    NSMutableArray *actions = [NSMutableArray array];

    if (!purchasesManager.subscribed) {
        if ([[BKRSettings sharedSettings].freeSubscriptionProductId length] > 0 && ![purchasesManager isPurchased:[BKRSettings sharedSettings].freeSubscriptionProductId]) {
            [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_FREE", nil)];
            [actions addObject:[BKRSettings sharedSettings].freeSubscriptionProductId];
        }

        for (NSString *productId in [BKRSettings sharedSettings].autoRenewableSubscriptionProductIds) {
            NSString *title = [purchasesManager displayTitleFor:productId];
            NSString *price = [purchasesManager priceFor:productId];
            if (price) {
                [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ %@", title, price]];
                [actions addObject:productId];
            }
        }
    }

    if ([issuesManager hasProductIDs]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_RESTORE", nil)];
        [actions addObject:@"restore"];
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_CLOSE", nil)];
    [actions addObject:@"cancel"];

    self.subscriptionsActionSheetActions = actions;

    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    return sheet;
}

- (void) actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.subscriptionsActionSheet) {
        NSString *action = (self.subscriptionsActionSheetActions)[buttonIndex];
        if ([action isEqualToString:@"cancel"]) {
            NSLog(@"Action sheet: cancel");
            [self setSubscribeButtonEnabled:YES];
        } else if ([action isEqualToString:@"restore"]) {
            [self.blockingProgressView show];
            [purchasesManager restore];
            NSLog(@"Action sheet: restore");
        } else {
            NSLog(@"Action sheet: %@", action);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerSubscriptionPurchase" object:self]; // -> Baker Analytics Event
            [self setSubscribeButtonEnabled:NO];
            if (![purchasesManager purchase:action]){
                [BKRUtils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                                  message:nil
                              buttonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)];
                [self setSubscribeButtonEnabled:YES];
            }
        }
    }
}

- (void)handleRestoreFailed:(NSNotification*)notification {
    NSError *error = (notification.userInfo)[@"error"];
    [BKRUtils showAlertWithTitle:NSLocalizedString(@"RESTORE_FAILED_TITLE", nil)
                      message:[error localizedDescription]
                  buttonTitle:NSLocalizedString(@"RESTORE_FAILED_CLOSE", nil)];

    [self.blockingProgressView dismissWithClickedButtonIndex:0 animated:YES];

}

- (void)handleMultipleRestores:(NSNotification*)notification {
    if ([BKRSettings sharedSettings].isNewsstand) {

        if ([notRecognisedTransactions count] > 0) {
            NSSet *productIDs = [NSSet setWithArray:[[notRecognisedTransactions valueForKey:@"payment"] valueForKey:@"productIdentifier"]];
            NSString *productsList = [[productIDs allObjects] componentsJoinedByString:@", "];

            [BKRUtils showAlertWithTitle:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_TITLE", nil)
                              message:[NSString stringWithFormat:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_MESSAGE", nil), productsList]
                          buttonTitle:NSLocalizedString(@"RESTORED_ISSUE_NOT_RECOGNISED_CLOSE", nil)];

            for (SKPaymentTransaction *transaction in notRecognisedTransactions) {
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
            [notRecognisedTransactions removeAllObjects];
        }
    }

    [self handleRefresh:nil];
    [self.blockingProgressView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)handleRestoredIssueNotRecognised:(NSNotification*)notification {
    SKPaymentTransaction *transaction = (notification.userInfo)[@"transaction"];
    [notRecognisedTransactions addObject:transaction];
}

// TODO: this can probably be removed
- (void)handleSubscription:(NSNotification*)notification {
    [self setSubscribeButtonEnabled:NO];
    [purchasesManager purchase:[BKRSettings sharedSettings].freeSubscriptionProductId];
}

- (void)handleSubscriptionPurchased:(NSNotification*)notification {
    SKPaymentTransaction *transaction = (notification.userInfo)[@"transaction"];

    [purchasesManager markAsPurchased:transaction.payment.productIdentifier];
    [self setSubscribeButtonEnabled:YES];

    if ([purchasesManager finishTransaction:transaction]) {
        if (!purchasesManager.subscribed) {
            [BKRUtils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_TITLE", nil)
                              message:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_MESSAGE", nil)
                          buttonTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_CLOSE", nil)];

            [self handleRefresh:nil];
        }
    } else {
        [BKRUtils showAlertWithTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_TITLE", nil)
                          message:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_MESSAGE", nil)
                      buttonTitle:NSLocalizedString(@"TRANSACTION_RECORDING_FAILED_CLOSE", nil)];
    }
}

- (void)handleSubscriptionFailed:(NSNotification*)notification {
    SKPaymentTransaction *transaction = (notification.userInfo)[@"transaction"];

    // Show an error, unless it was the user who cancelled the transaction
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [BKRUtils showAlertWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                          message:[transaction.error localizedDescription]
                      buttonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)];
    }

    [self setSubscribeButtonEnabled:YES];
}

- (void)handleSubscriptionRestored:(NSNotification*)notification {
    SKPaymentTransaction *transaction = (notification.userInfo)[@"transaction"];

    [purchasesManager markAsPurchased:transaction.payment.productIdentifier];

    if (![purchasesManager finishTransaction:transaction]) {
        NSLog(@"Could not confirm purchase restore with remote server for %@", transaction.payment.productIdentifier);
    }
}

- (void)handleProductsRetrieved:(NSNotification*)notification {
    NSSet *ids = (notification.userInfo)[@"ids"];
    BOOL issuesRetrieved = NO;

    for (NSString *productId in ids) {
        if ([productId isEqualToString:[BKRSettings sharedSettings].freeSubscriptionProductId]) {
            // ID is for a free subscription
            [self setSubscribeButtonEnabled:YES];
        } else if ([[BKRSettings sharedSettings].autoRenewableSubscriptionProductIds containsObject:productId]) {
            // ID is for an auto-renewable subscription
            [self setSubscribeButtonEnabled:YES];
        } else {
            // ID is for an issue
            issuesRetrieved = YES;
        }
    }

    if (issuesRetrieved) {
        NSString *price;
        for (BKRIssueViewController *controller in self.issueViewControllers) {
            price = [purchasesManager priceFor:controller.issue.productID];
            if (price) {
                [controller setPrice:price];
                [self.shelfStatus setPrice:price for:controller.issue.productID];
            }
        }
        [self.shelfStatus save];
    }
}

- (void)handleProductsRequestFailed:(NSNotification*)notification {
    NSError *error = (notification.userInfo)[@"error"];

    [BKRUtils showAlertWithTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_TITLE", nil)
                      message:[error localizedDescription]
                  buttonTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_CLOSE", nil)];
}

#pragma mark - Navigation management

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)readIssue:(BKRIssue*)issue
{
    BKRBook *book = nil;
    NSString *status = [issue getStatus];

    if ([BKRSettings sharedSettings].isNewsstand) {
        if ([status isEqual:@"opening"]) {
            book = [[BKRBook alloc] initWithBookPath:issue.path bundled:NO];
            if (book) {
                [self pushViewControllerWithBook:book];
            } else {
                NSLog(@"[ERROR] Book %@ could not be initialized", issue.ID);
                issue.transientStatus = BakerIssueTransientStatusNone;
                // Let's refresh everything as it's easier. This is an edge case anyway ;)
                for (BKRIssueViewController *controller in self.issueViewControllers) {
                    [controller refresh];
                }
                [BKRUtils showAlertWithTitle:NSLocalizedString(@"ISSUE_OPENING_FAILED_TITLE", nil)
                                  message:NSLocalizedString(@"ISSUE_OPENING_FAILED_MESSAGE", nil)
                              buttonTitle:NSLocalizedString(@"ISSUE_OPENING_FAILED_CLOSE", nil)];
            }
        }
    } else {
        if ([status isEqual:@"bundled"]) {
            book = [issue bakerBook];
            [self pushViewControllerWithBook:book];
        }
    }
}
- (void)handleReadIssue:(NSNotification*)notification
{
    BKRIssueViewController *controller = notification.object;
    [self readIssue:controller.issue];
}
- (void)receiveBookProtocolNotification:(NSNotification*)notification
{
    self.bookToBeProcessed = (notification.userInfo)[@"ID"];
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (void)handleBookToBeProcessed
{
    for (BKRIssueViewController *issueViewController in self.issueViewControllers) {
        if ([issueViewController.issue.ID isEqualToString:self.bookToBeProcessed]) {
            [issueViewController actionButtonPressed:nil];
            break;
        }
    }

    self.bookToBeProcessed = nil;
}
- (void)pushViewControllerWithBook:(BKRBook*)book
{
    BKRBookViewController *bakerViewController = [[BKRBookViewController alloc] initWithBook:book];
    [self.navigationController pushViewController:bakerViewController animated:YES];
}

#pragma mark - Buttons management

- (void)setrefreshButtonEnabled:(BOOL)enabled {
    self.refreshButton.enabled = enabled;
}

- (void)setSubscribeButtonEnabled:(BOOL)enabled {
    self.subscribeButton.enabled = enabled;
    if (enabled) {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil);
    } else {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_DISABLED_TEXT", nil);
    }
}

- (void)webViewDidFinishLoad:(UIWebView*)webView {
    // Inject user_id
    [BKRUtils webView:webView dispatchHTMLEvent:@"init" withParams:@{@"user_id": [BKRBakerAPI UUID],
                                                                @"app_id": [BKRUtils appID]}];
}

- (void)handleInfoButtonPressed:(id)sender {
    
    // If the button is pressed when the info box is open, close it
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (infoPopover.isPopoverVisible) {
            [infoPopover dismissPopoverAnimated:YES];
            return;
        }
    }
    
    // Prepare new view
    UIViewController *popoverContent = [[UIViewController alloc] init];
    UIWebView *popoverView = [[UIWebView alloc] init];
    
    popoverView.backgroundColor = [UIColor whiteColor];
    popoverView.delegate        = self;
    popoverContent.view         = popoverView;
    
    // Load HTML file
    NSString *path = [[NSBundle mainBundle] pathForResource:@"info" ofType:@"html" inDirectory:@"info"];
    [popoverView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    
    // Open view
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // On iPad use the UIPopoverController
        infoPopover = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
        [infoPopover presentPopoverFromBarButtonItem:self.infoItem
                            permittedArrowDirections:UIPopoverArrowDirectionUp
                                            animated:YES];
    } else {
        // On iPhone push the view controller to the navigation
        [self.navigationController pushViewController:popoverContent animated:YES];
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

- (int)getBannerHeight {
    return [[BKRSettings sharedSettings].issuesShelfOptions[[NSString stringWithFormat:@"headerHeight%@%@", [self getDeviceString], [self getOrientationString]]] intValue];
}

- (CGSize)getBannerSize {
    return CGSizeMake(self.view.frame.size.width, [self getBannerHeight]);
}

- (NSString *)getDeviceString {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? @"Pad" : @"Phone";
}

- (NSString *)getOrientationString {
    return UIInterfaceOrientationIsLandscape(self.interfaceOrientation) ? @"Landscape" : @"Portrait";
}

#pragma mark - BKRCategoryFilterItemDelegate

- (void)categoryFilterItem:(BKRCategoryFilterItem *)categoryFilterItem clickedAction:(NSString *)action {
    [self refreshIssueList];
}

@end
