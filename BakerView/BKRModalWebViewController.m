//
//  ModalViewController.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau, Pieter Claerhout
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
//  ==========================================================================================
//

#import "BKRModalWebViewController.h"
#import "UIColor+BakerExtensions.h"
#import "BKRUtils.h"
#import "BKRSettings.h"

#import "UIScreen+BakerExtensions.h"

@implementation BKRModalWebViewController

#pragma mark - Initialization

- (id)initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        _initialURL = url;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)loadView {

    [super loadView];

    // ****** Buttons
    UIBarButtonItem *btnClose  = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"WEB_MODAL_CLOSE_BUTTON_TEXT", nil)
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(dismissAction)];

    UIBarButtonItem *btnAction = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openInSafari)];

    self.btnGoBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.btnGoBack.enabled = NO;
    self.btnGoBack.width   = 30;

    self.btnGoForward = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
    self.btnGoForward.enabled = NO;
    self.btnGoForward.width   = 30;

    self.btnReload = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadPage)];
    self.btnReload.enabled  = NO;
    self.btnGoForward.width = 30;

    btnClose.tintColor          = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionBackgroundColor];
    btnAction.tintColor         = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionBackgroundColor];
    self.btnGoBack.tintColor    = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionBackgroundColor];
    self.btnGoForward.tintColor = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionBackgroundColor];
    self.btnReload.tintColor    = [UIColor bkrColorWithHexString:[BKRSettings sharedSettings].issuesActionBackgroundColor];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.frame            = CGRectMake(3, 3, 25, 25);
    self.spinner.hidesWhenStopped = YES;

    [self.spinner startAnimating];

    UIBarButtonItem *btnSpinner = [[UIBarButtonItem alloc] initWithCustomView:self.spinner];
    btnSpinner.width = 30;

    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    // ****** Add Toolbar
    self.toolbar          = [UIToolbar new];
    self.toolbar.barStyle = UIBarStyleDefault;

    // ****** Add items to toolbar
    if ([self.initialURL.scheme isEqualToString:@"file"]) {
        NSArray *items = @[btnClose, self.btnGoBack, self.btnGoForward, btnSpinner, spacer];
        [self.toolbar setItems:items animated:NO];
    } else {
        NSArray *items = @[btnClose, self.btnGoBack, self.btnGoForward, self.btnReload, btnSpinner, spacer, btnAction];
        [self.toolbar setItems:items animated:NO];
    }

    // ****** Add WebView
    self.webView                 = [[UIWebView alloc] initWithFrame:CGRectMake(0, 44, 1, 1)];
    self.webView.contentMode     = UIViewContentModeScaleToFill;
    self.webView.scalesPageToFit = YES;
    self.webView.delegate        = self;

    // ****** View
    self.view = [UIView new];

    // ****** Attach
    [self.view addSubview:self.toolbar];
    [self.view addSubview:self.webView];

    // ****** Set views starting frames according to current interface rotation
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.initialURL]];
}

- (void)dealloc {
    [self.webView stopLoading];
    [self.webView removeFromSuperview];
    self.webView.delegate = nil;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView*)webViewIn {
    // NSLog(@"[Modal] Loading '%@'", [webViewIn.request.URL absoluteString]); <-- this isn't returning the URL correctly, check
    [self.spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView*)webViewIn {

    //NSLog(@"[Modal] Finish loading.");
    [self.delegate webView:webViewIn setCorrectOrientation:self.interfaceOrientation];

    [self.spinner stopAnimating];

    self.btnGoBack.enabled    = [webViewIn canGoBack];
    self.btnGoForward.enabled = [webViewIn canGoForward];
    self.btnReload.enabled    = YES;
    
}

- (void)webView:(UIWebView*)webViewIn didFailLoadWithError:(NSError*)error {
    NSLog(@"[Modal] Failed to load '%@', error code %li", [webViewIn.request.URL absoluteString], (long)error.code);
    if (error.code == -1009) {

        UILabel *errorLabel = [[UILabel alloc] initWithFrame:self.webView.frame];
        errorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        errorLabel.textAlignment    = NSTextAlignmentCenter;
        errorLabel.textColor        = [UIColor grayColor];
        errorLabel.text             = NSLocalizedString(@"WEB_MODAL_FAILURE_MESSAGE", nil);
        errorLabel.numberOfLines    = 1;
        
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        if (MIN(screenBounds.size.width, screenBounds.size.height) < 768) {
            errorLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        } else {
            errorLabel.font = [UIFont fontWithName:@"Helvetica" size:18.0];
        }

        [self.view addSubview:errorLabel];
    }

    [self.spinner stopAnimating];
}

#pragma mark - Actions

- (void)dismissAction {
    [[self delegate] closeModalWebView];
}

- (void)goBack {
    [self.webView goBack];
}

- (void)goForward {
    [self.webView goForward];
}

- (void)reloadPage {
    [self.webView reload];
}

- (void)openInSafari {
    [[UIApplication sharedApplication] openURL:self.webView.request.URL];
}

#pragma mark - Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [self.delegate shouldAutorotateToInterfaceOrientation:orientation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    CGFloat screenWidth  = [[UIScreen mainScreen] bkrWidthForOrientation:toInterfaceOrientation];
    CGFloat screenHeight = [[UIScreen mainScreen] bkrHeightForOrientation:toInterfaceOrientation];

    self.view.frame    = CGRectMake(0, 0, screenWidth, screenHeight);
    self.toolbar.frame = CGRectMake(0, 0, screenWidth, 44);
    self.webView.frame = CGRectMake(0, 44, screenWidth, screenHeight - 44);

    [self.delegate webView:self.webView setCorrectOrientation:toInterfaceOrientation];
    
}

@end
