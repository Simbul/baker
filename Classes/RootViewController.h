//
//  RootViewController.h
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright 2010 Xmas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController {
		
	CGRect frameLeft;
	CGRect frameCenter;
	CGRect frameRight;
	
	UIWebView *prevPage;
	UIWebView *currPage;
	UIWebView *nextPage;
	
	UISwipeGestureRecognizer *swipeLeft;
	UISwipeGestureRecognizer *swipeRight;
	
	int currentPageNumber;
	BOOL currentPageIsLast;
	BOOL animating;	
}

@property (nonatomic, retain) UIWebView *prevPage;
@property (nonatomic, retain) UIWebView *currPage;
@property (nonatomic, retain) UIWebView *nextPage;

@property (nonatomic, retain) UISwipeGestureRecognizer *swipeLeft;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeRight;

@property int currentPageNumber;

- (BOOL)loadNewPage:(UIWebView *)target
		   filename:(NSString *)filename
			   type:(NSString *)type
				dir:(NSString *)dir;

- (void)swipePage:(UISwipeGestureRecognizer *)sender;

- (void)gotoPrevPage;
- (void)gotoNextPage;

- (void)animateHorizontalSlide:(NSString *)name
							dx:(int) dx
					 firstView:(UIWebView *)firstView
					secondView:(UIWebView *)secondView;

- (void)swipeAnimationDidStop:(NSString *)animationID
					 finished:(BOOL)flag;

@end
