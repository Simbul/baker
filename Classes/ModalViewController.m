//
//  ModalViewController.m
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
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

@implementation ModalViewController
@synthesize delegate, toolbar, webView, btnGoBack, btnGoForward, spinner;


#pragma mark - INIT
- (id)init {
    /****************************************************************************************************
     * We are going to create the view programmatically in loadView. Skip this.
     */
    self = [super init];
    return self;
}
- (id)initWithUrl:(NSURL *)url {
    /****************************************************************************************************
     * This is the main way you'll be using this object.
     * Just create the object and call this function.
     */
    myUrl = url;
    
    return [self init];
}

#pragma mark - VIEW LIFECYCLE
- (void)loadView {
    /****************************************************************************************************
     * Creates the UI: buttons, toolbar, webview and container view.
     */
    
    // ****** Buttons
    UIBarButtonItem *btnClose = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:@selector(dismissAction:)];
    btnClose.style = UIBarButtonItemStyleBordered;
    
    UIBarButtonItem *btnAction = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:nil action:@selector(openInSafari:)];
    btnAction.style = UIBarButtonItemStyleBordered;
    
    btnGoBack = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back.png"] style:UIBarButtonItemStylePlain target:nil action:@selector(goBack:)];
    btnGoBack.style = UIBarButtonItemStylePlain;
    btnGoBack.width = 30;
    btnGoBack.enabled = NO;

    
    btnGoForward = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward.png"] style:UIBarButtonItemStylePlain target:nil action:@selector(goForward:)];
    btnGoForward.style = UIBarButtonItemStylePlain;
    btnGoForward.width = 30;
    btnGoForward.enabled = NO;
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.hidesWhenStopped = YES;
    spinner.frame = CGRectMake(3, 3, 25, 25);
    [spinner startAnimating];
    UIBarButtonItem *btnSpinner = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    btnSpinner.width = 30;
    
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    
    // ****** Add Toolbar
    toolbar = [UIToolbar new];
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 44);
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [toolbar sizeToFit];
    
    
    // ****** Add items to toolbar
    NSArray *items = [NSArray arrayWithObjects: btnClose, btnGoBack, btnGoForward, btnSpinner, spacer, btnAction, nil];
    [toolbar setItems:items animated:NO];
    
    
    uint screenWidth  = [[UIScreen mainScreen] bounds].size.width;
    uint screenHeight = [[UIScreen mainScreen] bounds].size.height;

    // ****** Add WebView
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 44, screenWidth, screenHeight - 44)];
    webView.backgroundColor = [UIColor underPageBackgroundColor];
    webView.contentMode = UIViewContentModeScaleToFill;
    webView.scalesPageToFit = YES;
    webView.delegate = self;
    
        
    // ****** View
    self.view = [UIView new];
    
    // Note: without setting the view.frame no other sizeToFit or autoresizeMask in object inside it will work.
    self.view.frame = CGRectMake(0, 0, screenWidth, screenHeight);
    [self.view sizeToFit];
    
    
    // ****** Attach
    [self.view addSubview:toolbar];
    [self.view addSubview:webView];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [webView loadRequest:[NSURLRequest requestWithURL:myUrl]];
}
- (void)viewDidUnload {
    /****************************************************************************************************
     * Deallocate objects here.
     */
}
- (void)dealloc {
	[super dealloc];
}

#pragma mark - WEBVIEW
- (void)webViewDidStartLoad:(UIWebView *)wv {     
    /****************************************************************************************************
     * Start loading a new page in the UIWebView.
     */
    NSLog(@"[Modal] Loading %@", wv.request.URL.absoluteURL);
    [spinner startAnimating];     
}
- (void)webViewDidFinishLoad:(UIWebView *)webViewIn {
    /****************************************************************************************************
     * Triggered when the WebView finish.
     * We reset the button status here.
     */
    NSLog(@"[Modal] Done.");
    
    // ****** Stop spinner
    [spinner stopAnimating];
    
    // ****** Update buttons
    btnGoBack.enabled = [webViewIn canGoBack];
    btnGoForward.enabled = [webViewIn canGoForward];
}

#pragma mark - ACTIONS
- (IBAction)dismissAction:(id)sender {
    /****************************************************************************************************
     * Close action, it calls the delegate object to unload itself.
     */
    [[self delegate] done:self];
}
- (IBAction)goBack:(id)sender {
    /****************************************************************************************************
     * WebView back button.
     */
    [webView goBack];
}
- (IBAction)goForward:(id)sender {
    /****************************************************************************************************
     * WebView forward button.
     */
    [webView goForward];
}
- (IBAction)openInSafari:(id)sender {
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
    webView.frame = CGRectMake(0, 44, screenWidth, screenHeight - 44);
}

@end
