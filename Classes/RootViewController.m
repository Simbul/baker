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

@synthesize prevPage;
@synthesize currPage;
@synthesize nextPage;

@synthesize swipeLeft;
@synthesize swipeRight;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
		frameLeft = CGRectMake(-768,20,768,1004);
		frameCenter = CGRectMake(0,20,768,1004);
		frameRight = CGRectMake(768,20,768,1004);
		
		currentPageNumber = 1;
		currentPageIsLast = NO;
		animating = NO;
    }
    return self;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Create left view
	self.prevPage = [[UIWebView alloc] initWithFrame:frameLeft];
	[[self view] addSubview:prevPage];
	
	// Create center view
	self.currPage = [[UIWebView alloc] initWithFrame:frameCenter];
	[[self view] addSubview:currPage];
	
	// Create right view
	self.nextPage = [[UIWebView alloc] initWithFrame:frameRight];
	[[self view] addSubview:nextPage];
	
	// Load default pages inside views
	[self loadNewPage:currPage filename:@"1" type:@"html" dir:@"book"];
	[self loadNewPage:nextPage filename:@"2" type:@"html" dir:@"book"];
	
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

- (void)swipePage:(UISwipeGestureRecognizer *)sender {
	if(sender.direction == UISwipeGestureRecognizerDirectionLeft) {
		NSLog(@"SWIPE left!");
		[self gotoNextPage];
	} else if (sender.direction == UISwipeGestureRecognizerDirectionRight) {
		NSLog(@"SWIPE right!");
		[self gotoPrevPage];
	}
}

- (void)gotoPrevPage {
	NSLog(@"gotoPrevPage, from page %d", currentPageNumber);
	
	if (currentPageNumber == 1) {
		NSLog(@"Cannot go: first page reached");
		return;
	}
	
	if (animating) {
		NSLog(@"Cannot go: page turning in progress");
		return;
	}
	animating = TRUE;
	
	// Moving left, away from last page
	currentPageIsLast = FALSE;
	
	// Move views
	nextPage.frame = frameLeft;
	[self animateHorizontalSlide:@"right" dx:768 firstView:currPage secondView:prevPage];
}

- (void)gotoNextPage {
	NSLog(@"gotoNextPage, from page %d", currentPageNumber);
	
	if (currentPageIsLast) {
		NSLog(@"Cannot go: last page reached");
		return;
	}
	
	if (animating) {
		NSLog(@"Cannot go: page turning in progress");
		return;
	}
	animating = TRUE;
	
	// Move views
	prevPage.frame = frameRight;
	[self animateHorizontalSlide:@"left" dx:-768 firstView:currPage secondView:nextPage];
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

- (void)swipeAnimationDidStop:(NSString *)animationID finished:(BOOL)flag {
	NSLog(@"stop %@", animationID);
	
	if( [animationID isEqualToString:@"left"] ) {
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
	} else if( [animationID isEqualToString:@"right"] ) {
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
