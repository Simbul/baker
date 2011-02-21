//
//  RootViewController.m
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

#import <QuartzCore/QuartzCore.h>
#import "RootViewController.h"
#import "Downloader.h"
#import "SSZipArchive.h"

// LOADER STYLE
// Configure this to change the color of the loader
#define SCROLLVIEW_BGCOLOR whiteColor
#define PAGE_NUMBERS_COLOR blackColor
#define PAGE_NUMBERS_ALPHA 0.2

// PINCH-TO-ZOOM
// Enable pinch-to-zoom on the book page.
//   NO (Default) - Because it creates a more uniform reading experience: you should zoom only specific items with JavaScript.
//   YES - Not recommended. You have to manually set the zoom in EACH of your HTML files.
#define PAGE_ZOOM_GESTURE NO

// TEXT LABELS
#define OPEN_BOOK_MESSAGE @"Do you want to download "
#define OPEN_BOOK_CONFIRM @"Open book"

#define CLOSE_BOOK_MESSAGE @"Do you want to close this book?"
#define CLOSE_BOOK_CONFIRM @"Close book"

#define ZERO_PAGES_TITLE @"Whoops!"
#define ZERO_PAGES_MESSAGE @"Sorry, that book had no pages."

#define ERROR_FEEDBACK_TITLE @"Whoops!"
#define ERROR_FEEDBACK_MESSAGE @"There was a problem downloading the book."
#define ERROR_FEEDBACK_CONFIRM @"Retry"

#define EXTRACT_FEEDBACK_TITLE @"Extracting..."

#define ALERT_FEEDBACK_CANCEL @"Cancel"

// AVAILABLE ORIENTATION
// Define the available orientation of the book
//	@"Any" (Default) - Book is available in both orientation
//	@"Portrait" - Book is available only in portrait orientation
//	@"Landscape" - Book is available only in landscape orientation
#define	AVAILABLE_ORIENTATION @"Any"

//  ==========================================================================================

@implementation RootViewController

@synthesize documentsBookPath;
@synthesize bundleBookPath;

@synthesize pages;

@synthesize scrollView;
@synthesize pageSpinners;

@synthesize prevPage;
@synthesize currPage;
@synthesize nextPage;

@synthesize currentPageNumber;

@synthesize URLDownload;

