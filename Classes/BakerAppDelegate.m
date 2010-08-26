//
//  BakerAppDelegate.m
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright Xmas 2010. All rights reserved.
//

#import "BakerAppDelegate.h"
#import "RootViewController.h"

@implementation BakerAppDelegate

@synthesize window;
@synthesize rootViewController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
	self.rootViewController = [[RootViewController alloc] initWithNibName:@"RootViewController" bundle:[NSBundle mainBundle]];
	[window addSubview:[rootViewController view]];
	
    [window makeKeyAndVisible];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
	// Saving last page viewed index
	NSString *lastPageViewed = [NSString stringWithFormat:@"%d", rootViewController.currentPageNumber];	
	NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];	
	[userDefs setObject:lastPageViewed forKey:@"lastPageViewed"];
	
	NSLog(@"Saved last page viewed: %@", lastPageViewed);
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

- (void)dealloc {
    
	[rootViewController release];
	[window release];
    [super dealloc];
}


@end
