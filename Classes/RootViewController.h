//
//  RootViewController.h
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright 2010 Xmas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController {

	UIWebView *viewOne;
}

@property (nonatomic, retain) UIWebView *viewOne;

- (void)loadNewPage:(UIWebView *)target
		   filename:(NSString *)filename
			   type:(NSString *)type
				dir:(NSString *)dir;

@end
