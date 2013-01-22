//
//  ShelfViewController.m
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

#import "ShelfViewController.h"
#import "ShelfManager.h"
#import "UICustomNavigationBar.h"
#import "Constants.h"

#import "BakerViewController.h"
#import "IssueViewController.h"

#import "JSONKit.h"
#import "NSData+Base64.h"
#import "NSString+Extensions.h"

@implementation ShelfViewController

@synthesize issues;
@synthesize issueViewControllers;
@synthesize gridView;
@synthesize issuesManager;
@synthesize subscribeButton;
@synthesize refreshButton;
@synthesize shelfStatus;
@synthesize subscriptionsActionSheet;
@synthesize supportedOrientation;
#ifdef BAKER_NEWSSTAND
@synthesize purchasesManager;
#endif

#pragma mark - Init

- (id)init
{
    self = [super init];
    if (self) {
        self.issues = [ShelfManager localBooksList];
        self.shelfStatus = [[[ShelfStatus alloc] init] retain];
        self.supportedOrientation = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    }
    return self;
}
- (id)initWithBooks:(NSArray *)currentBooks
{
    self = [super init];
    if (self) {
        self.issues = currentBooks;

        #ifdef BAKER_NEWSSTAND
        self.purchasesManager = [PurchasesManager sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleProductsRetrieved:)
                                                     name:@"notification_products_retrieved"
                                                   object:self.purchasesManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleProductsRequestFailed:)
                                                     name:@"notification_products_request_failed"
                                                   object:self.purchasesManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFreeSubscriptionPurchased:)
                                                     name:@"notification_free_subscription_purchased"
                                                   object:self.purchasesManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFreeSubscriptionFailed:)
                                                     name:@"notification_free_subscription_failed"
                                                   object:self.purchasesManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleFreeSubscriptionRestored:)
                                                     name:@"notification_free_subscription_restored"
                                                   object:self.purchasesManager];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRestoreFinished:)
                                                     name:@"notification_restore_finished"
                                                   object:self.purchasesManager];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:purchasesManager];
        #endif

        self.shelfStatus = [[[ShelfStatus alloc] init] retain];
        [shelfStatus load];
        for (BakerIssue *issue in self.issues) {
            issue.price = [shelfStatus priceFor:issue.productID];
        }

        NSMutableArray *controllers = [NSMutableArray array];
        for (BakerIssue *issue in self.issues) {
            IssueViewController *controller = [self createIssueViewControllerWithIssue:issue];
            [controllers addObject:controller];
        }
        self.issueViewControllers = [NSMutableArray arrayWithArray:controllers];
        self.supportedOrientation = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    [gridView release];
    [issueViewControllers release];
    [issues release];
    [subscribeButton release];
    [refreshButton release];
    [shelfStatus release];
    [subscriptionsActionSheet release];
    [supportedOrientation release];
    [self.blockingProgressView release];
    #ifdef BAKER_NEWSSTAND
    [purchasesManager release];
    #endif

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"SHELF_NAVIGATION_TITLE", nil);

    self.background = [[UIImageView alloc] init];

    self.gridView = [[AQGridView alloc] init];
    self.gridView.dataSource = self;
    self.gridView.delegate = self;
    self.gridView.backgroundColor = [UIColor clearColor];

    [self.view addSubview:self.background];
    [self.view addSubview:self.gridView];

    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
    [self.gridView reloadData];

    #ifdef BAKER_NEWSSTAND
    self.refreshButton = [[[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                       target:self
                                       action:@selector(handleRefresh:)]
                                      autorelease];

    self.subscribeButton = [[[UIBarButtonItem alloc]
                             initWithTitle: NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil)
                             style:UIBarButtonItemStylePlain
                             target:self
                             action:@selector(handleSubscribeButtonPressed:)]
                            autorelease];

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
    [spinner release];

    if ([PRODUCT_ID_FREE_SUBSCRIPTION length] > 0) {
        self.subscribeButton.enabled = NO;
        [purchasesManager retrievePriceFor:PRODUCT_ID_FREE_SUBSCRIPTION];
    }

    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.refreshButton, self.subscribeButton, nil];
    #endif
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];

    #ifdef BAKER_NEWSSTAND
    [self handleRefresh:nil];
    #endif

    for (IssueViewController *controller in self.issueViewControllers) {
        controller.issue.transientStatus = BakerIssueTransientStatusNone;
        [controller refresh];
    }
}
- (NSInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [supportedOrientation indexOfObject:[NSString stringFromInterfaceOrientation:interfaceOrientation]] != NSNotFound;
}
- (BOOL)shouldAutorotate
{
    return YES;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    int width  = 0;
    int height = 0;

    NSString *image = @"";
    CGSize size = [UIScreen mainScreen].bounds.size;

    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        width  = size.width;
        height = size.height - 64;
        image  = @"shelf-bg-portrait";
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        width  = size.height;
        height = size.width - 64;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            height = height + 12;
        }
        image  = @"shelf-bg-landscape";
    }

    if (size.height == 568) {
        image = [NSString stringWithFormat:@"%@-568h.png", image];
    } else {
        image = [NSString stringWithFormat:@"%@.png", image];
    }

    int bannerHeight = [ShelfViewController getBannerHeight];

    self.background.frame = CGRectMake(0, 0, width, height);
    self.background.image = [UIImage imageNamed:image];

    self.gridView.frame = CGRectMake(0, bannerHeight, width, height - bannerHeight);
}
- (IssueViewController *)createIssueViewControllerWithIssue:(BakerIssue *)issue
{
    IssueViewController *controller = [[[IssueViewController alloc] initWithBakerIssue:issue] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReadIssue:) name:@"read_issue_request" object:controller];
    return controller;
}

