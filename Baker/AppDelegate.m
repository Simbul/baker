//
//  AppDelegate.m
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

#import "Constants.h"
#import "UIConstants.h"

#import "AppDelegate.h"
#import "UICustomNavigationController.h"
#import "UICustomNavigationBar.h"
#import "IssuesManager.h"
#import "BakerAPI.h"
#import "UIColor+Extensions.h"
#import "Utils.h"

#import "BakerViewController.h"
#import "BakerAnalyticsEvents.h"

#pragma mark - Initialization

@implementation AppDelegate

+ (void)initialize {
    // Set user agent (the only problem is that we can't modify the User-Agent later in the program)
    // We use a more browser-like User-Agent in order to allow browser detection scripts to run (like Tumult Hype).
    NSDictionary *userAgent = @{@"UserAgent": @"Mozilla/5.0 (compatible; BakerFramework) AppleWebKit/533.00+ (KHTML, like Gecko) Mobile"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:userAgent];
}

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {

#ifdef BAKER_NEWSSTAND
    [self configureNewsstandApp:application options:launchOptions];
#else
    [self configureStandAloneApp:application options:launchOptions];
#endif

    self.rootNavigationController = [[UICustomNavigationController alloc] initWithRootViewController:self.rootViewController];

    [self configureNavigationBar];
    [self configureAnalytics];

    self.window = [[InterceptorWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor    = [UIColor whiteColor];
    self.window.rootViewController = self.rootNavigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)configureNewsstandApp:(UIApplication*)application options:(NSDictionary*)launchOptions {
    
    NSLog(@"====== Baker Newsstand Mode enabled ======");
    [BakerAPI generateUUIDOnce];
    
    // Let the device know we want to handle Newsstand push notifications
    [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeNewsstandContentAvailability|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
    
#ifdef DEBUG
    // For debug only... so that you can download multiple issues per day during development
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NKDontThrottleNewsstandContentNotifications"];
    [[NSUserDefaults standardUserDefaults] synchronize];
#endif
    
    // Check if the app is runnig in response to a notification
    NSDictionary *payload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (payload) {
        NSDictionary *aps = payload[@"aps"];
        if (aps && aps[@"content-available"]) {
            
            __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            }];
            
            // Credit where credit is due. This semaphore solution found here:
            // http://stackoverflow.com/a/4326754/2998
            dispatch_semaphore_t sema = NULL;
            sema = dispatch_semaphore_create(0);
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self applicationWillHandleNewsstandNotificationOfContent:payload[@"content-name"]];
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
    }
    
    self.rootViewController = [[ShelfViewController alloc] init];

}

- (void)configureStandAloneApp:(UIApplication*)application options:(NSDictionary*)launchOptions {
    
    NSLog(@"====== Baker Standalone Mode enabled ======");
    NSArray *books = [IssuesManager localBooksList];
    if (books.count == 1) {
        BakerBook *book = [books[0] bakerBook];
        self.rootViewController = [[BakerViewController alloc] initWithBook:book];
    } else  {
        self.rootViewController = [[ShelfViewController alloc] initWithBooks:books];
    }

}

- (void)configureNavigationBar {
    UICustomNavigationBar *navigationBar = (UICustomNavigationBar*)self.rootNavigationController.navigationBar;
    navigationBar.tintColor           = [UIColor colorWithHexString:ISSUES_ACTION_BUTTON_BACKGROUND_COLOR];
    navigationBar.barTintColor        = [UIColor colorWithHexString:@"ffffff"];
    navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor colorWithHexString:@"000000"]};
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"navigation-bar-bg"] forBarMetrics:UIBarMetricsDefault];
}

- (void)configureAnalytics {
    [BakerAnalyticsEvents sharedInstance]; // Initialization
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BakerApplicationStart" object:self]; // -> Baker Analytics Event
}

#pragma mark - Push Notifications

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    NSLog(@"[AppDelegate] Push Notification - Device Token, review: %@", error);
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
#ifdef BAKER_NEWSSTAND
    NSString *apnsToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    apnsToken = [apnsToken stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSLog(@"[AppDelegate] My token (as NSData) is: %@", deviceToken);
    NSLog(@"[AppDelegate] My token (as NSString) is: %@", apnsToken);

    [[NSUserDefaults standardUserDefaults] setObject:apnsToken forKey:@"apns_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    BakerAPI *api = [BakerAPI sharedInstance];
    [api postAPNSToken:apnsToken];
#endif
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo {
#ifdef BAKER_NEWSSTAND
    NSDictionary *aps = userInfo[@"aps"];
    if (aps && aps[@"content-available"]) {
        [self applicationWillHandleNewsstandNotificationOfContent:userInfo[@"content-name"]];
    }
#endif
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo fetchCompletionHandler:(void(^)(UIBackgroundFetchResult result))handler {
#ifdef BAKER_NEWSSTAND
    NSDictionary *aps = userInfo[@"aps"];
    if (aps && aps[@"content-available"]) {
        [self applicationWillHandleNewsstandNotificationOfContent:userInfo[@"content-name"]];
    }
#endif
}

- (void)applicationWillHandleNewsstandNotificationOfContent:(NSString*)contentName {
#ifdef BAKER_NEWSSTAND
    IssuesManager *issuesManager = [IssuesManager sharedInstance];
    PurchasesManager *purchasesManager = [PurchasesManager sharedInstance];
    __block BakerIssue *targetIssue = nil;

    [issuesManager refresh:^(BOOL status) {
        if (contentName) {
            for (BakerIssue *issue in issuesManager.issues) {
                if ([issue.ID isEqualToString:contentName]) {
                    targetIssue = issue;
                    break;
                }
            }
        } else {
            targetIssue = (issuesManager.issues)[0];
        }

        [purchasesManager retrievePurchasesFor:issuesManager.productIDs withCallback:^(NSDictionary *_purchases) {

            NSString *targetStatus = [targetIssue getStatus];
            NSLog(@"[AppDelegate] Push Notification - Target status: %@", targetStatus);

            if ([targetStatus isEqualToString:@"remote"] || [targetStatus isEqualToString:@"purchased"]) {
                [targetIssue download];
            } else if ([targetStatus isEqualToString:@"purchasable"] || [targetStatus isEqualToString:@"unpriced"]) {
                NSLog(@"[AppDelegate] Push Notification - You are not entitled to download issue '%@', issue not purchased yet", targetIssue.ID);
            } else if (![targetStatus isEqualToString:@"remote"]) {
                NSLog(@"[AppDelegate] Push Notification - Issue '%@' in download or already downloaded", targetIssue.ID);
            }
        }];
    }];
#endif
}

#pragma mark - Application Lifecycle

- (void)applicationWillResignActive:(UIApplication*)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationWillResignActiveNotification" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
#ifdef BAKER_NEWSSTAND
    // Everything that happened while the application was opened can be considered as "seen"
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
#endif
}

- (void)applicationDidBecomeActive:(UIApplication*)application {
#ifdef BAKER_NEWSSTAND
    // Opening the application means all new items can be considered as "seen".
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
#endif
}

@end