// ****** INIT
- (id)init {
	
	[super initWithNibName:nil bundle:nil];
	
	// Get device screen bounds
	screenBounds = [[UIScreen mainScreen] bounds];
	NSLog(@"Device Width: %f", screenBounds.size.width);
	NSLog(@"Device Height: %f", screenBounds.size.height);
		
	// Set up listener to download notification from application delegate
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadBook:) name:@"downloadNotification" object:nil];
	
	[self checkPageSize];
	
	discardNextStatusBarToggle = NO;
	stackedScrollingAnimations = 0;
	[self hideStatusBar];
	
	// ****** SCROLLVIEW INIT
	scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	scrollView.backgroundColor = [UIColor SCROLLVIEW_BGCOLOR];
	scrollView.showsHorizontalScrollIndicator = YES;
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.delaysContentTouches = NO;
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	
	// ****** PREV WEBVIEW INIT
	//prevPage = [[UIWebView alloc] init];
	//prevPage.delegate = self;
	
	// ****** CURR WEBVIEW INIT
	currPage = [[UIWebView alloc] init];
	currPage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	currPage.delegate = self;
	currPage.scalesPageToFit = PAGE_ZOOM_GESTURE;
	currPage.alpha = 0.5;
	
	// ****** NEXT WEBVIEW INIT
	//nextPage = [[UIWebView alloc] init];
	//nextPage.delegate = self;
	
	currentPageFirstLoading = YES;
	currentPageIsDelayingLoading = YES;
		
	[[self view] addSubview:scrollView];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	self.documentsBookPath = [documentsPath stringByAppendingPathComponent:@"book"];
	self.bundleBookPath = [[NSBundle mainBundle] pathForResource:@"book" ofType:nil];
		
	if ([[NSFileManager defaultManager] fileExistsAtPath:documentsBookPath]) {
		[self initBook:documentsBookPath];
	} else {
		if ([[NSFileManager defaultManager] fileExistsAtPath:bundleBookPath]) {
			[self initBook:bundleBookPath];
		} /* else {
		   Do something if there are no books available to show...   
		} /**/
	}
	
	return self;
}
- (void)checkPageSize {
	if ([AVAILABLE_ORIENTATION isEqualToString:@"Portrait"] || [AVAILABLE_ORIENTATION isEqualToString:@"Landscape"]) {
		[self setPageSize:AVAILABLE_ORIENTATION];
	} else {
		UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
		// WARNING! Seems like checking [[UIDevice currentDevice] orientation] against "UIInterfaceOrientationPortrait" is broken (return FALSE with the device in portrait orientation)
		// Safe solution: always check if the device is in landscape orientation, if FALSE then it's in portrait.
		if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
			[self setPageSize:@"Landscape"];
		else
			[self setPageSize:@"Portrait"];
	}
}
- (void)setPageSize:(NSString *)orientation {
	
	NSLog(@"Set size for orientation: %@", orientation);
	if ([orientation isEqualToString:@"Portrait"]) {
		pageWidth = screenBounds.size.width;
		pageHeight = screenBounds.size.height;
	} else if ([orientation isEqualToString:@"Landscape"]) {
		pageWidth = screenBounds.size.height;
		pageHeight = screenBounds.size.width;
	}
}
- (void)resetScrollView {
	for (id subview in scrollView.subviews) {
		if (![subview isKindOfClass:[UIWebView class]]) {
			[subview removeFromSuperview];
		}
	}

	scrollView.contentSize = CGSizeMake(pageWidth * totalPages, pageHeight);
	
	UIApplication *sharedApplication = [UIApplication sharedApplication];
	int scrollViewY = 0;
	if (!sharedApplication.statusBarHidden) {
		scrollViewY = -20;
	}
	scrollView.frame = CGRectMake(0, scrollViewY, pageWidth, pageHeight);
	
	[self initPageNumbersForPages:totalPages];

	//prevPage.frame = [self frameForPage:currentPageNumber-1];
	currPage.frame = [self frameForPage:currentPageNumber];
	//nextPage.frame = [self frameForPage:currentPageNumber+1];
	
	[scrollView bringSubviewToFront:currPage];
	[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];

	// ****** TAPPABLE AREAS
	int tappableAreaSize = screenBounds.size.width/16;
	if (screenBounds.size.width < 768)
		tappableAreaSize = screenBounds.size.width/8;
	
	upTapArea = CGRectMake(tappableAreaSize, 0, pageWidth - (tappableAreaSize * 2), tappableAreaSize);
	downTapArea = CGRectMake(tappableAreaSize, pageHeight - tappableAreaSize, pageWidth - (tappableAreaSize * 2), tappableAreaSize);
	leftTapArea = CGRectMake(0, tappableAreaSize, tappableAreaSize, pageHeight - (tappableAreaSize * 2));
	rightTapArea = CGRectMake(pageWidth - tappableAreaSize, tappableAreaSize, tappableAreaSize, pageHeight - (tappableAreaSize * 2));
}
- (void)initBook:(NSString *)path {
	
	// Count pages
	if (self.pages != nil)
		[self.pages removeAllObjects];
	else
		self.pages = [NSMutableArray array];
	
	NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *fileName in dirContent) {
		if ([[fileName pathExtension] isEqualToString:@"html"])
			[self.pages addObject:[path stringByAppendingPathComponent:fileName]];
	}
		
	totalPages = [pages count];
	NSLog(@"Pages in this book: %d", totalPages);
	
	if (totalPages > 0) {
		// Check if there is a saved starting page
		NSString *currPageToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageViewed"];
		
		if (currentPageFirstLoading && currPageToLoad != nil)
			currentPageNumber = [currPageToLoad intValue];
		else
			currentPageNumber = 1;
		
		[self resetScrollView];
		//[scrollView addSubview:prevPage];
		[scrollView addSubview:currPage];
		//[scrollView addSubview:nextPage];
		[self loadSlot:0 withPage:currentPageNumber];
		
	} else {
		
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
		
 		feedbackAlert = [[UIAlertView alloc] initWithTitle:ZERO_PAGES_TITLE
												   message:ZERO_PAGES_MESSAGE
												  delegate:self
										 cancelButtonTitle:ALERT_FEEDBACK_CANCEL
										 otherButtonTitles:nil];
		[feedbackAlert show];
		[feedbackAlert release];
		
		[self initBook:bundleBookPath];
	}
}
- (void)initPageNumbersForPages:(int)count {
	pageSpinners = [[NSMutableArray alloc] initWithCapacity:count];
	
	for (int i = 0; i < count; i++) {
		// ****** Spinners
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		spinner.backgroundColor = [UIColor clearColor];
		
		CGRect frame = spinner.frame;
		frame.origin.x = pageWidth * i + (pageWidth + frame.size.width) / 2 - 40;
		frame.origin.y = (pageHeight + frame.size.height) / 2;
		spinner.frame = frame;
		
		[pageSpinners addObject:spinner];
		[[self scrollView] addSubview:spinner];
		[spinner release];
		
		// ****** Numbers
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(pageWidth * i + (pageWidth) / 2, pageHeight / 2 - 6, 100, 50)];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor PAGE_NUMBERS_COLOR];
		label.alpha = PAGE_NUMBERS_ALPHA;
				
		NSString *labelText = [[NSString alloc] initWithFormat:@"%d", i + 1];
		label.font = [UIFont fontWithName:@"Helvetica" size:40.0];
		label.textAlignment = UITextAlignmentLeft;
		label.text = labelText;
		//label.backgroundColor = [UIColor redColor];
		[labelText release];
		
		[[self scrollView] addSubview:label];
		[label release];
	}
}

