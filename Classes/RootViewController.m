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
#import "TapHandler.h"

#define PAGE_HEIGHT 1024
#define PAGE_WIDTH 768

@implementation RootViewController

@synthesize pages;

@synthesize scrollView;
@synthesize pageSpinners;

@synthesize prevPage;
@synthesize currPage;
@synthesize nextPage;

@synthesize swipeLeft;
@synthesize swipeRight;

@synthesize totalPages;
@synthesize currentPageNumber;

- (id)init {		
	// ****** CONFIGURATION
	// Permanently hide status bar
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	
	// Count pages
	self.pages = [[NSBundle mainBundle] pathsForResourcesOfType:@"html" inDirectory:@"book"];
	totalPages = [pages count];
	NSLog(@"Pages in this book: %d", totalPages);
	
	// Check if there is a saved starting page
	NSString *currPageToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageViewed"];
	if (currPageToLoad != nil)
		currentPageNumber = [currPageToLoad intValue];
	else
		currentPageNumber = 1;
	
	currentPageFirstLoading = YES;
	currentPageIsDelayingLoading = YES;
	
	// ****** VIEW
	scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, PAGE_WIDTH, PAGE_HEIGHT)];
	scrollView.showsHorizontalScrollIndicator = YES;
	scrollView.showsVerticalScrollIndicator = NO;
	scrollView.delaysContentTouches = NO;
	scrollView.pagingEnabled = YES;
	scrollView.contentSize = CGSizeMake(PAGE_WIDTH * totalPages, PAGE_HEIGHT);
	
	[self initPageNumbersForPages:totalPages];
	
	//self.prevPage = [[UIWebView alloc] initWithFrame:[self frameForPage:currentPageNumber - 1]];
	self.currPage = [[UIWebView alloc] initWithFrame:[self frameForPage:currentPageNumber]];
	//self.nextPage = [[UIWebView alloc] initWithFrame:[self frameForPage:currentPageNumber + 1]];
	
	//[scrollView addSubview:self.prevPage];
	[scrollView addSubview:self.currPage];
	//[scrollView addSubview:self.nextPage];
	
	//self.prevPage.delegate = self;
	self.currPage.delegate = self;
	//self.nextPage.delegate = self;
	self.scrollView.delegate = self;
	
	[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
	[[self view] addSubview:scrollView];
	[[self view] sendSubviewToBack:scrollView]; // might not be required, test
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	[super viewDidLoad];
	[self loadSlot:0 withPage:currentPageNumber];
	
	// ****** CORNER TAP HANDLERS
	upTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(50,0,668,50)];
	//upTapHandler.backgroundColor = [UIColor redColor];
	//upTapHandler.alpha = 0.5;
	[[self view] addSubview:upTapHandler];
	[upTapHandler release];
	
	downTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(50,974,668,50)];
	//downTapHandler.backgroundColor = [UIColor redColor];
	//downTapHandler.alpha = 0.5;
	[[self view] addSubview:downTapHandler];
	[downTapHandler release];
	
	leftTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(0,50,50,924)];
	//leftTapHandler.backgroundColor = [UIColor redColor];
	//leftTapHandler.alpha = 0.5;
	[[self view] addSubview:leftTapHandler];
	[leftTapHandler release];
	
	rightTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(718,50,50,924)];
	//rightTapHandler.backgroundColor = [UIColor redColor];
	//rightTapHandler.alpha = 0.5;
	[[self view] addSubview:rightTapHandler];
	[rightTapHandler release];
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
- (void)initPageNumbersForPages:(int)count {
	pageSpinners = [[NSMutableArray alloc] initWithCapacity:count];
	
	for (int i = 0; i < count; i++) {
		// ****** Spinners
		UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		
		CGRect frame = spinner.frame;
		frame.origin.x = PAGE_WIDTH * i + (PAGE_WIDTH + frame.size.width) / 2 - 40;
		frame.origin.y = (PAGE_HEIGHT + frame.size.height) / 2;
		spinner.frame = frame;
		
		[pageSpinners addObject:spinner];
		[[self scrollView] addSubview:spinner];
		[spinner release];
		
		// ****** Numbers
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(PAGE_WIDTH * i + (PAGE_WIDTH) / 2, PAGE_HEIGHT / 2 - 6, 100, 50)];
		label.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2];
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
- (BOOL)loadSlot:(int)slot withPage:(int)page {
	
	UIWebView *webView;
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
	return CGRectMake(PAGE_WIDTH * (page - 1), 0, PAGE_WIDTH, PAGE_HEIGHT);
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
- (void)scrollViewDidEndDragging:(UIScrollView *)scroll willDecelerate:(BOOL)decelerate {
	// Nothing to do here...
}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
	// Nothing to do here either...
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll {
	int gotoPage = (int)(self.scrollView.contentOffset.x / PAGE_WIDTH) + 1;
	
	//NSLog(@"DEDe contentOffset: %@", NSStringFromCGPoint(self.scrollView.contentOffset));
	NSLog(@" <<<>>> Swiping to page: %d", gotoPage);
	
	if (currentPageNumber != gotoPage) {
		currentPageNumber = gotoPage;
		[self gotoPageDelayer];
	}
}

// ****** WEBVIEW
- (void)webViewDidStartLoad:(UIWebView *)webView {
	// Sent before a web view begins loading content.
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// Sent after a web view finishes loading content.
	
	// If is the first time i load something in the currPage web view...
	if (webView == currPage && currentPageFirstLoading) {
		NSLog(@"(1) currPage finished first loading");
		
		// ...check if there is a saved starting scroll index and set it
		NSString *currPageScrollIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrollIndex"];
		if (currPageScrollIndex != nil) [self goDownInPage:currPageScrollIndex animating:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTouch:) name:@"onTouch" object:nil];
		
		//[self loadSlot:+1 withPage:currentPageNumber + 1];
		//[self loadSlot:-1 withPage:currentPageNumber - 1];
		
		currentPageFirstLoading = NO;
	}
	
	// /!\ hack to make it load at the right time and not too early
	// source: http://stackoverflow.com/questions/1422146/webviewdidfinishload-firing-too-soon
	//NSString *javaScript = @"<script type=\"text/javascript\">function myFunction(){return 1+1;}</script>";
	//[webView stringByEvaluatingJavaScriptFromString:javaScript];
	
	[self spinnerForPage:currentPageNumber isAnimating:NO]; // spinner YES
	[self webView:webView hidden:NO animating:YES];
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
		
		NSLog(@"Current Page IS NOT delaying loading --> handle clicked link");
		
		if (![[[request URL] scheme] isEqualToString:@"http"]) {
						
			NSString *url = [NSString stringWithFormat:@"%@", [request URL]];
			NSString *file = [url lastPathComponent];
			
			NSLog(@"File number: %@", [file substringToIndex:[file length]-5]);
			int page = [[file substringToIndex:[file length]-5] intValue];
			
			if ([self changePage:page]) {
				[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:YES];
				[self gotoPageDelayer];
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

// ****** GESTURES
- (void)swipePage:(UISwipeGestureRecognizer *)sender {
	
	// Not needed anymore, since UIScrollView handle the horizontal scrolling, but...
	
	int page = 0;
	if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
		NSLog(@"<<< swipe right!");
		page = currentPageNumber-1;
	} else if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
		NSLog(@">>> swipe left!");
		page = currentPageNumber+1;
	}
	
	if ([self changePage:page]) {
		// ...if needed animate scrolling here.
		[self gotoPageDelayer];
	}
}
- (void)onTouch:(NSNotification *)notification {
	
	// Get the coordinates of the tap with the currPage as reference...
	UITouch *tap = (UITouch *)[notification object];
	NSUInteger tapCount = [tap tapCount];
	CGPoint tapPoint = [tap locationInView:currPage];
	
	NSLog(@"  .  %d tap(s) [%f, %f]", tapCount, tapPoint.x, tapPoint.y);
	
	// ...and swipe or scroll the page.
	if (tapPoint.y < upTapHandler.frame.size.height) {
		NSLog(@" /\\ TAP up!");
		[self goUpInPage:@"1004" animating:YES];
	} else if (tapPoint.y > (downTapHandler.frame.origin.y - 20)) {
		NSLog(@" \\/ TAP down!");
		[self goDownInPage:@"1004" animating:YES];
	} else {		
		
		int page = 0;
		if (tapPoint.x < leftTapHandler.frame.size.width) {
			NSLog(@"<-- TAP left!");
			page = currentPageNumber-1;
		} else if (tapPoint.x > rightTapHandler.frame.origin.x) {
			NSLog(@"--> TAP right!");
			page = currentPageNumber+1;
		}
		
		if ([self changePage:page]) {
			[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:YES];
			[self gotoPageDelayer];
		}
	}
}

// ****** PAGE SCROLLING
- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSLog(@"Scrolling page up");
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	offset = [NSString stringWithFormat:@"%d", ([currPageOffset intValue]-[offset intValue])];
	
	[self scrollPage:currPage to:offset animating:animating];
}
- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSLog(@"Scrolling page down");
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	offset = [NSString stringWithFormat:@"%d", ([currPageOffset intValue]+[offset intValue])];
	
	[self scrollPage:currPage to:offset animating:animating];
}
- (void)scrollPage:(UIWebView *)webView to:(NSString *)offset animating:(BOOL)animating {

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

// ****** SYSTEM
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
	// Overriden to allow any orientation.
    return NO;
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
	[swipeRight release];
	[swipeLeft release];
	//[nextPage release];
	[currPage release];
	//[prevPage release];
    [super dealloc];
}

@end