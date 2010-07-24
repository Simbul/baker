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
	
	UISwipeGestureRecognizer *swipeLeft;
	UISwipeGestureRecognizer *swipeRight;
	
	int currentView;
}

@property (nonatomic, retain) UIWebView *viewOne;
@property (nonatomic, retain) UIWebView *viewTwo;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeLeft;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeRight;

- (void)loadNewPage:(UIWebView *)target
		   filename:(NSString *)filename
			   type:(NSString *)type
				dir:(NSString *)dir;

- (void)swipePage:(UISwipeGestureRecognizer *)sender;

@end
