
//
//  PageViewController.m
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import "PageViewController.h"

@interface PageViewController ()

@end

@implementation PageViewController

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        //Setup View for Page
        self.view = [[UIView alloc] initWithFrame:frame];
        
        // ****** INIT PROPERTIES
        _properties = [Properties properties];
        
        //Get Page Number Alpha
        _pageNumberAlpha = [_properties get:@"-baker-page-numbers-alpha", nil];
        
        //Get Page Number Color
        _pageNumberColor = [Utils colorWithHexString:[_properties get:@"-baker-page-numbers-color", nil]];
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // ****** Background Image
    _backgroundImageView = [[[UIImageView alloc] initWithFrame:self.view.frame] autorelease];
    [self.view addSubview:_backgroundImageView];
    
    // ****** Activity Indicator
    _activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    _activityIndicatorView.backgroundColor = [UIColor clearColor];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
            _activityIndicatorView.color = _pageNumberColor;
            _activityIndicatorView.alpha = [_pageNumberAlpha floatValue];
    };
    
    CGSize pageSize = self.view.frame.size;
    CGRect frame = _activityIndicatorView.frame;
    
    frame.origin.x = (pageSize.width - frame.size.width) / 2;
    frame.origin.y = (pageSize.height - frame.size.height) / 2;
    _activityIndicatorView.frame = frame;
        
    [_activityIndicatorView startAnimating];
    [self.view addSubview:_activityIndicatorView];
            
    // ****** Numbers
    _numberLabel = [[[UILabel alloc] initWithFrame:CGRectMake((pageSize.width - 115) / 2, pageSize.height / 2 - 55, 115, 30)] autorelease];
    _numberLabel.backgroundColor = [UIColor clearColor];
    _numberLabel.font = [UIFont fontWithName:@"Helvetica" size:40.0];
    _numberLabel.text = @"0";
    _numberLabel.textColor = _pageNumberColor;
    _numberLabel.textAlignment = UITextAlignmentCenter;
    _numberLabel.alpha = [_pageNumberAlpha floatValue];
    
    [self.view addSubview:_numberLabel];
}

- (void)viewWillAppear:(BOOL)animated{
    
    //Make Sure Number Label is updated to show relevant page number
    _numberLabel.text = [NSString stringWithFormat:@"%d", self.tag];
    
}

- (void)loadPage:(NSString*)pageURL{
    
    // ****** Title
    
    //Remove and Release Exsisting Title Label if it exsists already
    if (_titleLabel){
        [_titleLabel removeFromSuperview];
        [_titleLabel release];
        _titleLabel = nil;
    }
    
    CGSize pageSize = self.view.frame.size;
    
    _titleLabel = [[[PageTitleLabel alloc]initWithFile:pageURL] autorelease];
    [_titleLabel setX:((pageSize.width - _titleLabel.frame.size.width) / 2) Y:(pageSize.height / 2 + 20)];
    [self.view addSubview:_titleLabel];
    
    // ****** Webview
    
    //Remove and Release Exsisting Web View if it exsists already
    if (_webView){
        [_webView removeFromSuperview];
        [_webView release];
        _webView = nil;
    }
    
    _webView = [[[UIWebView alloc] initWithFrame:self.view.frame] autorelease];
    _webView.hidden = YES;
}

- (void)setTag:(int)tag{
    self.view.tag = tag;
}

- (int)tag{
    return self.view.tag;
}


