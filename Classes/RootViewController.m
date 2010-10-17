//
//  RootViewController.m
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright 2010 Xmas. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RootViewController.h"
#import "TapHandler.h"

#define PAGE_HEIGHT 1024
#define PAGE_WIDTH 768

@implementation RootViewController

@synthesize scrollView;

@synthesize prevPage;
@synthesize currPage;
@synthesize nextPage;

@synthesize swipeLeft;
@synthesize swipeRight;

@synthesize totalPages;
@synthesize currentPageNumber;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		
		// ****** CONFIGURATION
		// Permanently hide status bar
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		
		// Count pages
		NSArray *pagesArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"html" inDirectory:@"book"];
		totalPages = [pagesArray count];
		NSLog(@"Pages in this book: %d", totalPages);
		
		// Check if there is a saved starting page
		NSString *currPageToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageViewed"];
		if (currPageToLoad != nil)
			currentPageNumber = [currPageToLoad intValue];
		else
			currentPageNumber = 1;
        
		currentPageFirstLoading = YES;
		currentPageIsAnimating = NO;
		
		// ****** VIEW
		scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, PAGE_WIDTH, PAGE_HEIGHT)];
		scrollView.showsHorizontalScrollIndicator = NO;
		scrollView.showsVerticalScrollIndicator = NO;
		scrollView.delaysContentTouches = YES;
		scrollView.pagingEnabled = YES;
		scrollView.contentSize = CGSizeMake(PAGE_WIDTH * totalPages, PAGE_HEIGHT);
		
		self.prevPage = [[UIWebView alloc] initWithFrame:[self frameForPage:currentPageNumber - 1]];
		self.currPage = [[UIWebView alloc] initWithFrame:[self frameForPage:currentPageNumber]];
		self.nextPage = [[UIWebView alloc] initWithFrame:[self frameForPage:currentPageNumber + 1]];
		
		[scrollView addSubview:self.prevPage];
		[scrollView addSubview:self.currPage];
		[scrollView addSubview:self.nextPage];
		
		self.prevPage.delegate = self;
		self.currPage.delegate = self;
		self.nextPage.delegate = self;
		self.scrollView.delegate = self;
		
		[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
		[[self view] addSubview:scrollView];
		[[self view] sendSubviewToBack:scrollView]; // might not be required, test
		
		// TEMP
		/*NSURL *url = [NSURL URLWithString:@"http://www.google.com"];
		NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];	
		[self.prevPage loadRequest:requestObj];
		[self.currPage loadRequest:requestObj];
		[self.nextPage loadRequest:requestObj];*/
		
		// Custom initialization		
		//frameLeft = CGRectMake(-PAGE_WIDTH, 0, PAGE_WIDTH, PAGE_HEIGHT);
		//frameCenter = CGRectMake(0, 0, PAGE_WIDTH, PAGE_HEIGHT);
		//frameRight = CGRectMake(PAGE_WIDTH, 0, PAGE_WIDTH, PAGE_HEIGHT);
	}
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	[super viewDidLoad];
	
	// ****** Load starting pages inside views
	//[self preloadWebViewsWithPage:currentPageNumber];
	[self loadSlot:0 withPage:currentPageNumber];
	
	// ****** Create tap handlers
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
	
	leftTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(0,20,50,984)];
	//leftTapHandler.backgroundColor = [UIColor redColor];
	//leftTapHandler.alpha = 0.5;
	[[self view] addSubview:leftTapHandler];
	[leftTapHandler release];
	
	rightTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(718,20,50,984)];
	//rightTapHandler.backgroundColor = [UIColor redColor];
	//rightTapHandler.alpha = 0.5;
	[[self view] addSubview:rightTapHandler];
	[rightTapHandler release];
	
	
	// ****** Load swipe recognizers
	/*self.swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	[[self view] addGestureRecognizer:swipeLeft];
	[swipeLeft release];
	
	self.swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	[[self view] addGestureRecognizer:swipeRight];
	[swipeRight release];*/
}

// ****** LOADING
- (BOOL)loadSlot:(int)slot withPage:(int)page {
	
	UIWebView *webView;
	CGRect frame;
	
	// ****** SELECT
	if (slot == -1) {
		webView = self.prevPage;
		frame = frameLeft;
	} else if (slot == 0) {
		webView = self.currPage;
		frame = frameCenter;
	} else if (slot == +1) {
		webView = self.nextPage;
		frame = frameRight;
	}
	
	// ****** DESTROY
	/*if (webView != nil) {
		[webView removeFromSuperview];
		[webView release];
	}*/
	
	// ***** CREATE
	/*webView = [[UIWebView alloc] initWithFrame:frame];
	webView.delegate = self;*/
	webView.hidden = YES;
	/*[[self view] addSubview:webView];
	[[self view] sendSubviewToBack:webView];*/
	[self loadWebView:webView withPage:page];
	
	// ****** ATTACH
	/*if (slot == -1) {
		self.prevPage = webView;
	} else if (slot == 0) {
		self.currPage = webView;
	} else if (slot == +1) {
		self.nextPage = webView;
	}*/
	
	
	/*UIWebView *webView1 = [[UIWebView alloc] initWithFrame:CGRectMake(0,20,768,1004)];
	UIWebView *webView2 = [[UIWebView alloc] initWithFrame:CGRectMake(768,20,768,1004)];
	UIWebView *webView3 = [[UIWebView alloc] initWithFrame:CGRectMake(1536,20,768,1004)];
	[webView1 loadRequest:requestObj];
	[webView2 loadRequest:requestObj];
	[webView3 loadRequest:requestObj];
	
	[target loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
	prevPage.delegate = self;
	
	[scrollView addSubview:webView1];
	[scrollView addSubview:webView2];
	[scrollView addSubview:webView3];
	
	[window addSubview:scrollView];
	*/
	return NO;
}
- (BOOL)loadWebView:(UIWebView*)webview withPage:(int)page {
	NSString *file = [NSString stringWithFormat:@"%d", page];
	NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"html" inDirectory:@"book"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSLog(@"[+] Loading: book/%@.html", file);
		[webview loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
		return YES;
	}
	return NO;
}

