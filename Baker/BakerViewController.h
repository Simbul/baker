//
//  RootViewController.h
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
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
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>

#import "BakerWrapper.h"
#import "BakerWrapperDataSource.h"
#import "BakerWrapperDelegate.h"
#import "IndexViewController.h"
#import "PageViewController.h"
#import "ModalViewController.h"
#import "Properties.h"

// Page Rendering Type Definitions
enum {
    BakerRenderingTypeScreenshots,
    BakerRenderingTypeThreeCards
} typedef BakerRenderingType;

@class Downloader;
@interface BakerViewController : UIViewController<BakerWrapperDataSource, BakerWrapperDelegate, modalWebViewDelegate>  {
    
    CGRect screenBounds;
    
    NSString *currentBookPath;
    NSString *bundleBookPath;
    NSString *documentsBookPath;
    NSString *defaultScreeshotsPath;
    NSString *cachedScreenshotsPath;
    
    NSString *availableOrientation;
    
    NSMutableArray *pages;
    NSMutableArray *toLoad;
    
    NSMutableDictionary *attachedScreenshotPortrait;
    NSMutableDictionary *attachedScreenshotLandscape;
    
    NSString *pageNameFromURL;
    NSString *anchorFromURL;
    
    UIImage *backgroundImageLandscape;
    UIImage *backgroundImagePortrait;
    
    PageViewController *prevPage;
    PageViewController *currPage;
    PageViewController *nextPage;
    
    NSString *URLDownload;
    Downloader *downloader;
    UIAlertView *feedbackAlert;
    
    IndexViewController *indexViewController;
    ModalViewController *myModalViewController;
    
    BakerRenderingType renderingType;
    
    Properties *properties;
}

#pragma mark - PROPERTIES
@property (nonatomic, retain) BakerWrapper *wrapperViewController;

#pragma mark - INIT
- (id)initWithBookPath:(NSString *)bookPath;
- (BOOL)loadBookWithBookPath:(NSString *)bookPath;
- (void)cleanupBookEnvironment;
- (void)resetPageSlots;
- (void)loadBookProperties;
- (void)buildPageArray;
- (void)startReadingFromPage:(int)pageNumber anchor:(NSString *)anchor;
- (void)startReading;
- (void)setImageFor:(UIImageView *)view;
- (void)updateBookLayout;
- (void)setPageSize:(NSString *)orientation;
- (void)setTappableAreaSize;
- (void)setFrame:(CGRect)frame forPage:(UIWebView *)page;
- (void)setupWebView:(UIWebView *)webView;
- (void)addSkipBackupAttributeToItemAtPath:(NSString *)path;
- (NSDictionary *)bookCurrentStatus;

#pragma mark - MODAL WEBVIEW
- (void)loadModalWebView:(NSURL *)url;
- (void)closeModalWebView;

#pragma mark - PAGE MANAGEMENT
- (PageViewController *)initWrapperWithPage:(int)page;
- (void)pageViewHasBecomeCurrentPage:(PageViewController *)newPageViewController;
- (PageViewController *)pageViewForPage:(int)page;
- (PageViewController *)gotoPage:(int)page;

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

#pragma mark - INDEX VIEW
- (BOOL)isIndexView:(UIWebView *)webView;

@end