#pragma mark - WEBVIEW
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    // Sent before a web view begins loading content, useful to trigger actions before the WebView.
    NSLog(@"• Should webView load the page ?");
    NSURL *url = [request URL];
    
    if ([webView isEqual:prevPage])
    {
        NSLog(@"    Page is prev page --> load page");
        return YES;
    }
    else if ([webView isEqual:nextPage])
    {
        NSLog(@"    Page is next page --> load page");
        return YES;
    }
    else if (currentPageIsDelayingLoading)
    {
        NSLog(@"    Page is current page and current page IS delaying loading --> load page");
        currentPageIsDelayingLoading = NO;
        return ![self isIndexView:webView];
    }
    else
    {
        // ****** Handle URI schemes
        if (url)
        {
            // Existing, checking if index...
            if([[url relativePath] isEqualToString:[indexViewController indexPath]])
            {
                NSLog(@"    Page is index --> load index");
                return YES;
            }
            else
            {
                NSLog(@"    Page is current page and current page IS NOT delaying loading --> handle clicked link: %@", [url absoluteString]);
                
                // Not index, checking scheme...
                if ([[url scheme] isEqualToString:@"file"])
                {
                    // ****** Handle: file://
                    NSLog(@"    Page is a link with scheme file:// --> load internal link");
                    
                    anchorFromURL  = [[url fragment] retain];
                    NSString *file = [[url relativePath] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    
                    int page = [pages indexOfObject:file];
                    if (page == NSNotFound)
                    {
                        // ****** Internal link, but not one of the book pages --> load page anyway
                        return YES;
                    }
                    
                    page = page + 1;
                    if (![self changePage:page] && ![webView isEqual:indexViewController.view])
                    {
                        if (anchorFromURL == nil) {
                            return YES;
                        }
                        
                        [self handleAnchor:YES];
                    }
                }
                else if ([[url scheme] isEqualToString:@"book"])
                {
                    // ****** Handle: book://
                    NSLog(@"    Page is a link with scheme book:// --> download new book");
                    
                    if ([[url host] isEqualToString:@"local"] && [[NSFileManager defaultManager] fileExistsAtPath:bundleBookPath]) {
                        // *** Back to bundled book
                        feedbackAlert = [[UIAlertView alloc] initWithTitle:@""
                                                                   message:[NSString stringWithFormat:CLOSE_BOOK_MESSAGE]
                                                                  delegate:self
                                                         cancelButtonTitle:ALERT_FEEDBACK_CANCEL
                                                         otherButtonTitles:CLOSE_BOOK_CONFIRM, nil];
                        [feedbackAlert show];
                        [feedbackAlert release];
                        
                    } else {
                        
                        if ([[url pathExtension] isEqualToString:@"html"]) {
                            anchorFromURL = [[url fragment] retain];
                            pageNameFromURL = [[[url lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] retain];
                            NSString *tmpUrl = [[url URLByDeletingLastPathComponent] absoluteString];
                            url = [NSURL URLWithString:[tmpUrl stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]]];
                        }
                        
                        // ****** Download book
                        URLDownload = [[@"http:" stringByAppendingString:[url resourceSpecifier]] retain];
                        
                        if ([[[NSURL URLWithString:URLDownload] pathExtension] isEqualToString:@""]) {
                            URLDownload = [[URLDownload stringByAppendingString:@".hpub"] retain];
                        }
                        
                        [self downloadBook:nil];
                    }
                }
                else if ([[url scheme] isEqualToString:@"mailto"])
                {
                    // Handle mailto links using MessageUI framework
                    NSLog(@"    Page is a link with scheme mailto: handle mail link");
                    
                    // Build temp array and dictionary
                    NSArray *tempArray = [[url absoluteString] componentsSeparatedByString:@"?"];
                    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
                    
                    // Check array count to see if we have parameters to query
                    if ([tempArray count] == 2)
                    {
                        NSArray *keyValuePairs = [[tempArray objectAtIndex:1] componentsSeparatedByString:@"&"];
                        
                        for (NSString *queryString in keyValuePairs) {
                            NSArray *keyValuePair = [queryString componentsSeparatedByString:@"="];
                            if (keyValuePair.count == 2) {
                                [queryDictionary setObject:[keyValuePair objectAtIndex:1] forKey:[keyValuePair objectAtIndex:0]];
                            }
                        }
                    }
                    
                    NSString *email = ([tempArray objectAtIndex:0]) ? [tempArray objectAtIndex:0] : [url resourceSpecifier];
                    NSString *subject = [queryDictionary objectForKey:@"subject"];
                    NSString *body = [queryDictionary objectForKey:@"body"];
                    
                    [queryDictionary release];
                    
                    if ([MFMailComposeViewController canSendMail])
                    {
                        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
                        
                        mailer.mailComposeDelegate = self;
                        mailer.modalPresentationStyle = UIModalPresentationPageSheet;
                        
                        [mailer setToRecipients:[NSArray arrayWithObject:[email stringByReplacingOccurrencesOfString:@"mailto:" withString:@""]]];
                        [mailer setSubject:[subject stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                        [mailer setMessageBody:[body stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] isHTML:NO];
                        
                        // Show the view
                        [self presentModalViewController:mailer animated:YES];
                        [mailer release];
                    }
                    else
                    {
                        // Check if the system can handle a mailto link
                        if ([[UIApplication sharedApplication] canOpenURL:url])
                        {
                            // Go for it and open the URL within the respective app
                            [[UIApplication sharedApplication] openURL: url];
                        }
                        else
                        {
                            // Display error message
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                                            message:@"Your device doesn't support the sending of emails!"
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                            
                            [alert show];
                            [alert release];
                        }
                    }
                    
                    return NO;
                }
                else if (![[url scheme] isEqualToString:@""] && ![[url scheme] isEqualToString:@"http"] && ![[url scheme] isEqualToString:@"https"])
                {
                    [[UIApplication sharedApplication] openURL:url];
                    return NO;
                }
                else
                {
                    // **************************************************************************************************** OPEN OUTSIDE BAKER
                    // * This is required since the inclusion of external libraries (like Google Maps) requires
                    // * direct opening of external pages within Baker. So we have to handle when you want to actually
                    // * open a page outside of Baker.
                    
                    NSString *params = [url query];
                    NSLog(@"    Opening absolute URL: %@", [url absoluteString]);
                    
                    if (params != nil)
                    {
                        NSRegularExpression *referrerExternalRegex = [NSRegularExpression regularExpressionWithPattern:URL_OPEN_EXTERNAL options:NSRegularExpressionCaseInsensitive error:NULL];
                        NSUInteger matches = [referrerExternalRegex numberOfMatchesInString:params options:0 range:NSMakeRange(0, [params length])];
                        
                        NSRegularExpression *referrerModalRegex = [NSRegularExpression regularExpressionWithPattern:URL_OPEN_MODALLY options:NSRegularExpressionCaseInsensitive error:NULL];
                        NSUInteger matchesModal = [referrerModalRegex numberOfMatchesInString:params options:0 range:NSMakeRange(0, [params length])];
                        
                        if (matches > 0)
                        {
                            NSLog(@"    Link contain param \"%@\" --> open link in Safari", URL_OPEN_EXTERNAL);
                            
                            // Generate new URL without
                            // We are regexp-ing three things: the string alone, the string first with other content, the string with other content in any other position
                            NSRegularExpression *replacerRegexp = [NSRegularExpression regularExpressionWithPattern:[[NSString alloc] initWithFormat:@"\\?%@$|(?<=\\?)%@&?|()&?%@", URL_OPEN_EXTERNAL, URL_OPEN_EXTERNAL, URL_OPEN_EXTERNAL] options:NSRegularExpressionCaseInsensitive error:NULL];
                            NSString *oldURL = [url absoluteString];
                            NSLog(@"    replacement pattern: %@", [replacerRegexp pattern]);
                            NSString *newURL = [replacerRegexp stringByReplacingMatchesInString:oldURL options:0 range:NSMakeRange(0, [oldURL length]) withTemplate:@""];
                            
                            NSLog(@"    Opening with updated URL: %@", newURL);
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:newURL]];
                            
                            return NO;
                        }
                        else if (matchesModal)
                        {
                            NSLog(@"    Link contain param \"%@\" --> open link modally", URL_OPEN_MODALLY);
                            
                            // Generate new URL without
                            // We are regexp-ing three things: the string alone, the string first with other content, the string with other content in any other position
                            NSRegularExpression *replacerRegexp = [NSRegularExpression regularExpressionWithPattern:[[NSString alloc] initWithFormat:@"\\?%@$|(?<=\\?)%@&?|()&?%@", URL_OPEN_MODALLY, URL_OPEN_MODALLY, URL_OPEN_MODALLY] options:NSRegularExpressionCaseInsensitive error:NULL];
                            NSString *oldURL = [url absoluteString];
                            NSLog(@"    replacement pattern: %@", [replacerRegexp pattern]);
                            NSString *newURL = [replacerRegexp stringByReplacingMatchesInString:oldURL options:0 range:NSMakeRange(0, [oldURL length]) withTemplate:@""];
                            
                            NSLog(@"    Opening with updated URL: %@", newURL);
                            [self loadModalWebView:url];
                            
                            return NO;
                        }
                    }
                    
                    NSLog(@"    Link doesn't contain param \"%@\" --> open link in page", URL_OPEN_EXTERNAL);
                    
                    return YES;
                }
            }
        }
        
        return NO;
    }
}
- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"• Page did start load");
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // Sent if a web view failed to load content.
    if ([webView isEqual:currPage]) {
        NSLog(@"• CurrPage failed to load content with error: %@", error);
    } else if ([webView isEqual:prevPage]) {
        NSLog(@"• PrevPage failed to load content with error: %@", error);
    } else if ([webView isEqual:nextPage]) {
        NSLog(@"• NextPage failed to load content with error: %@", error);
    }
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"• Page did finish load");
    [self webView:webView setCorrectOrientation:self.interfaceOrientation];
    
    if (webView.hidden == YES)
    {
        if ([webView isEqual:currPage]) {
            currentPageHasChanged = NO;
            [self setCurrentPageHeight];
        }
        
        [webView removeFromSuperview];
        webView.hidden = NO;
        
        if ([renderingType isEqualToString:@"three-cards"]) {
            [self webView:webView hidden:NO animating:YES];
        } else {
            [self takeScreenshotFromView:webView forPage:currentPageNumber andOrientation:[self getCurrentInterfaceOrientation]];
        }
        
        [self handlePageLoading];
    }
}
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating {
    
    NSLog(@"• webView hidden: %d animating: %d", status, animating);
    
    /* if (animating) {
     
     webView.hidden = NO;
     webView.alpha = 0.0;
     
     if (!USEPAGEVIEW){
     [scrollView addSubview:webView];
     } else {
     [currentPageViewController.view addSubview:webView];
     }
     
     [UIView animateWithDuration:0.5
     animations:^{ webView.alpha = 1.0; }
     completion:^(BOOL finished) { [self webViewDidAppear:webView animating:animating]; }];
     } else {
     
     if (!USEPAGEVIEW){
     [scrollView addSubview:webView];
     } else {
     [currentPageViewController.view addSubview:webView];
     }
     
     [self webViewDidAppear:webView animating:animating];
     }*/
}
- (void)webViewDidAppear:(UIWebView *)webView animating:(BOOL)animating {
    
    if ([webView isEqual:currPage])
    {
        [self webView:webView dispatchHTMLEvent:@"focus"];
        
        // If is the first time i load something in the currPage web view...
        if (currentPageFirstLoading)
        {
            // ... check if there is a saved starting scroll index and set it
            NSLog(@"   Handle last scroll index if necessary");
            NSString *currPageScrollIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrollIndex"];
            if (currPageScrollIndex != nil) {
                [self scrollDownCurrentPage:[currPageScrollIndex intValue] animating:YES];
            }
            currentPageFirstLoading = NO;
        }
        else
        {
            NSLog(@"   Handle saved hash reference if necessary");
            [self handleAnchor:YES];
        }
    }
}
- (void)webView:(UIWebView *)webView dispatchHTMLEvent:(NSString *)event {
    
    NSString *jsDispatchEvent = [NSString stringWithFormat:@"var bakerDispatchedEvent = document.createEvent('Events');\
                                 bakerDispatchedEvent.initEvent('%@', false, false);\
                                 window.dispatchEvent(bakerDispatchedEvent);", event];
    
    [webView stringByEvaluatingJavaScriptFromString:jsDispatchEvent];
}
- (void)setupWebView:(UIWebView *)webView {
    NSLog(@"• Setup webView");
    
    if (webViewBackground == nil)
    {
        webViewBackground = webView.backgroundColor;
        [webViewBackground retain];
    }
    
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    
    webView.delegate = self;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    webView.mediaPlaybackRequiresUserAction = ![[properties get:@"-baker-media-autoplay", nil] boolValue];
    webView.scalesPageToFit = [[properties get:@"zoomable", nil] boolValue];
    BOOL verticalBounce = [[properties get:@"-baker-vertical-bounce", nil] boolValue];
    
    for (UIView *subview in webView.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView *)subview).bounces = verticalBounce;
        }
    }
}

- (BOOL)loadWebView:(UIWebView*)webView withPage:(int)page {
    
    NSString *path = [NSString stringWithString:[pages objectAtIndex:page - 1]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"• Loading: book/%@", [[NSFileManager defaultManager] displayNameAtPath:path]);
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
        return YES;
    }
    return NO;
}


- (void)webView:(UIWebView *)webView setCorrectOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    // Since the UIWebView doesn't handle orientationchange events correctly we have to set the correct value for window.orientation property ourselves
    NSString *jsOrientationGetter;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 0; });";
            break;
        case UIInterfaceOrientationLandscapeLeft:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 90; });";
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 180; });";
            break;
        case UIInterfaceOrientationLandscapeRight:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return -90; });";
            break;
        default:
            break;
    }
    
    [webView stringByEvaluatingJavaScriptFromString:jsOrientationGetter];
}

@end
