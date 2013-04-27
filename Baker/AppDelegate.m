//
//  AppDelegate.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
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

#import "AppDelegate.h"
#import "UICustomNavigationController.h"
#import "UICustomNavigationBar.h"
#import "IssuesManager.h"
#import "BakerAPI.h"

#import "BakerViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize rootViewController;
@synthesize rootNavigationController;

+ (void)initialize {
    // Set user agent (the only problem is that we can't modify the User-Agent later in the program)
    // We use a more browser-like User-Agent in order to allow browser detection scripts to run (like Tumult Hype).
    NSDictionary *userAgent = [[NSDictionary alloc] initWithObjectsAndKeys:@"Mozilla/5.0 (compatible; BakerFramework) AppleWebKit/533.00+ (KHTML, like Gecko) Mobile", @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userAgent];
    [userAgent release];
}

- (void)dealloc
{
    [window release];
    [rootViewController release];
    [rootNavigationController release];

    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    #ifdef BAKER_NEWSSTAND

    NSLog(@"====== Baker Newsstand Mode enabled ======");
    [BakerAPI generateUUIDOnce];

    // Let the device know we want to handle Newsstand push notifications
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeNewsstandContentAvailability];

    // Check if the app is runnig in response to a notification
    NSDictionary *payload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (payload) {
        NSDictionary *aps = [payload objectForKey:@"aps"];
        if (aps && [aps objectForKey:@"content-available"]) {

            __block UIBackgroundTaskIdentifier backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            }];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self applicationWillHandleNewsstandNotificationOfContent:[payload objectForKey:@"content-name"]];
                [application endBackgroundTask:backgroundTask];
                backgroundTask = UIBackgroundTaskInvalid;
            });
        }
    }

    self.rootViewController = [[[ShelfViewController alloc] init] autorelease];

    #else

    NSLog(@"====== Baker Standalone Mode enabled ======");
    NSArray *books = [IssuesManager localBooksList];
    if ([books count] == 1) {
        self.rootViewController = [[[BakerViewController alloc] initWithBook:[[books objectAtIndex:0] bakerBook]] autorelease];
    } else  {
        self.rootViewController = [[[ShelfViewController alloc] initWithBooks:books] autorelease];
    }

    #endif

    self.rootNavigationController = [[[UICustomNavigationController alloc] initWithRootViewController:self.rootViewController] autorelease];
    UICustomNavigationBar *navigationBar = (UICustomNavigationBar *)self.rootNavigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"navigation-bar-bg.png"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setTintColor:[UIColor clearColor]];

    self.window = [[[InterceptorWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];

    self.window.rootViewController = self.rootNavigationController;
    [self.window makeKeyAndVisible];

    return YES;
}

#ifdef BAKER_NEWSSTAND
- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *apnsToken = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    apnsToken = [apnsToken stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSLog(@"[AppDelegate] My token (as NSData) is: %@", deviceToken);
    NSLog(@"[AppDelegate] My token (as NSString) is: %@", apnsToken);

    [[NSUserDefaults standardUserDefaults] setObject:apnsToken forKey:@"apns_token"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    BakerAPI *api = [BakerAPI sharedInstance];
    [api postAPNSToken:apnsToken];
}
#endif

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"[AppDelegate] Push Notification - Device Token, review: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    #ifdef BAKER_NEWSSTAND
    NSDictionary *aps = [userInfo objectForKey:@"aps"];
    if (aps && [aps objectForKey:@"content-available"]) {
        [self applicationWillHandleNewsstandNotificationOfContent:[userInfo objectForKey:@"content-name"]];
    }
    #endif
}
- (void)applicationWillHandleNewsstandNotificationOfContent:(NSString *)contentName
{
    #ifdef BAKER_NEWSSTAND
    IssuesManager *issuesManager = [IssuesManager sharedInstance];
    [issuesManager refresh];

    if (contentName) {
        for (BakerIssue *issue in issuesManager.issues) {
            if ([issue.ID isEqualToString:contentName]) {
                [issue download];
                break;
            }
        }
    } else {
        BakerIssue *targetIssue = [issuesManager.issues objectAtIndex:0];
        [targetIssue download];
    }
    #endif
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationWillResignActiveNotification" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    #ifdef BAKER_NEWSSTAND
    // Everything that happened while the application was opened can be considered as "seen"
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    #endif
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    #ifdef BAKER_NEWSSTAND
    // Opening the application means all new items can be considered as "seen".
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    #endif
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
