//
//  RootViewController.m
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright 2010 Xmas. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RootViewController.h"

@implementation RootViewController

@synthesize swipeLeft;
@synthesize swipeRight;

@synthesize prevPage;
@synthesize currPage;
@synthesize nextPage;

@synthesize currentPageNumber;
@synthesize currentPageIsLast;

@synthesize frameLeft;
@synthesize frameCenter;
@synthesize frameRight;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
		self.frameLeft = CGRectMake(-768,20,768,1004);
		self.frameCenter = CGRectMake(0,20,768,1004);
		self.frameRight = CGRectMake(768,20,768,1004);
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	UIWebView *webView;
	
	// Create center view
	webView = [[UIWebView alloc] initWithFrame:self.frameCenter];
	[self loadNewPage:webView filename:@"1" type:@"html" dir:@"book"];
	[[self view] addSubview:webView];
	self.currPage = webView;
	[webView release];
	
	// Create right view
	webView = [[UIWebView alloc] initWithFrame:self.frameRight];
	[self loadNewPage:webView filename:@"2" type:@"html" dir:@"book"];
	[[self view] addSubview:webView];
	self.nextPage = webView;
	[webView release];
	
	// Create left view
	webView = [[UIWebView alloc] initWithFrame:self.frameLeft];
	[[self view] addSubview:webView];
	self.prevPage = webView;
	[webView release];
		
	// Initialize pointers to pages
	self.currentPageNumber = 1;
	self.currentPageIsLast = FALSE;
	
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
	NSLog(@"loadNewPage %@ %@ %@", filename, type, dir);
	NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:type inDirectory:dir];
	
	if ([path length] == 0) {
		return FALSE;
	}
	
	NSURL *url = [NSURL fileURLWithPath:path];
	
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];	
	[target loadRequest:requestObj];
	
	return TRUE;
}

- (void)gotoNextPage {
	NSLog(@"gotoNextPage, from page %d", self.currentPageNumber);
	
	if (self.currentPageIsLast) {
		NSLog(@"Cannot go: last page reached");
		return;
	}
	
	// Move views
	self.prevPage.frame = self.frameRight;
	[self animateHorizontalSlide:@"left" dx:-768 firstView:self.currPage secondView:self.nextPage];
}

- (void)gotoPrevPage {
	NSLog(@"gotoPrevPage, from page %d", self.currentPageNumber);
	
	if (self.currentPageNumber == 1) {
		NSLog(@"Cannot go: first page reached");
		return;
	}
	
	// Moving left, away from last page
	self.currentPageIsLast = FALSE;
	
	// Move views
	self.nextPage.frame = self.frameLeft;
	[self animateHorizontalSlide:@"right" dx:768 firstView:self.currPage secondView:self.prevPage];
}

- (void)swipeAnimationDidStop:(NSString *)animationID finished:(BOOL)flag {
	NSLog(@"stop %@", animationID);
	
	if( [animationID isEqualToString:@"left"] ) {
		// Update pointers
		self.currentPageNumber += 1;
		
		NSLog(@"went forward to page %d", self.currentPageNumber);
		UIWebView *tmpView = self.prevPage;
		self.prevPage = self.currPage;
		self.currPage = self.nextPage;
		self.nextPage = tmpView;
		
		// Preload next page
		NSString *nextFile = [NSString stringWithFormat:@"%d", self.currentPageNumber+1];
		if (![self loadNewPage:self.nextPage filename:nextFile type:@"html" dir:@"book"]) {
			// Could not load: no more pages
			NSLog(@"Could not load %@.html", nextFile);
			self.currentPageIsLast = TRUE;
		} else {
			self.currentPageIsLast = FALSE;
		}
	} else if( [animationID isEqualToString:@"right"] ) {
		// Update pointers
		self.currentPageNumber -= 1;
		
		NSLog(@"went back to page %d", self.currentPageNumber);
		UIWebView *tmpView = self.prevPage;
		self.prevPage = self.nextPage;
		self.nextPage = self.currPage;
		self.currPage = tmpView;
		
		// Preload next page
		NSString *file = [NSString stringWithFormat:@"%d", self.currentPageNumber-1];
		if (![self loadNewPage:self.prevPage filename:file type:@"html" dir:@"book"]) {
			// Could not load: no more pages
			NSLog(@"Could not load %@.html", file);
		}
		
	}
	// NSLog(@"%f %f %f", self.prevPage.frame.origin.x, self.currPage.frame.origin.x, self.nextPage.frame.origin.x);
}

- (void)animateHorizontalSlide:(NSString *)name dx:(int)dx firstView:(UIWebView *)firstView secondView:(UIWebView *)secondView {
	[UIView beginAnimations:name context:nil]; {
		
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:1.0];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(swipeAnimationDidStop:finished:)];
		
		firstView.frame = CGRectOffset(firstView.frame, dx, 0);
		secondView.frame = CGRectOffset(secondView.frame, dx, 0);
	}
	
	[UIView commitAnimations];
}

- (void)swipePage:(UISwipeGestureRecognizer *)sender {
	if(sender.direction == UISwipeGestureRecognizerDirectionLeft) {
		NSLog(@"SWIPE left!");
		[self gotoNextPage];
	} else if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
		NSLog(@"SWIPE right!");
		[self gotoPrevPage];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}

- (void)didReceiveMemoryWarning {
    
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    
	[super viewDidUnload];
	
	self.prevPage = nil;
	self.currPage = nil;
	self.nextPage = nil;
	self.swipeLeft = nil;
	self.swipeRight = nil;
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
