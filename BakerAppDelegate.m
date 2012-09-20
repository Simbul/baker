//
//  BakerAppDelegate.m
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2010-2011, Davide Casali, Marco Colombo, Alessandro Morandi
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


#import "BakerAppDelegate.h"
#import "Baker/BakerViewController.h"
#import "Baker/InterceptorWindow.h"

@implementation BakerAppDelegate

@synthesize window;
@synthesize rootViewController;

#pragma mark -
#pragma mark Application lifecycle

// Set user agent (the only problem is that we can't modify the User-Agent later in the program)
+ (void)initialize {
    NSDictionary *userAgent = [[NSDictionary alloc] initWithObjectsAndKeys:@"BakerFramework", @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userAgent];
    [userAgent release];
}

// IOS 3 BUG
// IF "(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions"
// THEN "(BOOL) application:(UIApplication*)application handleOpenURL:(NSURL*)url" is never called
// check http://stackoverflow.com/questions/3612460/lauching-app-with-url-via-uiapplicationdelegates-handleopenurl-working-under-i for hints
//- (void)applicationDidFinishLaunching:(UIApplication *)application {    
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Disable Shake to undo
    application.applicationSupportsShakeToEdit = NO;
    
    // Create the controller for the root view
    self.rootViewController = [[[BakerViewController alloc] initWithBookPath:[[NSBundle mainBundle] pathForResource:@"book" ofType:nil]] autorelease];
    
    // Create the application window
    self.window = [[[InterceptorWindow alloc] initWithFrame:[[UIScreen mainScreen]bounds]] autorelease];
    window.backgroundColor = [UIColor whiteColor];
    
    // Add the root view to the application window
    self.window.rootViewController = self.rootViewController;
    [window makeKeyAndVisible];
    
    NSString *reqSysVer = @"3.2";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedDescending && [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey] != nil) {
        NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
        [self application:application handleOpenURL:url];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url {
    
    NSString *URLString = [url absoluteString];
    NSLog(@"handleOpenURL -> %@", URLString);
    
    // STOP IF: url || URLString is nil
    if (!url || !URLString)
        return NO;
    
    // STOP IF: not my scheme
    if (![[url scheme] isEqualToString:@"book"])
        return NO;
    
    NSLog(@"HPub scheme found! -> %@", [url scheme]);
    
    NSArray *URLSections = [URLString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    NSString *URLDownload = [@"http:" stringByAppendingString:[URLSections objectAtIndex:1]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadNotification" object:URLDownload];
    
    return YES;
}
- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    [self saveLastPageReference];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive.
     */
}
- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Sent when the main button is pressed in iOS < 4
     */
    
    [self saveLastPageReference];
}

- (void)saveLastPageReference {
    
    NSDictionary *bookStatus = [rootViewController bookCurrentStatus];
    NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
    
    [userDefs setObject:[bookStatus objectForKey:@"lastPageViewed"] forKey:@"lastPageViewed"];
    [userDefs setObject:[bookStatus objectForKey:@"lastScrollIndex"] forKey:@"lastScrollIndex"];
    
    [userDefs synchronize];
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
