    //
//  RootViewController.m
//  Baker
//
//  Created by Xmas on 10/22/07.
//  Copyright 2010 Xmas. All rights reserved.
//

#import "RootViewController.h"

@implementation RootViewController

@synthesize viewOne;
@synthesize viewTwo;

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
}

- (void)loadNewPage:(UIWebView *)target filename:(NSString *)filename type:(NSString *)type dir:(NSString *)dir {
	
	NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:type inDirectory:dir];
	NSURL *url = [NSURL fileURLWithPath:path];
	
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];	
	[target loadRequest:requestObj];
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
}

- (void)dealloc {
	
	[viewTwo dealloc];
	[viewOne dealloc];
    [super dealloc];
}


@end