// ****** SCROLLVIEW
- (CGRect)frameForPage:(int)page {
	return CGRectMake(PAGE_WIDTH * (page - 1), 0, PAGE_WIDTH, PAGE_HEIGHT);
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scroll willDecelerate:(BOOL)decelerate {
	// nothing to see, nothing to do
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll {
	int gotoPage = (int)(self.scrollView.contentOffset.x / PAGE_WIDTH) + 1;
	
	//NSLog(@"DEDe contentOffset: %@", NSStringFromCGPoint(self.scrollView.contentOffset));
	NSLog(@" <<<>>> Swiping to page: %d", gotoPage);
	
	if (currentPageNumber != gotoPage) {
		[self gotoPage:gotoPage];
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
		
		NSLog(@"currPage finished first loading");
		
		// ...check if there is a saved starting scroll index and set it
		NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
		NSString *currPageScrollIndex = [userDefs objectForKey:@"lastScrollIndex"];
		if(currPageScrollIndex != nil) {
			[self goDownInPage:currPageScrollIndex animating:NO];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTouch:) name:@"onTouch" object:nil];
		
		[self loadSlot:+1 withPage:currentPageNumber + 1];
		[self loadSlot:-1 withPage:currentPageNumber - 1];
		
		currentPageFirstLoading = NO;
	}
	
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
	if ([[[request URL] scheme] isEqualToString:@"x-local"]) {
		NSLog(@"   x-local!", [[request URL] absoluteString]);
		//TODO
		return NO;
	}
	
	return YES; // Return YES to make sure regular navigation works as expected.
}
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating {
	NSLog(@"--- unhiding animated=%d", animating);
	
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
	
	if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
		NSLog(@"<<< swipe right!");
		[self gotoPage:currentPageNumber - 1];
	} else if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
		NSLog(@">>> swipe left!");
		[self gotoPage:currentPageNumber + 1];
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
	} else if (tapPoint.x < leftTapHandler.frame.size.width) {
		NSLog(@"<-- TAP left!");
		[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber - 1] animated:YES];
		[self gotoPage:currentPageNumber - 1]; //TODO: handle multipage jumps
	} else if (tapPoint.x > rightTapHandler.frame.origin.x) {
		NSLog(@"--> TAP right!");
		[scrollView scrollRectToVisible:[self frameForPage:currentPageNumber + 1] animated:YES];
		[self gotoPage:currentPageNumber + 1]; //TODO: handle multipage jumps
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
		
		currentPageIsAnimating = YES;
		
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

// ****** PAGING
- (void)gotoPage:(int)pageNumber {
	/****************************************************************************************************
	 * Opens a specific page
	 */
	NSString *file = [NSString stringWithFormat:@"%d", pageNumber];
	NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"html" inDirectory:@"book"];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { //} && !currentPageIsAnimating) {
		NSLog(@"Goto Page: book/%d.html", pageNumber);
		
		currentPageIsAnimating = YES;
		//[currPage stopLoading];
		
		if ((pageNumber - currentPageNumber) > 0) {
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
			
			// Animate
			//[self animateHorizontalSlide:@"left" dx:-768 firstView:prevPage secondView:currPage];
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
			
			// Animate
			//[self animateHorizontalSlide:@"right" dx:768 firstView:nextPage secondView:currPage];
		}
	}
}
- (void)animateHorizontalSlide:(NSString *)name dx:(int)dx firstView:(UIWebView *)firstView secondView:(UIWebView *)secondView {
	
	[UIView beginAnimations:name context:nil]; {
		
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.35];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
	
		firstView.frame = CGRectOffset(firstView.frame, dx, 0);
		secondView.frame = CGRectOffset(secondView.frame, dx, 0);
	}
	
	[UIView commitAnimations];
}
- (void)animationDidStop:(NSString *)animationID finished:(BOOL)flag {
	NSLog(@"(animation ended) %@", animationID);
	
	// Let's try to avoid the "grey screen" UIWebView bug
	[self scrollPage:prevPage to:0 animating:NO];
	//[prevPage reload];
	[self scrollPage:nextPage to:0 animating:NO];
	//[nextPage reload];
	
	currentPageIsAnimating = NO;
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
	nextPage.delegate = nil;
	currPage.delegate = nil;
	prevPage.delegate = nil;
}
- (void)dealloc {
	[swipeRight release];
	[swipeLeft release];
	[nextPage release];
	[currPage release];
	[prevPage release];
    [super dealloc];
}

@end