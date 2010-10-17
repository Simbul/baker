//
//  RootViewController.h
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright 2010 Xmas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TapHandler;

@interface RootViewController : UIViewController < UIWebViewDelegate > {
		
	CGRect frameLeft;
	CGRect frameCenter;
	CGRect frameRight;
	
	UIWebView *prevPage;
	UIWebView *currPage;
	UIWebView *nextPage;
	
	UISwipeGestureRecognizer *swipeLeft;
	UISwipeGestureRecognizer *swipeRight;
	
	TapHandler *rightTapHandler;
	TapHandler *leftTapHandler;
	TapHandler *downTapHandler;
	TapHandler *upTapHandler;

	int totalPages;
	int currentPageNumber;
	BOOL currentPageFirstLoading;
	BOOL currentPageIsAnimating;	
}

@property (nonatomic, retain) UIWebView *prevPage;
@property (nonatomic, retain) UIWebView *currPage;
@property (nonatomic, retain) UIWebView *nextPage;

@property (nonatomic, retain) UISwipeGestureRecognizer *swipeLeft;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeRight;

@property int totalPages;
@property int currentPageNumber;

// ****** LOADING
- (BOOL)loadSlot:(int)slot withPage:(int)page;
- (BOOL)loadWebView:(UIWebView*)webview withPage:(int)page;
- (void)preloadWebViewsWithPage:(int)page;

// ****** WEBVIEW
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating;

// ****** GESTURES
- (void)swipePage:(UISwipeGestureRecognizer *)sender;
- (void)onTouch:(NSNotification *)notification;

// ****** SCROLLING
- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating;
- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating;
- (void)scrollPage:(UIWebView *)webView to:(NSString *)offset animating:(BOOL)animating;

// ****** PAGING
- (void)gotoPage:(int)pageNumber;
- (void)animateHorizontalSlide:(NSString *)name
							dx:(int) dx
					 firstView:(UIWebView *)firstView
					secondView:(UIWebView *)secondView;
- (void)animationDidStop:(NSString *)animationID
					 finished:(BOOL)flag;

@end
