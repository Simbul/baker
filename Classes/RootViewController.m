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

@implementation RootViewController

@synthesize prevPage;
@synthesize currPage;
@synthesize nextPage;

@synthesize swipeLeft;
@synthesize swipeRight;

@synthesize currentPageNumber;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        
		// Custom initialization		
		frameLeft = CGRectMake(-768,0,768,1024);
		frameCenter = CGRectMake(0,0,768,1024);
		frameRight = CGRectMake(768,0,768,1024);
		
		currentPageIsLast = NO;
		currentPageFirstLoading = YES;
		currentPageIsAnimating = NO;
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	[super viewDidLoad];
	
	// Permanently hide status bar
	[[UIApplication sharedApplication] setStatusBarHidden:YES];
	
	// Create left view
	self.prevPage = [[UIWebView alloc] initWithFrame:frameLeft];
	prevPage.delegate = self;
	[[self view] addSubview:prevPage];
	
	// Create center view
	self.currPage = [[UIWebView alloc] initWithFrame:frameCenter];
	currPage.delegate = self;
	currPage.hidden = YES;
	[[self view] addSubview:currPage];
	
	// Create right view
	self.nextPage = [[UIWebView alloc] initWithFrame:frameRight];
	nextPage.delegate = self;
	[[self view] addSubview:nextPage];
	
	// Check if there is a saved starting page
	NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
	NSString *currPageToLoad = [userDefs objectForKey:@"lastPageViewed"];
	if (currPageToLoad != nil)
		currentPageNumber = [currPageToLoad intValue];
	else
		currentPageNumber = 1;
	
	// Load starting pages inside views
	[self loadNewPage:currPage filename:currPageToLoad type:@"html" dir:@"book"];		
	if (currentPageNumber > 1) {
		NSString *prevPageToLoad = [NSString stringWithFormat:@"%d",currentPageNumber-1];
		[self loadNewPage:prevPage filename:prevPageToLoad type:@"html" dir:@"book"];
	}
	
	NSString *nextPageToLoad = [NSString stringWithFormat:@"%d",currentPageNumber+1];
	if (![self loadNewPage:nextPage filename:nextPageToLoad type:@"html" dir:@"book"])
		currentPageIsLast = YES;
	
	// Create tap handlers
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
	
	
	// Load swipe recognizers
	self.swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	[[self view] addGestureRecognizer:swipeLeft];
	[swipeLeft release];
	
	self.swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	[[self view] addGestureRecognizer:swipeRight];
	[swipeRight release];
}

- (BOOL)loadNewPage:(UIWebView *)target filename:(NSString *)filename type:(NSString *)type dir:(NSString *)dir {
	
	NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:type inDirectory:dir];
	
	if ([path length] > 0) {
		NSURL *url = [NSURL fileURLWithPath:path];
		NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];	
		[target loadRequest:requestObj];
		return YES;
	} else {
		// Path does not exist
		return NO;
	}
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	// Sent before a web view begins loading content, useful to trigger actions before the WebView.
	NSLog(@"-> Link: %@", [[request URL] absoluteString]);
	
	if ([[[request URL] scheme] isEqualToString:@"x-local"]) {
		NSLog(@"   x-local!", [[request URL] absoluteString]);
		//TODO
		return NO;
	}
	
	return YES; // Return YES to make sure regular navigation works as expected.
}

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
		if(currPageScrollIndex != nil)
			[self goDownInPage:currPageScrollIndex animating:NO];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSingleTap:) name:@"singleTap" object:nil];
		currentPageFirstLoading = NO;
		webView.hidden = NO;
	}
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

