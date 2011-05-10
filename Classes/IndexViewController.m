//
//  IndexViewController.m
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

#import "IndexViewController.h"

#define NAVIGATION_HEIGHT 150


@implementation IndexViewController

- (id)initWithBookBundlePath:(NSString *)path fileName:(NSString *)name webViewDelegate:(UIViewController *)delegate {
    bookBundlePath = path;
    fileName = name;
    webViewDelegate = delegate;
    currentOrientation = UIInterfaceOrientationPortrait;
    
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 1024, 768, NAVIGATION_HEIGHT)];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.delegate = self;
    
    self.view = webView;
    [webView release];
    
    [self loadContent];
}

- (BOOL)isIndexViewHidden {
    if (currentOrientation == UIInterfaceOrientationPortrait || currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return self.view.frame.origin.y > 1024 - NAVIGATION_HEIGHT;
    } else {
        return self.view.frame.origin.y > 768 - NAVIGATION_HEIGHT;
    }

}

- (void)setIndexViewHidden:(BOOL)hidden withAnimation:(BOOL)animation {
    if (currentOrientation == UIInterfaceOrientationPortrait || currentOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        if (hidden) {
            self.view.frame = CGRectMake(0, 1024, 768, NAVIGATION_HEIGHT);
        } else {
            self.view.frame = CGRectMake(0, 1024 - NAVIGATION_HEIGHT, 768, NAVIGATION_HEIGHT);
        }
    } else {
        if (hidden) {
            self.view.frame = CGRectMake(0, 768, 1024, NAVIGATION_HEIGHT);
        } else {
            self.view.frame = CGRectMake(0, 768 - NAVIGATION_HEIGHT, 1024, NAVIGATION_HEIGHT);
        }
    }
}

- (void)rotateFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation toOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        if ([self isIndexViewHidden]) {
            self.view.frame = CGRectMake(0, 768, 1024, NAVIGATION_HEIGHT);
        } else {
            self.view.frame = CGRectMake(0, 768 - NAVIGATION_HEIGHT, 1024, NAVIGATION_HEIGHT);
        }
    } else {
        if ([self isIndexViewHidden]) {
            self.view.frame = CGRectMake(0, 1024, 768, NAVIGATION_HEIGHT);
        } else {
            self.view.frame = CGRectMake(0, 1024 - NAVIGATION_HEIGHT, 768, NAVIGATION_HEIGHT);
        }
    }
    currentOrientation = toInterfaceOrientation;
}

- (void)loadContent {
    NSString *path = [bookBundlePath stringByAppendingPathComponent:fileName];
    
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[(UIWebView *)self.view loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
	}
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    // After the first load, point the delegate to the main view controller
    webView.delegate = webViewDelegate;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