#pragma mark - Shelf data source

- (NSUInteger)numberOfItemsInGridView:(AQGridView *)aGridView
{
    return [issueViewControllers count];
}
- (AQGridViewCell *)gridView:(AQGridView *)aGridView cellForItemAtIndex:(NSUInteger)index
{
    CGSize cellSize = [IssueViewController getIssueCellSize];
    CGRect cellFrame = CGRectMake(0, 0, cellSize.width, cellSize.height);

    static NSString *cellIdentifier = @"cellIdentifier";
    AQGridViewCell *cell = (AQGridViewCell *)[self.gridView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[AQGridViewCell alloc] initWithFrame:cellFrame reuseIdentifier:cellIdentifier] autorelease];
		cell.selectionStyle = AQGridViewCellSelectionStyleNone;

        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.backgroundColor = [UIColor clearColor];
	}

    IssueViewController *controller = [self.issueViewControllers objectAtIndex:index];
    UIView *removableIssueView = [cell.contentView viewWithTag:42];
    if (removableIssueView) {
        [removableIssueView removeFromSuperview];
    }
    [cell.contentView addSubview:controller.view];

    return cell;
}
- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView
{
    return [IssueViewController getIssueCellSize];
}

#ifdef BAKER_NEWSSTAND
- (void)handleRefresh:(NSNotification *)notification {
    [self setrefreshButtonEnabled:NO];

    if (!self.issuesManager) {
        self.issuesManager = [[[IssuesManager alloc] initWithURL:NEWSSTAND_MANIFEST_URL] autorelease];
    }
    if([self.issuesManager refresh]) {
        self.issues = issuesManager.issues;

        [self.issues enumerateObjectsUsingBlock:^(id object, NSUInteger idx, BOOL *stop) {
            // NOTE: this block changes the issueViewController array while looping

            IssueViewController *existingIvc = nil;
            if (idx < [self.issueViewControllers count]) {
                existingIvc = [self.issueViewControllers objectAtIndex:idx];
            }

            BakerIssue *issue = (BakerIssue*)object;
            if (!existingIvc || ![[existingIvc issue].ID isEqualToString:issue.ID]) {
                IssueViewController *ivc = [self createIssueViewControllerWithIssue:issue];
                [self.issueViewControllers insertObject:ivc atIndex:idx];
                [self.gridView insertItemsAtIndices:[NSIndexSet indexSetWithIndex:idx] withAnimation:AQGridViewItemAnimationNone];
            }
        }];

        [self.purchasesManager retrievePricesFor:self.issuesManager.productIDs];
    }
    else{
        UIAlertView *connAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_TITLE", nil)
                                                            message:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_MESSAGE", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"INTERNET_CONNECTION_UNAVAILABLE_CLOSE", nil)
                                                  otherButtonTitles:nil];
        [connAlert show];
        [connAlert release];
    }
    [self setrefreshButtonEnabled:YES];
}

#pragma mark - Store Kit

- (void)handleSubscribeButtonPressed:(NSNotification *)notification {
    if (subscriptionsActionSheet.visible) {
        [subscriptionsActionSheet dismissWithClickedButtonIndex:(subscriptionsActionSheet.numberOfButtons - 1) animated:YES];
    } else {
        [self.subscriptionsActionSheet release];
        self.subscriptionsActionSheet = [self buildSubscriptionsActionSheet];
        [subscriptionsActionSheet showFromBarButtonItem:self.subscribeButton animated:YES];
    }
}