// ****** LOADING
- (BOOL)changePage:(int)page {

	BOOL pageChanged = NO;
	if (page < 1) {
		currentPageNumber = 1;
	} else if (page > totalPages) {
		currentPageNumber = totalPages;
	} else {
		currentPageNumber = page;
		pageChanged = YES;
	}
	
	return pageChanged;	
}
- (void)gotoPageDelayer {
	// This delay is required in order to avoid stuttering when the animation runs.
	// The animation lasts 0.5 seconds: so we start loading after that.
	
	if (currentPageIsDelayingLoading)
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(gotoPage) object:nil];
	
	currentPageIsDelayingLoading = YES;
	[self performSelector:@selector(gotoPage) withObject:nil afterDelay:0.5];
}
- (void)gotoPage {
	
	/****************************************************************************************************
	 * Opens a specific page
	 */
		
	//NSString *file = [NSString stringWithFormat:@"%d", currentPageNumber];
	//NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"html" inDirectory:@"book"];
		
	NSString *path = [pages objectAtIndex:currentPageNumber-1];
		
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSLog(@"Goto Page: book/%@", [[NSFileManager defaultManager] displayNameAtPath:path]);
		
		// ****** METHOD B - Single view
		[currPage stopLoading];
		currPage.frame = [self frameForPage:currentPageNumber];
		[self loadSlot:0 withPage:currentPageNumber];
		
		// ****** METHOD A - Three-cards view
		/*if ((pageNumber - currentPageNumber) > 0) {
			// ****** Move RIGHT >>>
			currentPageNumber = pageNumber;
			prevPage.frame = [self frameForPage:pageNumber + 1];
			
			// Swap
			UIWebView *tmpView = prevPage;
			prevPage = currPage;
			currPage = nextPage;
			nextPage = tmpView;
			
			// Preload
			[self loadSlot:+1 withPage:currentPageNumber + 1];
		} else {
			// ****** Move LEFT <<<
			currentPageNumber = pageNumber;
			nextPage.frame = [self frameForPage:pageNumber - 1];
			
			// Swap
			UIWebView *tmpView = nextPage;
			nextPage = currPage;
			currPage = prevPage;
			prevPage = tmpView;
			
			// Preload
			[self loadSlot:-1 withPage:currentPageNumber - 1];
		} /**/
	}	
}
- (BOOL)loadSlot:(int)slot withPage:(int)page {
	
	UIWebView *webView = nil;
	//CGRect frame;
	
	// ****** SELECT
	if (slot == -1) {
		webView = self.prevPage;
		//frame = [self frameForPage:page - 1];
	} else if (slot == 0) {
		webView = self.currPage;
		//frame = [self frameForPage:page];
	} else if (slot == +1) {
		webView = self.nextPage;
		//frame = [self frameForPage:page + 1];
	}
	
	// ****** DESTROY
	/*if (webView != nil) {
		[webView removeFromSuperview];
		[webView release];
	} /**/
	
	// ***** CREATE
	/*webView = [[UIWebView alloc] initWithFrame:frame];
	webView.delegate = self;
	[[self view] addSubview:webView];
	[[self view] sendSubviewToBack:webView]; /**/
	[self loadWebView:webView withPage:page];
	[self spinnerForPage:page isAnimating:YES]; // spinner YES
	
	// ****** ATTACH
	/*if (slot == -1) {
		self.prevPage = webView;
	} else if (slot == 0) {
		self.currPage = webView;
	} else if (slot == +1) {
		self.nextPage = webView;
	} /**/
	
	return NO;
}
- (BOOL)loadWebView:(UIWebView*)webView withPage:(int)page {
	
	//NSString *file = [NSString stringWithFormat:@"%d", page];
	//NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"html" inDirectory:@"book"];
	
	NSString *path = [pages objectAtIndex:page-1];
		
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSLog(@"[+] Loading: book/%@", [[NSFileManager defaultManager] displayNameAtPath:path]);
		webView.hidden = YES; // use direct property instead of [self webView:hidden:animating:] otherwise it won't work
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
		return YES;
	}
	return NO;
}

