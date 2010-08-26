//
//  BakerAppDelegate.h
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright Xmas 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface BakerAppDelegate : NSObject <UIApplicationDelegate> {
    
	UIWindow *window;
	RootViewController *rootViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) RootViewController *rootViewController;

@end

