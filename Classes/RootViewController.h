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


#import <UIKit/UIKit.h>

@class Downloader;

@interface RootViewController : UIViewController < UIWebViewDelegate, UIScrollViewDelegate > {
	
	CGRect screenBounds;
	
	NSString *documentsBookPath;
	NSString *bundleBookPath;
	
	NSMutableArray *pages;
	NSString *pageNameFromURL;
	NSString *anchorFromURL;
	
	UIScrollView *scrollView;
	NSMutableArray *pageSpinners;
	
	UIWebView *prevPage;
	UIWebView *currPage;
	UIWebView *nextPage;
	
	CGRect upTapArea;
	CGRect downTapArea;
	CGRect leftTapArea;
	CGRect rightTapArea;

	int totalPages;
    int lastPageNumber;
	int currentPageNumber;
	
    int pageWidth;
	int pageHeight;
    int currentPageHeight;
	
    int tapNumber;
    int stackedScrollingAnimations;
    
	BOOL currentPageFirstLoading;
	BOOL currentPageIsDelayingLoading;
	BOOL discardNextStatusBarToggle;
	
	NSString *URLDownload;
	Downloader *downloader;
	
	UIAlertView *feedbackAlert;
}

@property (nonatomic, retain) NSString *documentsBookPath;
@property (nonatomic, retain) NSString *bundleBookPath;

@property (nonatomic, retain) NSMutableArray *pages;
@property (nonatomic, retain) NSString *pageNameFromURL;
@property (nonatomic, retain) NSString *anchorFromURL;

@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSMutableArray *pageSpinners;

@property (nonatomic, retain) UIWebView *currPage;
@property (nonatomic, retain) UIWebView *prevPage;
@property (nonatomic, retain) UIWebView *nextPage;

@property int tapNumber;
@property int lastPageNumber;
@property int currentPageNumber;

@property (nonatomic, retain) NSString *URLDownload;

// ****** INIT
- (void)setupWebView:(UIWebView *)webView;
- (void)checkPageSize;
- (void)setPageSize:(NSString *)orientation;
- (void)initBook:(NSString *)path;

// ****** LOADING
- (BOOL)changePage:(int)page;
- (void)gotoPageDelayer;
- (void)gotoPage;
- (void)initPageNumbersForPages:(int)count;
- (void)loadSlot:(int)slot withPage:(int)page;
- (BOOL)loadWebView:(UIWebView*)webview withPage:(int)page;

// ****** SCROLLVIEW
- (CGRect)frameForPage:(int)page;
- (void)spinnerForPage:(int)page isAnimating:(BOOL)isAnimating;
- (void)resetScrollView;

// ****** WEBVIEW
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating;
- (void)revealWebView:(UIWebView *)webView;

// ****** GESTURES
- (void)userDidTap:(UITouch *)touch;
- (void)userDidScroll:(UITouch *)touch;

// ****** PAGE SCROLLING
- (void)getPageHeight;
- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating;
- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating;
- (void)scrollPage:(UIWebView *)webView to:(NSString *)offset animating:(BOOL)animating;
- (void)handleAnchor:(BOOL)animating;

// ****** STATUS BAR
- (void)toggleStatusBar;
- (void)hideStatusBar;
- (void)hideStatusBarDiscardingToggle:(BOOL)discardToggle;

// ****** DOWNLOAD NEW BOOKS
- (void)downloadBook:(NSNotification *)notification;
- (void)startDownloadRequest;
- (void)handleDownloadResult:(NSNotification *)notification;
- (void)manageDownloadData:(NSData *)data;

@end