// ****** SCROLLVIEW
- (CGRect)frameForPage:(int)page {
	return CGRectMake(pageWidth * (page - 1), 0, pageWidth, pageHeight);
}
- (void)spinnerForPage:(int)page isAnimating:(BOOL)isAnimating {
	UIActivityIndicatorView *spinner = nil;
	if (page <= pageSpinners.count) spinner = [pageSpinners objectAtIndex:page - 1];
	
	if (isAnimating) {
		spinner.alpha = 0.0;
		[UIView beginAnimations:@"showSpinner" context:nil]; {
			//[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[UIView setAnimationDuration:1.0];
			//[UIView setAnimationDelegate:self];
			//[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
			
			spinner.alpha = 1.0;
		}
		[UIView commitAnimations];	
		[spinner startAnimating];
	} else {
		[spinner stopAnimating];
	}
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// This is called because this controller is the delegate for UIScrollView
	[self hideStatusBar];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scroll willDecelerate:(BOOL)decelerate {
	// Nothing to do here...
}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	// Nothing to do here either...
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll {
	int gotoPage = (int)(self.scrollView.contentOffset.x / pageWidth) + 1;
	
	//NSLog(@"DEDe contentOffset: %@", NSStringFromCGPoint(self.scrollView.contentOffset));
	NSLog(@" <<<>>> Swiping to page: %d", gotoPage);
	
	if (currentPageNumber != gotoPage) {
		currentPageNumber = gotoPage;
		[self gotoPageDelayer];
	}
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	stackedScrollingAnimations--;
	if (stackedScrollingAnimations == 0) {
		self.scrollView.scrollEnabled = YES;
	}
}

// ****** WEBVIEW
- (void)webViewDidStartLoad:(UIWebView *)webView {
	// Sent before a web view begins loading content.
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// Sent after a web view finishes loading content.
	
	// Get current page max scroll offset
	for (id subview in webView.subviews) {
		if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
			CGSize size = ((UIScrollView *)subview).contentSize;
			
			currentPageHeight = size.height;
			NSLog(@"Current page height: %d", currentPageHeight);			
		}
	}
	
	// If is the first time i load something in the currPage web view...
	if (webView == currPage && currentPageFirstLoading) {
		NSLog(@"(1) currPage finished first loading");
		
		// ...check if there is a saved starting scroll index and set it
		NSString *currPageScrollIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrollIndex"];
		if (currPageScrollIndex != nil) [self goDownInPage:currPageScrollIndex animating:NO];
		
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTouch:) name:@"onTouch" object:nil];
		
		//[self loadSlot:+1 withPage:currentPageNumber + 1];
		//[self loadSlot:-1 withPage:currentPageNumber - 1];
		
		currentPageFirstLoading = NO;
	}
	
	// /!\ hack to make it load at the right time and not too early
	// source: http://stackoverflow.com/questions/1422146/webviewdidfinishload-firing-too-soon
	//NSString *javaScript = @"<script type=\"text/javascript\">function myFunction(){return 1+1;}</script>";
	//[webView stringByEvaluatingJavaScriptFromString:javaScript];
	
	[self spinnerForPage:currentPageNumber isAnimating:NO]; // spinner YES
	[self performSelector:@selector(revealWebView:) withObject:webView afterDelay:0.1]; // This seems fixing the WebView-Flash-Of-Old-Content-Bug
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	// Sent if a web view failed to load content.
	if (webView == prevPage)
		NSLog(@"prevPage failed to load content with error: %@", error);
	else if (webView == currPage)
		NSLog(@"currPage failed to load content with error: %@", error);
	else if (webView == nextPage)
		NSLog(@"nextPage failed to load content with error: %@", error);
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	// Sent before a web view begins loading content, useful to trigger actions before the WebView.	
	if (currentPageIsDelayingLoading) {
		
		NSLog(@"Current Page IS delaying loading --> load page");
		currentPageIsDelayingLoading = NO;
		return YES;
		
	} else {
		
		[self hideStatusBarDiscardingToggle:YES];
		
		NSURL *url = [request URL];
		NSLog(@"Current Page IS NOT delaying loading --> handle clicked link: %@", [url absoluteString]);
		
		// ****** Handle URI schemes
		if (url) {
			// Existing, checking schemes...
			
			if ([[url scheme] isEqualToString:@"file"]) {
				// ****** Handle: file://
				NSLog(@"file:// ->");
				
				NSString *file = [[url relativePath] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				int page = (int)[pages indexOfObject:file] + 1;
				if ([self changePage:page]) {
					stackedScrollingAnimations++;
					[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:YES];
					[self gotoPageDelayer];
				}
				
			} else if ([[url scheme] isEqualToString:@"book"]) {
				// ****** Handle: book://
				NSLog(@"book:// ->");
				
				if ([[url host] isEqualToString:@"local"] && [[NSFileManager defaultManager] fileExistsAtPath:bundleBookPath]) {
					// *** Back to bundled book
					feedbackAlert = [[UIAlertView alloc] initWithTitle:@""
															   message:[NSString stringWithFormat:CLOSE_BOOK_MESSAGE]
															  delegate:self
													 cancelButtonTitle:ALERT_FEEDBACK_CANCEL
													 otherButtonTitles:CLOSE_BOOK_CONFIRM, nil];
					[feedbackAlert show];
					[feedbackAlert release];
				} else {
					// *** Download book
					self.URLDownload = [@"http:" stringByAppendingString:[url resourceSpecifier]];
					
					if ([[[NSURL URLWithString:self.URLDownload] pathExtension] isEqualToString:@""]) {
						self.URLDownload = [self.URLDownload stringByAppendingString:@".hpub"];
					}
					
					[self downloadBook:nil];
				}
			} else {
				// ****** Handle: *
				[[UIApplication sharedApplication] openURL:[request URL]];
			}
		}
		
		return NO;
	}
}
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating {
	NSLog(@"- - hidden:%d animating:%d", status, animating);
	
	if (animating) {
		webView.alpha = 0.0;
		webView.hidden = NO;
		
		[UIView beginAnimations:@"webViewVisibility" context:nil]; {
			//[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[UIView setAnimationDuration:0.5];
			//[UIView setAnimationDelegate:self];
			//[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
			
			webView.alpha = 1.0;	
		}
		[UIView commitAnimations];		
	} else {
		webView.alpha = 1.0;
		webView.hidden = NO;
	}
}
- (void)revealWebView:(UIWebView *)webView {
	[self webView:webView hidden:NO animating:YES];  // Delayed run to fix the WebView-Flash-Of-Old-Content-Bug
}

