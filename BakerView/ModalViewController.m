//
//  ModalViewController.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau
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
//  USAGE:
//
//  In the header (.h), add to @interface:
//
//      ModalViewController *modal;
//
//
//  In the controller (.m) use this function:
//
//      - (void)loadModalWebView:(NSURL *) url {
//          // initialize
//          myModalViewController = [[[ModalViewController alloc] initWithUrl:url] autorelease];
//          myModalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//          myModalViewController.delegate = self;
//
//          // hide the IndexView before opening modal web view
//          [self hideStatusBar];
//
//          // check if iOS4 or 5
//          if ([self respondsToSelector:@selector(presentViewController:animated:completion:)])
//              // iOS 5
//              [self presentViewController:myModalViewController animated:YES completion:nil];
//          else
//              // iOS 4
//              [self presentModalViewController:myModalViewController animated:YES];
//      }
//

#import "ModalViewController.h"
#import "UIColor+Extensions.h"
#import "UIConstants.h"
#import "Utils.h"

@implementation ModalViewController

@synthesize delegate;
@synthesize webView;
@synthesize toolbar;
@synthesize btnGoBack;
@synthesize btnGoForward;
@synthesize btnReload;
@synthesize spinner;

#pragma mark - INIT
- (id)initWithUrl:(NSURL *)url {
    /****************************************************************************************************
     * This is the main way you'll be using this object.
     * Just create the object and call this function.
     */

    self = [super init];
    if (self) {
        myUrl = url;
    }
    return self;
}

