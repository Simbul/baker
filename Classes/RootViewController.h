//
//  RootViewController.h
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2010, Davide Casali, Marco Colombo, Alessandro Morandi
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
//  Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to 
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


#import <UIKit/UIKit.h>

@class TapHandler;

@interface RootViewController : UIViewController < UIWebViewDelegate, UIScrollViewDelegate > {
	
	NSArray *pages;
	
	UIScrollView *scrollView;
	NSMutableArray *pageSpinners;
	
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
	int currentPageMaxScroll;
	BOOL currentPageFirstLoading;
	BOOL currentPageIsDelayingLoading;
	BOOL discardNextStatusBarToggle;
}

@property (nonatomic, retain) NSArray *pages;

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *pageSpinners;

@property (nonatomic, retain) UIWebView *prevPage;
@property (nonatomic, retain) UIWebView *currPage;
@property (nonatomic, retain) UIWebView *nextPage;

@property (nonatomic, retain) UISwipeGestureRecognizer *swipeLeft;
@property (nonatomic, retain) UISwipeGestureRecognizer *swipeRight;

@property int currentPageNumber;

// ****** LOADING
- (BOOL)changePage:(int)page;
- (void)gotoPageDelayer;
- (void)gotoPage;
- (void)initPageNumbersForPages:(int)count;
- (BOOL)loadSlot:(int)slot withPage:(int)page;
- (BOOL)loadWebView:(UIWebView*)webview withPage:(int)page;

// ****** SCROLLVIEW
- (CGRect)frameForPage:(int)page;
- (void)spinnerForPage:(int)page isAnimating:(BOOL)isAnimating;

// ****** WEBVIEW
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating;

// ****** GESTURES
//- (void)swipePage:(UISwipeGestureRecognizer *)sender;
- (void)onTouch:(NSNotification *)notification;
- (void)userDidSingleTap:(UITouch *)touch;
- (void)userDidScroll:(UITouch *)touch;

// ****** SCROLLING
- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating;
- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating;
- (void)scrollPage:(UIWebView *)webView to:(NSString *)offset animating:(BOOL)animating;

// ****** STATUS BAR
- (void)toggleStatusBar;
- (void)hideStatusBar;
- (void)hideStatusBarDiscardingToggle:(BOOL)discardToggle;

// ****** DOWNLOAD BOOKS
- (void)downloadBook:(NSNotification *)notification;

@end