// ****** GESTURES
- (void)userDidTap:(UITouch *)touch {
	NSLog(@"User did single tap");
	
	CGPoint tapPoint = [touch locationInView:self.view];
	
	NSLog(@"  .  1 tap [%f, %f]", tapPoint.x, tapPoint.y);
	
	// ...and swipe or scroll the page.
	if (CGRectContainsPoint(upTapArea, tapPoint)) {
		NSLog(@" /\\ TAP up!");
		[self goUpInPage:@"1004" animating:YES];
	} else if (CGRectContainsPoint(downTapArea, tapPoint)) {
		NSLog(@" \\/ TAP down!");
		[self goDownInPage:@"1004" animating:YES];
	} else if (CGRectContainsPoint(leftTapArea, tapPoint) || CGRectContainsPoint(rightTapArea, tapPoint)) {
		int page = 0;
		if (CGRectContainsPoint(leftTapArea, tapPoint)) {
			NSLog(@"<-- TAP left!");
			page = currentPageNumber-1;
		} else if (CGRectContainsPoint(rightTapArea, tapPoint)) {
			NSLog(@"--> TAP right!");
			page = currentPageNumber+1;
		}
		
		if ([self changePage:page]) {
			[self hideStatusBar];
			// While we are tapping, we don't want scrolling event to get in the way
			scrollView.scrollEnabled = NO;
			stackedScrollingAnimations++;
			[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:YES];
			[self gotoPageDelayer];
		}
	} else if (touch.tapCount == 2) {
		[self performSelector:@selector(toggleStatusBar) withObject:nil];
	}
}
- (void)userDidScroll:(UITouch *)touch {
	NSLog(@"User did scroll");
	[self hideStatusBar];
}

