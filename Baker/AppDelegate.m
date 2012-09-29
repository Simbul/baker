//
//  AppDelegate.m
//  Baker
//
//  Created by Alessandro Morandi on 10/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"

#import "AppDelegate.h"
#import "UICustomNavigationController.h"
#import "UICustomNavigationBar.h"

#import "ShelfManager.h"

#ifdef BAKER_NEWSSTAND
#import "IssuesManager.h"
#endif

#import "BakerViewController.h"

@implementation AppDelegate

@synthesize window;
@synthesize rootViewController;
@synthesize rootNavigationController;

- (void)dealloc
{
    [window release];
    [rootViewController release];
    [rootNavigationController release];
    
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[InterceptorWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.window.backgroundColor = [UIColor whiteColor];

    #ifdef BAKER_NEWSSTAND
    
    NSLog(@"====== Newsstand is enabled ======");
    IssuesManager *issuesManager = [[IssuesManager alloc] initWithURL:NEWSSTAND_MANIFEST_URL];
    [issuesManager refresh];
    NSArray *books = issuesManager.issues;
    self.rootViewController = [[[ShelfViewController alloc] initWithBooks:books] autorelease];
    
    #else
    
    NSLog(@"====== Newsstand is not enabled ======");
    NSArray *books = [ShelfManager localBooksList];
    if ([books count] == 1) {
        self.rootViewController = [[[BakerViewController alloc] initWithBook:[books objectAtIndex:0]] autorelease];
    } else  {
        self.rootViewController = [[[ShelfViewController alloc] initWithBooks:books] autorelease];
    }
    
    #endif

    self.rootNavigationController = [[UICustomNavigationController alloc] initWithRootViewController:self.rootViewController];
    UICustomNavigationBar *navigationBar = (UICustomNavigationBar *)self.rootNavigationController.navigationBar;
    [navigationBar setBackgroundImage:[UIImage imageNamed:@"navigation-bar-bg.png"] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setTintColor:[UIColor clearColor]];

    [self.window addSubview:rootNavigationController.view];
    [self.window makeKeyAndVisible];
    
    return YES;
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
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
