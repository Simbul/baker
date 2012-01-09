//
//  RootViewController.h
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2010-2011, Davide Casali, Marco Colombo, Alessandro Morandi
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
#import <MessageUI/MessageUI.h>
#import "IndexViewController.h"
#import "Properties.h"


@class Downloader;

@interface RootViewController : UIViewController <UIWebViewDelegate, UIScrollViewDelegate, MFMailComposeViewControllerDelegate> {
	
	CGRect screenBounds;
	
	NSString *documentsBookPath;
    NSString *bundleBookPath;
    NSString *defaultScreeshotsPath;
    NSString *cachedScreenshotsPath;
    
    NSString *availableOrientation;
    NSString *renderingType;
	
	NSMutableArray *pages;
    NSMutableArray *toLoad;
    NSMutableArray *pageDetails;
    UIImage *backgroundImageLandscape;
    UIImage *backgroundImagePortrait;

	NSString *pageNameFromURL;
	NSString *anchorFromURL;
	
    int tapNumber;
    int stackedScrollingAnimations;
    
	BOOL currentPageFirstLoading;
	BOOL currentPageIsDelayingLoading;
    BOOL currentPageHasChanged;
    BOOL currentPageIsLocked;
        
    UIScrollView *scrollView;
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
	
	NSString *URLDownload;
    Downloader *downloader;
	UIAlertView *feedbackAlert;
    
    IndexViewController *indexViewController;
    
    Properties *properties;
}

#pragma mark - PROPERTIES
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIWebView *currPage;
@property int currentPageNumber;

#pragma mark - INIT
- (void)setupWebView:(UIWebView *)webView;
- (void)setPageSize:(NSString *)orientation;
- (void)setTappableAreaSize;
- (void)resetScrollView;
- (void)initPageDetails;
- (void)showPageDetails;
- (void)resetPageDetails;
- (void)initBookProperties:(NSString *)path;
- (void)initBook:(NSString *)path;
- (void)setImageFor:(UIImageView *)view;
- (void)addSkipBackupAttributeToItemAtPath:(NSString *)path;

#pragma mark - LOADING
- (BOOL)changePage:(int)page;
- (void)gotoPageDelayer;
- (void)gotoPage;
- (void)lockPage:(BOOL)lock;
- (void)addPageLoading:(int)slot;
- (void)handlePageLoading;
- (void)loadSlot:(int)slot withPage:(int)page;
- (BOOL)loadWebView:(UIWebView *)webview withPage:(int)page;

#pragma mark - SCROLLVIEW
- (CGRect)frameForPage:(int)page;
- (void)resetScrollView;

#pragma mark - WEBVIEW
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating;
- (void)webViewDidAppear:(UIWebView *)webView animating:(BOOL)animating;

#pragma mark - SCREENSHOTS
- (void)initScreenshots;
- (BOOL)checkScreeshotForPage:(int)pageNumber andOrientation:(NSString *)interfaceOrientation;
- (void)takeScreenshotFromView:(UIWebView *)webView forPage:(int)pageNumber andOrientation:(NSString *)interfaceOrientation;
- (void)placeScreenshotForView:(UIWebView *)webView andPage:(int)pageNumber andOrientation:(NSString *)interfaceOrientation;

#pragma mark - GESTURES
- (void)userDidTap:(UITouch *)touch;
- (void)userDidScroll:(UITouch *)touch;

#pragma mark - PAGE SCROLLING
- (void)getPageHeight;
- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating;
- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating;
- (void)scrollPage:(UIWebView *)webView to:(NSString *)offset animating:(BOOL)animating;
- (void)handleAnchor:(BOOL)animating;

#pragma mark - STATUS BAR
- (void)toggleStatusBar;
- (void)hideStatusBar;

#pragma mark - DOWNLOAD NEW BOOKS
- (void)downloadBook:(NSNotification *)notification;
- (void)startDownloadRequest;
- (void)handleDownloadResult:(NSNotification *)notification;
- (void)manageDownloadData:(NSData *)data;

#pragma mark - ORIENTATION
- (NSString *)getCurrentInterfaceOrientation;

@end
