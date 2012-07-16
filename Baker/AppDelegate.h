//
//  AppDelegate.h
//  Baker
//
//  Created by Alessandro Morandi on 10/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "InterceptorWindow.h"
#import "ShelfViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) InterceptorWindow *window;
@property (strong, nonatomic) ShelfViewController *rootViewController;
@property (strong, nonatomic) UINavigationController *rootNavigationController;

@end