#pragma mark - VIEW LIFECYCLE
- (void)loadView {
    /****************************************************************************************************
     * Creates the UI: buttons, toolbar, webview and container view.
     */

    [super loadView];


    // ****** Buttons
    UIBarButtonItem *btnClose  = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"WEB_MODAL_CLOSE_BUTTON_TEXT", nil)
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(dismissAction)] autorelease];

    UIBarButtonItem *btnAction = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openInSafari)] autorelease];

    self.btnGoBack = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)] autorelease];
    btnGoBack.enabled = NO;
    btnGoBack.width = 30;

    self.btnGoForward = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:self action:@selector(goForward)] autorelease];
    btnGoForward.enabled = NO;
    btnGoForward.width = 30;

    self.btnReload = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadPage)] autorelease];
    btnReload.enabled = NO;
    btnGoForward.width = 30;

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        btnClose.tintColor = [UIColor colorWithHexString:ISSUES_ACTION_BUTTON_BACKGROUND_COLOR];
        btnAction.tintColor = [UIColor colorWithHexString:ISSUES_ACTION_BUTTON_BACKGROUND_COLOR];
        btnGoBack.tintColor = [UIColor colorWithHexString:ISSUES_ACTION_BUTTON_BACKGROUND_COLOR];
        btnGoForward.tintColor = [UIColor colorWithHexString:ISSUES_ACTION_BUTTON_BACKGROUND_COLOR];
        btnReload.tintColor = [UIColor colorWithHexString:ISSUES_ACTION_BUTTON_BACKGROUND_COLOR];
    }

    self.spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    spinner.frame = CGRectMake(3, 3, 25, 25);
    spinner.hidesWhenStopped = YES;

    [spinner startAnimating];

    UIBarButtonItem *btnSpinner = [[[UIBarButtonItem alloc] initWithCustomView:spinner] autorelease];
    btnSpinner.width = 30;

    UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];


    // ****** Add Toolbar
    self.toolbar = [[UIToolbar new] autorelease];
    toolbar.barStyle = UIBarStyleDefault;


    // ****** Add items to toolbar
    if ([[myUrl scheme] isEqualToString:@"file"])
    {
        NSArray *items = [NSArray arrayWithObjects: btnClose, btnGoBack, btnGoForward, btnSpinner, spacer, nil];
        [toolbar setItems:items animated:NO];
    }
    else
    {
        NSArray *items = [NSArray arrayWithObjects: btnClose, btnGoBack, btnGoForward, btnReload, btnSpinner, spacer, btnAction, nil];
        [toolbar setItems:items animated:NO];
    }


    // ****** Add WebView
    self.webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 44, 1, 1)] autorelease];
    webView.contentMode = UIViewContentModeScaleToFill;
    webView.scalesPageToFit = YES;
    webView.delegate = self;


    // ****** View
    self.view = [[UIView new] autorelease];


    // ****** Attach
    [self.view addSubview:toolbar];
    [self.view addSubview:webView];


    // ****** Set views starting frames according to current interface rotation
    [self willRotateToInterfaceOrientation:self.interfaceOrientation duration:0];
}
- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    [webView loadRequest:[NSURLRequest requestWithURL:myUrl]];
}
- (void)dealloc {

    [self.webView stopLoading];
    [self.webView removeFromSuperview];
    self.webView.delegate = nil;

    [btnGoBack release];
    [btnGoForward release];
    [btnReload release];

    [spinner release];
    [toolbar release];

    [webView release];

    [super dealloc];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - WEBVIEW
- (void)webViewDidStartLoad:(UIWebView *)webViewIn {
    /****************************************************************************************************
     * Start loading a new page in the UIWebView.
     */

    // NSLog(@"[Modal] Loading '%@'", [webViewIn.request.URL absoluteString]); <-- this isn't returning the URL correctly, check
    [spinner startAnimating];
}
- (void)webViewDidFinishLoad:(UIWebView *)webViewIn {
    /****************************************************************************************************
     * Triggered when the WebView finish.
     * We reset the button status here.
     */

    //NSLog(@"[Modal] Finish loading.");
    [[self delegate] webView:webViewIn setCorrectOrientation:self.interfaceOrientation];

    // ****** Stop spinner
    [spinner stopAnimating];

    // ****** Update buttons
    btnGoBack.enabled    = [webViewIn canGoBack];
    btnGoForward.enabled = [webViewIn canGoForward];
    btnReload.enabled = YES;
}
- (void)webView:(UIWebView *)webViewIn didFailLoadWithError:(NSError *)error {
    NSLog(@"[Modal] Failed to load '%@', error code %i", [webViewIn.request.URL absoluteString], [error code]);
    if ([error code] == -1009) {
        UILabel *errorLabel = [[[UILabel alloc] initWithFrame:self.webView.frame] autorelease];
        errorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        errorLabel.textAlignment = NSTextAlignmentCenter;
        errorLabel.textColor = [UIColor grayColor];
        errorLabel.text = NSLocalizedString(@"WEB_MODAL_FAILURE_MESSAGE", nil);
        errorLabel.numberOfLines = 1;

        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        if (screenBounds.size.width < 768) {
            errorLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        } else {
            errorLabel.font = [UIFont fontWithName:@"Helvetica" size:18.0];
        }

        [self.view addSubview:errorLabel];
    }

    // ****** Stop spinner
    [spinner stopAnimating];
}

#pragma mark - ACTIONS
- (void)dismissAction {
    /****************************************************************************************************
     * Close action, it calls the delegate object to unload itself.
     */

    [[self delegate] closeModalWebView];
}
- (void)goBack {
    /****************************************************************************************************
     * WebView back button.
     */

    [webView goBack];
}
- (void)goForward {
    /****************************************************************************************************
     * WebView forward button.
     */

    [webView goForward];
}
- (void)reloadPage {
    /****************************************************************************************************
     * WebView reload button.
     */
    
    [webView reload];
}
- (void)openInSafari {
    /****************************************************************************************************
     * Open in Safari.
     * In the future this will trigger the panel to choose between different actions.
     */

    [[UIApplication sharedApplication] openURL:webView.request.URL];
}

#pragma mark - ORIENTATION
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    /****************************************************************************************************
     * We'll use our delegate object to check if we can autorotate or not.
     */

    return [[self delegate] shouldAutorotateToInterfaceOrientation:orientation];
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    uint screenWidth  = 0;
    uint screenHeight = 0;

    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
    {
        screenWidth  = [[UIScreen mainScreen] bounds].size.width;
        screenHeight = [[UIScreen mainScreen] bounds].size.height;
    }
    else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        screenWidth  = [[UIScreen mainScreen] bounds].size.height;
        screenHeight = [[UIScreen mainScreen] bounds].size.width;
    }

    self.view.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    toolbar.frame = CGRectMake(0, 0, screenWidth, 44);
    webView.frame = CGRectMake(0, 44, screenWidth, screenHeight - 44);

    [[self delegate] webView:webView setCorrectOrientation:toInterfaceOrientation];
}

@end
