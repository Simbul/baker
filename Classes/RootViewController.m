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
		frameLeft = CGRectMake(-768,20,768,1004);
		frameCenter = CGRectMake(0,20,768,1004);
		frameRight = CGRectMake(768,20,768,1004);
		
		currentPageIsLast = NO;
		currentPageFirstLoading = YES;
		animating = NO;
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
	[super viewDidLoad];
	
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

	// Load swipe recognizers
	self.swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	[[self view] addGestureRecognizer:swipeLeft];
	[swipeLeft release];
	
	self.swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	[[self view] addGestureRecognizer:swipeRight];
	[swipeRight release];
	
	// Create tap handlers
	rightTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(718,20,50,1004)];
	[[self view] addSubview:rightTapHandler];
	[rightTapHandler release];
	
	leftTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(0,20,50,1004)];
	[[self view] addSubview:leftTapHandler];
	[leftTapHandler release];
	
	downTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(50,974,668,50)];
	[[self view] addSubview:downTapHandler];
	[downTapHandler release];
	
	upTapHandler = [[TapHandler alloc] initWithFrame:CGRectMake(50,20,668,50)];
	[[self view] addSubview:upTapHandler];
	[upTapHandler release];
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
	
	// Sent before a web view begins loading content.
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	
	// Sent before a web view begins loading content.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
		
	// Sent after a web view finishes loading content.
	
	//If is the first time i load something in the currPage web view...
	if (webView == currPage && currentPageFirstLoading) {
		
		NSLog(@"currPage finished first loading");
		
		// ...check if there is a saved starting scroll index and set it
		NSUserDefaults *userDefs = [NSUserDefaults standardUserDefaults];
		NSString *currPageScrollIndex = [userDefs objectForKey:@"lastScrollIndex"];
		if(currPageScrollIndex != nil)
			[self scrollPage:currPageScrollIndex];
		
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

- (void)swipePage:(UISwipeGestureRecognizer *)sender {
	
	if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
		NSLog(@"SWIPE right!");
		[self gotoPrevPage];
	} else if (sender.direction == UISwipeGestureRecognizerDirectionLeft) {
		NSLog(@"SWIPE left!");
		[self gotoNextPage];
	} 
}

- (void)handleSingleTap:(NSNotification *)notification {
	
	NSLog(@"TAP!");
	// Get the coordinates of the tap with the currPage as reference...
	UITouch *tap = (UITouch *)[notification object];
	CGPoint tapCoordinates = [tap locationInView:currPage];
	// ...and swipe or scroll the page.
	if (tapCoordinates.x > rightTapHandler.frame.origin.x) 
		[self gotoNextPage];
	else if (tapCoordinates.x < leftTapHandler.frame.size.width)
		[self gotoPrevPage];
	else if (tapCoordinates.y > downTapHandler.frame.origin.y)
		[self scrollPage:@"DOWN"];
	else if (tapCoordinates.y < upTapHandler.frame.size.height)
		[self scrollPage:@"UP"];
}

- (void)scrollPage:(NSString *)offset {
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	if ([offset isEqualToString:@"UP"])
		offset = [NSString stringWithFormat:@"%d", ([currPageOffset intValue]-1004)];
	else if ([offset isEqualToString:@"DOWN"])
		offset = [NSString stringWithFormat:@"%d", ([currPageOffset intValue]+1004)];

	NSString *jsCommand = [NSString stringWithFormat:@"window.scrollTo(0,%@);", offset];
	[currPage stringByEvaluatingJavaScriptFromString:jsCommand];
}

- (void)gotoPrevPage {
	
	NSLog(@"Go to previous page from page %d", currentPageNumber);
	
	if (currentPageNumber != 1 && !animating) {
		// Move views
		animating = YES;
		nextPage.frame = frameLeft;
		[self animateHorizontalSlide:@"right" dx:768 firstView:currPage secondView:prevPage];
	}
}

- (void)gotoNextPage {
	
	NSLog(@"Go to  next page from page %d", currentPageNumber);
	
	if(!currentPageIsLast && !animating) {
		// Move views
		animating = YES;
		prevPage.frame = frameRight;
		[self animateHorizontalSlide:@"left" dx:-768 firstView:currPage secondView:nextPage];
	}
}

- (void)animateHorizontalSlide:(NSString *)name dx:(int)dx firstView:(UIWebView *)firstView secondView:(UIWebView *)secondView {
	
	[UIView beginAnimations:name context:nil]; {
		
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.35];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(swipeAnimationDidStop:finished:)];
	
		firstView.frame = CGRectOffset(firstView.frame, dx, 0);
		secondView.frame = CGRectOffset(secondView.frame, dx, 0);
	}
	
	[UIView commitAnimations];
}

- (void)swipeAnimationDidStop:(NSString *)animationID finished:(BOOL)flag {
	
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
	
	animating = NO;
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