// ****** PAGE SCROLLING
- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	
	int currentPageOffset = [currPageOffset intValue];
	if (currentPageOffset > 0) {
		
		int targetOffset = currentPageOffset-[offset intValue];
		if (targetOffset < 0)
			targetOffset = 0;
		
		NSLog(@"Scrolling page up to %d", targetOffset);
		
		offset = [NSString stringWithFormat:@"%d", targetOffset];
		[self scrollPage:currPage to:offset animating:animating];
	}
}
- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	
	int currentPageMaxScroll = currentPageHeight - pageHeight;
	int currentPageOffset = [currPageOffset intValue];
	
	if (currentPageOffset < currentPageMaxScroll) {
		
		int targetOffset = currentPageOffset+[offset intValue];
		if (targetOffset > currentPageMaxScroll)
			targetOffset = currentPageMaxScroll;
		
		NSLog(@"Scrolling page down to %d", targetOffset);
		
		offset = [NSString stringWithFormat:@"%d", targetOffset];
		[self scrollPage:currPage to:offset animating:animating];
	}

}
- (void)scrollPage:(UIWebView *)webView to:(NSString *)offset animating:(BOOL)animating {
	[self hideStatusBar];
	
	NSString *jsCommand = [NSString stringWithFormat:@"window.scrollTo(0,%@);", offset];
	
	if (animating) {
		
		[UIView beginAnimations:@"scrollPage" context:nil]; {
		
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[UIView setAnimationDuration:0.35];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
		
			[webView stringByEvaluatingJavaScriptFromString:jsCommand];
		}
		[UIView commitAnimations];
	
	} else {
		[webView stringByEvaluatingJavaScriptFromString:jsCommand];
	}
}