- (UIActionSheet *)buildSubscriptionsActionSheet {
    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil)
                                                      delegate:self
                                             cancelButtonTitle:nil
                                        destructiveButtonTitle:nil
                                             otherButtonTitles: nil];
    NSMutableArray *actions = [NSMutableArray array];
    if ([PRODUCT_ID_FREE_SUBSCRIPTION length] > 0 && ![purchasesManager isMarkedAsPurchased:PRODUCT_ID_FREE_SUBSCRIPTION]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_FREE", nil)];
        [actions addObject:PRODUCT_ID_FREE_SUBSCRIPTION];
    }

    [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_RESTORE", nil)];
    [actions addObject:@"restore"];
    [sheet addButtonWithTitle:NSLocalizedString(@"SUBSCRIPTIONS_SHEET_CLOSE", nil)];
    [actions addObject:@"cancel"];

    self.subscriptionsActionSheetActions = actions;

    sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
    return sheet;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == subscriptionsActionSheet) {
        NSString *action = [self.subscriptionsActionSheetActions objectAtIndex:buttonIndex];
        if ([action isEqualToString:@"cancel"]) {
            NSLog(@"Action sheet: cancel");
            [self setSubscribeButtonEnabled:YES];
        } else if ([action isEqualToString:@"restore"]) {
            [self.blockingProgressView show];
            [purchasesManager restore];
            NSLog(@"Action sheet: restore");
        } else {
            NSLog(@"Action sheet: %@", action);
            [self setSubscribeButtonEnabled:NO];
            [purchasesManager purchase:action];
        }
    }
}

- (void)handleRestoreFinished:(NSNotification *)notification {
    [self.blockingProgressView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)handleFreeSubscription:(NSNotification *)notification {
    [self setSubscribeButtonEnabled:NO];
    [purchasesManager purchase:PRODUCT_ID_FREE_SUBSCRIPTION];
}

- (void)handleFreeSubscriptionPurchased:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_TITLE", nil)
                                                    message:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_MESSAGE", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"SUBSCRIPTION_SUCCESSFUL_CLOSE", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];

    [purchasesManager markAsPurchased:PRODUCT_ID_FREE_SUBSCRIPTION];

    [self setSubscribeButtonEnabled:YES];

    [purchasesManager finishTransaction:transaction];
}

- (void)handleFreeSubscriptionFailed:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    // Show an error, unless it was the user who cancelled the transaction
    if (transaction.error.code != SKErrorPaymentCancelled) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_TITLE", nil)
                                                        message:[transaction.error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"SUBSCRIPTION_FAILED_CLOSE", nil)
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }

    [self setSubscribeButtonEnabled:YES];
}

- (void)handleFreeSubscriptionRestored:(NSNotification *)notification {
    SKPaymentTransaction *transaction = [notification.userInfo objectForKey:@"transaction"];

    [purchasesManager markAsPurchased:PRODUCT_ID_FREE_SUBSCRIPTION];

    [purchasesManager finishTransaction:transaction];
}

- (void)handleProductsRetrieved:(NSNotification *)notification {
    NSSet *ids = [notification.userInfo objectForKey:@"ids"];

    if (ids.count == 1 && [[ids anyObject] isEqualToString:PRODUCT_ID_FREE_SUBSCRIPTION]) {
        // Free subscription retrieved
        [self setSubscribeButtonEnabled:YES];
    } else {
        // Issues retrieved
        NSString *price;
        for (IssueViewController *controller in self.issueViewControllers) {
            price = [purchasesManager priceFor:controller.issue.productID];
            if (price) {
                [controller setPrice:price];
                [shelfStatus setPrice:price for:controller.issue.productID];
            }
        }
        [shelfStatus save];
    }
}

- (void)handleProductsRequestFailed:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:@"error"];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_TITLE", nil)
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"PRODUCTS_REQUEST_FAILED_CLOSE", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#endif

#pragma mark - Navigation management

- (void)gridView:(AQGridView *)myGridView didSelectItemAtIndex:(NSUInteger)index
{
    [myGridView deselectItemAtIndex:index animated:NO];
}
- (void)readIssue:(BakerIssue *)issue
{
    BakerBook *book = nil;
    NSString *status = [issue getStatus];

    #ifdef BAKER_NEWSSTAND
    if (status == @"opening") {
        book = [[[BakerBook alloc] initWithBookPath:issue.path bundled:NO] autorelease];
        [self pushViewControllerWithBook:book];
    }
    #else
    if (status == @"bundled") {
        book = [issue bakerBook];
        [self pushViewControllerWithBook:book];
    }
    #endif
}
- (void)handleReadIssue:(NSNotification *)notification
{
    IssueViewController *controller = notification.object;
    [self readIssue:controller.issue];
}
-(void)pushViewControllerWithBook:(BakerBook *)book
{
    BakerViewController *bakerViewController = [[BakerViewController alloc] initWithBook:book];
    [self.navigationController pushViewController:bakerViewController animated:YES];
    [bakerViewController release];
}

#pragma mark - Buttons management

-(void)setrefreshButtonEnabled:(BOOL)enabled {
    self.refreshButton.enabled = enabled;
}

-(void)setSubscribeButtonEnabled:(BOOL)enabled {
    self.subscribeButton.enabled = enabled;
    if (enabled) {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_TEXT", nil);
    } else {
        self.subscribeButton.title = NSLocalizedString(@"SUBSCRIBE_BUTTON_DISABLED_TEXT", nil);
    }
}

#pragma mark - Helper methods

+ (int)getBannerHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 240;
    } else {
        return 104;
    }
}

@end