- (void)handleSingleTap:(NSNotification *)notification {
	
	// Get the coordinates of the tap with the currPage as reference...
	UITouch *tap = (UITouch *)[notification object];
	CGPoint tapCoordinates = [tap locationInView:currPage];
	
	NSLog(@"SINGLE TAP on coordinates x:%f and y:%f", tapCoordinates.x, tapCoordinates.y);
	
	// ...and swipe or scroll the page.
	if (tapCoordinates.y < upTapHandler.frame.size.height) {
		NSLog(@"TAP up!");
		[self goUpInPage:@"1004" animating:YES];
	} else if (tapCoordinates.y > (downTapHandler.frame.origin.y-20)) {
		NSLog(@"TAP down!");
		[self goDownInPage:@"1004" animating:YES];
	} else if (tapCoordinates.x < leftTapHandler.frame.size.width) {
		NSLog(@"TAP left!");
		[self goToPrevPage];
	} else if (tapCoordinates.x > rightTapHandler.frame.origin.x) {
		NSLog(@"TAP right!");
		[self goToNextPage];
	}
}

- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSLog(@"Scrolling page up");
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	offset = [NSString stringWithFormat:@"%d", ([currPageOffset intValue]-[offset intValue])];
	[self scrollPage:offset animating:animating];
}

- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSLog(@"Scrolling page down");
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	offset = [NSString stringWithFormat:@"%d", ([currPageOffset intValue]+[offset intValue])];
	[self scrollPage:offset animating:animating];
}

- (void)scrollPage:(NSString *)offset animating:(BOOL)animating {

	NSString *jsCommand = [NSString stringWithFormat:@"window.scrollTo(0,%@);", offset];
	
	if (animating) {
		
		currentPageIsAnimating = YES;
		
		[UIView beginAnimations:@"scrollPage" context:nil]; {
		
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[UIView setAnimationDuration:0.35];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
		
			[currPage stringByEvaluatingJavaScriptFromString:jsCommand];
		}
		[UIView commitAnimations];
	
	} else {
		[currPage stringByEvaluatingJavaScriptFromString:jsCommand];
	}
}

- (void)swipePage:(UISwipeGestureRecognizer *)sender {
	
	if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
		NSLog(@"SWIPE right!");
		[self goToPrevPage];
	} else if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
		NSLog(@"SWIPE left!");
		[self goToNextPage];
	} 
}

- (void)goToPrevPage {
	
	NSLog(@"Go to previous page from page %d", currentPageNumber);
	
	if (currentPageNumber != 1 && !currentPageIsAnimating) {
		// Move views
		currentPageIsAnimating = YES;
		nextPage.frame = frameLeft;
		[self animateHorizontalSlide:@"right" dx:768 firstView:currPage secondView:prevPage];
	}
}

- (void)goToNextPage {
	
	NSLog(@"Go to  next page from page %d", currentPageNumber);
	
	if(!currentPageIsLast && !currentPageIsAnimating) {
		// Move views
		currentPageIsAnimating = YES;
		prevPage.frame = frameRight;
		[self animateHorizontalSlide:@"left" dx:-768 firstView:currPage secondView:nextPage];
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
	
	NSLog(@"stop %@", animationID);
	
	if ([animationID isEqualToString:@"left"]) {
		// Update pointers
		currentPageNumber += 1;
		
		NSLog(@"went forward to page %d", currentPageNumber);
		UIWebView *tmpView = prevPage;
		prevPage = currPage;
		currPage = nextPage;
		nextPage = tmpView;
		
		// Preload next page
		NSString *file = [NSString stringWithFormat:@"%d", currentPageNumber+1];
		if (![self loadNewPage:nextPage filename:file type:@"html" dir:@"book"]) {
			// Could not load: no more pages
			NSLog(@"Could not load %@.html", file);
			currentPageIsLast = YES;
		}
		
		[prevPage stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0,0);"];
		
	} else if ([animationID isEqualToString:@"right"]) {
		// Update pointers
		currentPageNumber -= 1;
		currentPageIsLast = NO;
		
		NSLog(@"went back to page %d", currentPageNumber);
		UIWebView *tmpView = nextPage;
		nextPage = currPage;
		currPage = prevPage;
		prevPage = tmpView;
		
		// Preload previous page
		if (currentPageNumber > 1) {
			NSString *file = [NSString stringWithFormat:@"%d", currentPageNumber-1];
			[self loadNewPage:prevPage filename:file type:@"html" dir:@"book"];
		}
		
		[nextPage stringByEvaluatingJavaScriptFromString:@"window.scrollTo(0,0);"];		
	}
	
	currentPageIsAnimating = NO;
}

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