// ****** STATUS BAR
- (void)toggleStatusBar {
	if (discardNextStatusBarToggle) {
		// do nothing, but reset the variable
		discardNextStatusBarToggle = NO;
	} else {
		NSLog(@"TOGGLE status bar");
		UIApplication *sharedApplication = [UIApplication sharedApplication];
		[sharedApplication setStatusBarHidden:!sharedApplication.statusBarHidden withAnimation:UIStatusBarAnimationSlide];
	}
}
- (void)hideStatusBar {
	[self hideStatusBarDiscardingToggle:NO];
}
- (void)hideStatusBarDiscardingToggle:(BOOL)discardToggle {
	NSLog(@"HIDE status bar %@", (discardToggle ? @"discarding toggle" : @""));
	discardNextStatusBarToggle = discardToggle;
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

// ****** DOWNLOAD NEW BOOKS
- (void)downloadBook:(NSNotification *)notification {
	
	if (notification != nil)
		self.URLDownload = (NSString *)[notification object];
	
	NSLog(@"Download file %@", URLDownload);
	
	feedbackAlert = [[UIAlertView alloc] initWithTitle:@""
											   message:[OPEN_BOOK_MESSAGE stringByAppendingFormat:@"%@?", URLDownload]
											  delegate:self
									 cancelButtonTitle:ALERT_FEEDBACK_CANCEL
									 otherButtonTitles:OPEN_BOOK_CONFIRM, nil];
	[feedbackAlert show];
	[feedbackAlert release];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	if (buttonIndex != alertView.cancelButtonIndex) {
		if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:CLOSE_BOOK_CONFIRM])
			[self initBook:bundleBookPath];
		else
			[self startDownloadRequest];
	}
}
- (void)startDownloadRequest {
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadResult:) name:@"handleDownloadResult" object:nil];	
	downloader = [[Downloader alloc] initDownloader:@"handleDownloadResult"];
	[downloader makeHTTPRequest:URLDownload];
}
- (void)handleDownloadResult:(NSNotification *)notification {
	
	NSMutableDictionary *requestSummary = (NSMutableDictionary *)[notification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"handleDownloadResult" object:nil];
	
	[downloader release];
		
	if ([requestSummary objectForKey:@"error"] != nil) {
		
		NSLog(@"Error while downloading data");
		
		feedbackAlert = [[UIAlertView alloc] initWithTitle:ERROR_FEEDBACK_TITLE
												   message:ERROR_FEEDBACK_MESSAGE
												  delegate:self
										 cancelButtonTitle:ALERT_FEEDBACK_CANCEL
										 otherButtonTitles:ERROR_FEEDBACK_CONFIRM, nil];
		[feedbackAlert show];
		[feedbackAlert release];
			
	} else if ([requestSummary objectForKey:@"data"] != nil) {
		
		NSLog(@"Data received succesfully");
		
		feedbackAlert = [[UIAlertView alloc] initWithTitle:EXTRACT_FEEDBACK_TITLE
												   message:nil
												  delegate:self
										 cancelButtonTitle:nil
										 otherButtonTitles:nil];
				
		UIActivityIndicatorView *extractingWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(124,50,37,37)];
		extractingWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
		[extractingWheel startAnimating];
		
		[feedbackAlert addSubview:extractingWheel];
		[feedbackAlert show];
		
		[extractingWheel release];
		[feedbackAlert release];
		
		[self performSelector:@selector(manageDownloadData:) withObject:[requestSummary objectForKey:@"data"] afterDelay:0.1];
	}
}
- (void)manageDownloadData:(NSData *)data {
			
	NSArray *URLSections = [URLDownload pathComponents];
	NSString *targetPath = [NSTemporaryDirectory() stringByAppendingString:[URLSections lastObject]];
		
	[data writeToFile:targetPath atomically:YES];
			
	if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
		NSLog(@"File create successfully! Path: %@", targetPath);
		
		NSString *destinationPath = self.documentsBookPath;
		NSLog(@"Book destination path: %@", destinationPath);
		
		// If a "book" directory already exists remove it (quick solution, improvement needed) 
		if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
			[[NSFileManager defaultManager] removeItemAtPath:destinationPath error:NULL];
		
		[SSZipArchive unzipFileAtPath:targetPath toDestination:destinationPath];
		
		NSLog(@"Book successfully unzipped. Removing .hpub file");
		[[NSFileManager defaultManager] removeItemAtPath:targetPath error:NULL];
		
		currentPageIsDelayingLoading = YES;
		
		[feedbackAlert dismissWithClickedButtonIndex:feedbackAlert.cancelButtonIndex animated:YES];
		[self initBook:destinationPath];
	} /* else {
	   Do something if it was not possible to write the book file on the iPhone/iPad file system...
	} /**/
}

// ****** SYSTEM
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Overriden to allow any orientation.
	
	if ([AVAILABLE_ORIENTATION isEqualToString:@"Portrait"]) {
		return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	} else if ([AVAILABLE_ORIENTATION isEqualToString:@"Landscape"]) {
		return (interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
	} else {
		return YES;
	}	
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self checkPageSize];
	[self resetScrollView];
	[currPage setNeedsDisplay];
}
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
- (void)viewDidUnload {
    
	[super viewDidUnload];
	
	// Set web views delegates to nil, mandatory before releasing UIWebview instances 
	//nextPage.delegate = nil;
	currPage.delegate = nil;
	//prevPage.delegate = nil;
}
- (void)dealloc {
	//[nextPage release];
	[currPage release];
	//[prevPage release];
    [super dealloc];
}

@end