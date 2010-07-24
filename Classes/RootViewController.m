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

@synthesize viewOne;
@synthesize viewTwo;
@synthesize swipeLeft;
@synthesize swipeRight;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.viewOne = [[UIWebView alloc] initWithFrame:CGRectMake(0,20,768,1004)];
	[self loadNewPage:viewOne filename:@"1" type:@"html" dir:@"book"];
	[[self view] addSubview:viewOne];
	[viewOne release];
	
	self.viewTwo = [[UIWebView alloc] initWithFrame:CGRectMake(768,20,768,1004)];
	[self loadNewPage:viewTwo filename:@"2" type:@"html" dir:@"book"];
	[[self view] addSubview:viewTwo];
	[viewTwo release];
	
	currentView = 1;
	
	self.swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
	[[self view] addGestureRecognizer:swipeLeft];
	[swipeLeft release];
	
	self.swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePage:)];
	swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
	[[self view] addGestureRecognizer:swipeRight];
	[swipeRight release];
}

- (void)loadNewPage:(UIWebView *)target filename:(NSString *)filename type:(NSString *)type dir:(NSString *)dir {
	
	NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:type inDirectory:dir];
	NSURL *url = [NSURL fileURLWithPath:path];
	
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];	
	[target loadRequest:requestObj];
}

- (void)swipePage:(UISwipeGestureRecognizer *)sender {
		
	NSLog(@"SWIPE!");
	
	//UIView Animation Method
	[UIView beginAnimations:nil context:nil]; {
		
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:1.0];
		[UIView setAnimationDelegate:self];
		
		switch(currentView) {
			case 1:
				if(sender.direction == UISwipeGestureRecognizerDirectionLeft) {
					viewOne.frame = CGRectOffset(viewOne.frame,-768,0);
					viewTwo.frame = CGRectOffset(viewTwo.frame,-768,0);
					currentView = 2;				
				} break;
			case 2:
				if(sender.direction == UISwipeGestureRecognizerDirectionRight) {
					viewOne.frame = CGRectOffset(viewOne.frame,768,0);
					viewTwo.frame = CGRectOffset(viewTwo.frame,768,0);
					currentView = 1;
				} break;
			default:
				break;
		}
	}
	
	[UIView commitAnimations];
	
	//CA Transition Method
	/*CATransition *swipe;
	swipe = [CATransition animation];
	[swipe setDuration:1.0];
	[swipe setType:kCATransitionPush];
	[swipe setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
	
	switch(currentView) {
		case 1:
			if(sender.direction == UISwipeGestureRecognizerDirectionLeft) {
				[swipe setSubtype:kCATransitionFromRight];
				viewOne.frame = CGRectOffset(viewOne.frame,-768,0);
				viewTwo.frame = CGRectOffset(viewTwo.frame,-768,0);
				[[self.view layer] addAnimation:swipe forKey:@"swipePage"];
				currentView = 2;
			} break;
		case 2:
			if(sender.direction == UISwipeGestureRecognizerDirectionRight) {
				[swipe setSubtype:kCATransitionFromLeft];
				viewOne.frame = CGRectOffset(viewOne.frame,768,0);
				viewTwo.frame = CGRectOffset(viewTwo.frame,768,0);
				[[self.view layer] addAnimation:swipe forKey:@"swipePage"];
				currentView = 1;
			} break;
		default:
			break;
	}*/
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
	
	self.viewOne = nil;
	self.viewTwo = nil;
	self.swipeLeft = nil;
	self.swipeRight = nil;
}

- (void)dealloc {
	
	[swipeRight release];
	[swipeLeft release];
	[viewTwo release];
	[viewOne release];
    [super dealloc];
}


@end
