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
	UIWebView *viewTwo;
	
	int currentView;
}

@property (nonatomic, retain) UIWebView *viewOne;
@property (nonatomic, retain) UIWebView *viewTwo;

- (void)loadNewPage:(UIWebView *)target
		   filename:(NSString *)filename
			   type:(NSString *)type
				dir:(NSString *)dir;

@end
