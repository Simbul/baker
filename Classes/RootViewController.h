//
//  RootViewController.h
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright 2010 Xmas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController {
	UISwipeGestureRecognizer *swipeLeft;
	UISwipeGestureRecognizer *swipeRight;
	
	BOOL currentPageIsLast;
	
	UIWebView *prevPage;
	UIWebView *currPage;
	UIWebView *nextPage;
	
	int currentPageNumber;
	
	CGRect frameLeft;
	CGRect frameCenter;
	CGRect frameRight;
}

@property (nonatomic, retain) UIWebView *prevPage;
@property (nonatomic, retain) UIWebView *currPage;
@property (nonatomic, retain) UIWebView *nextPage;

@property (nonatomic, retain) UISwipeGestureRecognizer *swipeLeft;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeRight;

@property (nonatomic) int currentPageNumber;
@property (nonatomic) BOOL currentPageIsLast;
@property (nonatomic) CGRect frameLeft;
@property (nonatomic) CGRect frameCenter;
@property (nonatomic) CGRect frameRight;

- (BOOL)loadNewPage:(UIWebView *)target
		   filename:(NSString *)filename
			   type:(NSString *)type
				dir:(NSString *)dir;

- (void)swipePage:(UISwipeGestureRecognizer *)sender;

- (void)gotoNextPage;
- (void)slideLeft;
- (void)animateHorizontalSlide:(NSString *)name
							dx:(int) dx
					 firstView:(UIWebView *)firstView
					secondView:(UIWebView *)secondView;
- (void)swipeAnimationDidStop:(NSString *)animationID
					 finished:(BOOL)flag;


@end
