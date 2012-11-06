//
//  RootViewController.m
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

#import <QuartzCore/QuartzCore.h>
#import <sys/xattr.h>
#import <AVFoundation/AVFoundation.h>

#import "BakerDefines.h"
#import "BakerViewController.h"
#import "BakerScrollWrapper.h"
#import "Downloader.h"
#import "SSZipArchive.h"
#import "PageTitleLabel.h"
#import "Utils.h"

@implementation BakerViewController

#pragma mark - INIT

- (id)initWithBookPath:(NSString *)bookPath {
    self = [super init];
    
    if (self) {
    
    NSLog(@"• INIT");
    
    // ****** DEVICE SCREEN BOUNDS
    screenBounds = [[UIScreen mainScreen] bounds];
    NSLog(@"    Device Width: %f", screenBounds.size.width);
    NSLog(@"    Device Height: %f", screenBounds.size.height);
    
    // ****** INIT PROPERTIES
    properties = [Properties properties];
    
    // ****** BUNDLED BOOK DIRECTORY
    bundleBookPath = [[[NSBundle mainBundle] pathForResource:@"book" ofType:nil] retain];
    
    // ****** DOWNLOADED BOOKS DIRECTORY
    NSString *privateDocsPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Private Documents"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:privateDocsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:privateDocsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    documentsBookPath = [[privateDocsPath stringByAppendingPathComponent:@"book"] retain];
    
    // ****** SCREENSHOTS DIRECTORY //TODO: set in load book only if is necessary
        
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    defaultScreeshotsPath = [[cachePath stringByAppendingPathComponent:@"baker-screenshots"] retain];
    [self addSkipBackupAttributeToItemAtPath:defaultScreeshotsPath];
    
    // ****** Initialize audio session for html5 audio
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok;
    NSError *setCategoryError = nil;
    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback
                             error:&setCategoryError];
    if (!ok) {
        NSLog(@"%s setCategoryError=%@", __PRETTY_FUNCTION__, setCategoryError);
    }

    
        // ****** BOOK ENVIRONMENT
        pages  = [[NSMutableArray array] retain];
        toLoad = [[NSMutableArray array] retain];
        
        attachedScreenshotPortrait  = [[NSMutableDictionary dictionary] retain];
        attachedScreenshotLandscape = [[NSMutableDictionary dictionary] retain];
        
        pageNameFromURL = nil;
        anchorFromURL = nil;
        
        /// ****** WRAPPER VIEW INIT
        _wrapperViewController = [[BakerScrollWrapper alloc] initWithFrame:self.view.frame];
        _wrapperViewController.dataSource = self;
        _wrapperViewController.delegate = self;
        [self addChildViewController:_wrapperViewController];
        [self.view addSubview:_wrapperViewController.view];
        
        // ****** LISTENER FOR INTERCEPTOR WINDOW NOTIFICATION
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterceptedTouch:) name:@"notification_touch_intercepted" object:nil];
        
        // ****** LISTENER FOR DOWNLOAD NOTIFICATION - TODO: MOVE TO VIEWWILLAPPEAR
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadBook:) name:@"downloadNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadResult:) name:@"handleDownloadResult" object:nil];
        
        // TODO: LOAD BOOK METHOD IN VIEW DID LOAD
        [self loadBookWithBookPath:bookPath];
        [self startReading];
    }
    return self;
}


- (BOOL)loadBookWithBookPath:(NSString *)bookPath {
    
    NSLog(@"• LOAD BOOK WITH PATH: %@", bookPath);
    
    // ****** STORING BOOK PATH
    currentBookPath = [bookPath retain];
    
    // ****** CLEANUP PREVIOUS BOOK
    [self cleanupBookEnvironment];
    
    // ****** LOAD BOOK PROPERTIES FROM BOOK.JSON
    [self loadBookProperties];
    
    if (pages.count > 0) {
        
        // ****** SET SCREENSHOTS FOLDER
        NSString *screenshotFolder = [properties get:@"-baker-page-screenshots", nil];
        if (screenshotFolder) {
            cachedScreenshotsPath = [bookPath stringByAppendingPathComponent:screenshotFolder];
        }
        
        if (!screenshotFolder || ![[NSFileManager defaultManager] fileExistsAtPath:cachedScreenshotsPath]) {
            cachedScreenshotsPath = [bookPath stringByAppendingPathComponent:@"baker-screenshots"];
            if ([bookPath isEqualToString:bundleBookPath]) {
                cachedScreenshotsPath = defaultScreeshotsPath;
            }
        }
        
        [cachedScreenshotsPath retain];
        
        return YES;
        
    } else {
        
        if (![bookPath isEqualToString:bundleBookPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:bookPath error:nil];
        }
        
        feedbackAlert = [[UIAlertView alloc] initWithTitle:ZERO_PAGES_TITLE
                                                   message:ZERO_PAGES_MESSAGE
                                                  delegate:self
                                         cancelButtonTitle:ALERT_FEEDBACK_CANCEL
                                         otherButtonTitles:nil];
        [feedbackAlert show];
        [feedbackAlert release];
        
        return NO;
    }
}
- (void)cleanupBookEnvironment {
    
    [self resetPageSlots];    
    
    [pages removeAllObjects];
    [toLoad removeAllObjects];
}
- (void)resetPageSlots {
    NSLog(@"• Reset leftover page slot");
    
    if (currPage) {
        [currPage.view removeFromSuperview];
        [currPage release];
    }
    if (nextPage) {
        [nextPage.view removeFromSuperview];
        [nextPage release];
    }
    if (prevPage) {
        [prevPage.view removeFromSuperview];
        [prevPage release];
    }
    
    currPage = nil;
    nextPage = nil;
    prevPage = nil;
}

- (void)loadBookProperties {
    /****************************************************************************************************
     * Initializes the 'properties' object from book.json and inits also some static properties.
     */
    NSString *filePath = [currentBookPath stringByAppendingPathComponent:@"book.json"];
    [properties loadManifest:filePath];
    
    // ****** ORIENTATION
    availableOrientation = [[[properties get:@"orientation", nil] retain] autorelease];
    NSLog(@"available orientation: %@", availableOrientation);
    
    // ****** CONTENTS
    [self buildPageArray];
    
    // ****** BAKER RENDERING
    NSString *renderingTypeString = [[[properties get:@"-baker-rendering", nil] retain] autorelease];
    renderingType = ([renderingTypeString isEqualToString:@"three-cards"])?BakerRenderingTypeThreeCards:BakerRenderingTypeScreenshots;
    
    NSLog(@"rendering type: %@", renderingTypeString);
    
    NSString *backgroundPathLandscape = [properties get:@"-baker-background-image-landscape", nil];
    if (backgroundPathLandscape != nil) {
        backgroundPathLandscape  = [currentBookPath stringByAppendingPathComponent:backgroundPathLandscape];
        backgroundImageLandscape = [[UIImage imageWithContentsOfFile:backgroundPathLandscape] retain];
    }
    
    NSString *backgroundPathPortrait = [properties get:@"-baker-background-image-portrait", nil];
    if (backgroundPathPortrait != nil) {
        backgroundPathPortrait  = [currentBookPath stringByAppendingPathComponent:backgroundPathPortrait];
        backgroundImagePortrait = [[UIImage imageWithContentsOfFile:backgroundPathPortrait] retain];
    }
}
- (void)buildPageArray {
    for (id page in [properties get:@"contents", nil]) {
        
        NSString *pageFile = nil;
        if ([page isKindOfClass:[NSString class]]) {
            pageFile = [currentBookPath stringByAppendingPathComponent:page];
        } else if ([page isKindOfClass:[NSDictionary class]]) {
            pageFile = [currentBookPath stringByAppendingPathComponent:[page objectForKey:@"url"]];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:pageFile]) {
            [pages addObject:pageFile];
        } else {
            NSLog(@"Page %@ does not exist in %@", page, currentBookPath);
        }
    }

    NSLog(@"    Pages in this book: %d", [pages count]);
}

- (void)startReadingFromPage:(int)pageNumber anchor:(NSString *)anchor {
    
    // set current page number
    // set anchor
    
    // open current page
    
    // TODO: START READING FROM PAGE AND ANCHOR
/*
    currentPageNumber = startingPage;
    if (currentPageFirstLoading && currPageToLoad != nil) {
        currentPageNumber = [currPageToLoad intValue];
    } else if (pageNameFromURL != nil) {
        pageNameFromURL = nil;
        NSString *fileNameFromURL = [path stringByAppendingPathComponent:pageNameFromURL];
        for (int i = 0; i < totalPages; i++) {
            if ([[pages objectAtIndex:i] isEqualToString:fileNameFromURL]) {
                currentPageNumber = i + 1;
                break;
            }
        }
    }*/
}

- (void)startReading {
    
    [self updateBookLayout];
    
    // TODO: MOVE INTO ANOTHER METHOD
    // [indexViewController loadContentFromBundle:[currentBookPath isEqualToString:bundleBookPath]];
    // ****** INDEX WEBVIEW INIT
    // we move it here to make it more clear and clean
    
    if (indexViewController != nil) {
        // first of all, we need to clean the indexview if it exists.
        [indexViewController.view removeFromSuperview];
        [indexViewController release];
    }
    indexViewController = [[IndexViewController alloc] initWithBookPath:currentBookPath fileName:INDEX_FILE_NAME webViewDelegate:self];
    [self.view addSubview:indexViewController.view];
    
    [indexViewController loadContent];
    
    // ****** SET STARTING PAGE
    int totalPages = pages.count;
    
    int lastPageViewed   = [[[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageViewed"] intValue];
    int bakerStartAtPage = [[properties get:@"-baker-start-at-page", nil] intValue];
    int startWithPage = 1;
    
    if (lastPageViewed != 0) {
        startWithPage = lastPageViewed;
    } else if (bakerStartAtPage < 0) {
        startWithPage = totalPages - ((-bakerStartAtPage % totalPages) * -1);
    } else if (bakerStartAtPage > 0) {
        startWithPage = bakerStartAtPage % (totalPages + 1);
    }
    
    [self initWrapperWithPage:startWithPage];
    

}

- (void)updateBookLayout {
    
    // HACK TO HANDLE STATUS BAR ON ROTATION, TODO: MOVE IT IN ITS OWN METHOD
    int scrollViewY = 0;
    if (![UIApplication sharedApplication].statusBarHidden) {
        scrollViewY = -20;
    }
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         _wrapperViewController.view.frame = CGRectMake(0, scrollViewY, self.view.frame.size.width, self.view.frame.size.height);
                     }];
}
  
- (void)addSkipBackupAttributeToItemAtPath:(NSString *)path {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        if (SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"5.0.1")) {
            
            const char *filePath = [path fileSystemRepresentation];
            const char *attrName = "com.apple.MobileBackup";
            u_int8_t attrValue = 1;
            
            int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
            if (result == 0) {
                NSLog(@"Successfully added skip backup attribute to item %@ (iOS <= 5.0.1)", path);
            }

        } else if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.1")) {
            
            BOOL success = [[NSURL fileURLWithPath:path] setResourceValue:[NSNumber numberWithBool: YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
            if(success) {
                NSLog(@"Successfully added skip backup attribute to item %@ (iOS >= 5.1)", path);
            }
        }
    }
}
- (NSDictionary *)bookCurrentStatus {
    NSString *lastPageViewed =  nil;
    if (currPage.tag > 0) {
        lastPageViewed = [NSString stringWithFormat:@"%d", currPage.tag];
    }
    
    NSString *lastScrollIndex = nil;
    if (currPage != nil) {
        lastScrollIndex = [currPage.webView stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:lastPageViewed, @"lastPageViewed", lastScrollIndex, @"lastScrollIndex", nil];
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
                    if (![webView isEqual:indexViewController.view])
                    {
                        if (anchorFromURL == nil) {
                            return YES;
                        }
                        
                        //[self handleAnchor:YES];
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

#pragma mark - MODAL VIEW
- (void)loadModalWebView:(NSURL *)url {
    /****************************************************************************************************
     * Initializes the modal view and opens the requested url.
     * It contains a fix to avoid an overlapping status bar.
     */
    
    NSLog(@"» Loading a modal webview for url %@", url.absoluteString);
    
    myModalViewController = [[ModalViewController alloc] initWithUrl:url];
    myModalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    myModalViewController.delegate = self;
    
    // Hide the IndexView before opening modal web view
    [self hideStatusBar];
    
    // Check if iOS4 or 5
    if ([self respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // iOS 5
        [self presentViewController:myModalViewController animated:YES completion:nil];
    } else {
        // iOS 4
        [self presentModalViewController:myModalViewController animated:YES];
    }
    
    [myModalViewController release];
}
- (void)closeModalWebView {
    /****************************************************************************************************
     * This function is called from inside the modal view to close itself (delegate).
     */
    
    // Check if iOS5 method is supported
    if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        // iOS 5
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        // iOS 4
        [self dismissModalViewControllerAnimated:YES];
    }
    
    // In case the orientation changed while being in modal view, restore the
    // webview and stuff to the current orientation
    [indexViewController rotateFromOrientation:self.interfaceOrientation toOrientation:self.interfaceOrientation];
    
    [self updateBookLayout];
}

#pragma mark - PAGE MANAGEMENT

- (void)initWrapperWithPage:(int)page{
    
    PageViewController *newPageViewController = [self newPageViewForPage:page];
    
    [self pageViewHasBecomeCurrentPage:newPageViewController];
    
    NSArray *pageViews = @[newPageViewController];
    
    [_wrapperViewController setViewControllers:pageViews direction:BakerWrapperNavigationDirectionHorizontal animated:NO completion:^(BOOL finished) {
        NSLog(@"First Page Loaded");
    }];
}

- (void)pageViewHasBecomeCurrentPage:(PageViewController *)newPageViewController{
    
    if (newPageViewController == currPage) return;
    
    if (renderingType == BakerRenderingTypeThreeCards) {
        
        if (prevPage == newPageViewController) {
            if (nextPage){
                [nextPage.view removeFromSuperview];
                [nextPage removeFromParentViewController];
                [nextPage release];
            }
            nextPage = currPage;
            prevPage = [self newPageViewForPage:newPageViewController.tag - 1];
        }
        
        if (nextPage == newPageViewController){
            if (prevPage){
                [prevPage.view removeFromSuperview];
                [prevPage removeFromParentViewController];
                [prevPage release];
            }
            prevPage = currPage;
            nextPage = [self newPageViewForPage:newPageViewController.tag + 1];
        }
        
    }
    
    if (currPage){
        [currPage.view removeFromSuperview];
        [currPage removeFromParentViewController];
        [currPage release];
    }
    
    currPage = newPageViewController;
}

- (PageViewController *)newPageViewForPage:(int)page{
    if (page > 0 && page < pages.count){
        
        PageViewController *newPage = [[[PageViewController alloc] initWithFrame:self.view.frame] autorelease];
        
        if ([[self getCurrentInterfaceOrientation] isEqualToString:@"portrait"] && backgroundImagePortrait != NULL){
            newPage.backgroundImageView.image = backgroundImagePortrait;
        } else if (backgroundImageLandscape != NULL){
            newPage.backgroundImageView.image = backgroundImageLandscape;
        } else {
            newPage.backgroundImageView.image = nil;
        }
        
        newPage.delegate = self;
        
        [newPage setTag:page];
        [newPage loadPage:[pages objectAtIndex:page - 1]];
        
        return newPage;
    } else {
        return nil;
    }
}

- (PageViewController *)getPageViewForPage:(int)page{
    
    if (renderingType == BakerRenderingTypeThreeCards) {
        
        if (prevPage && prevPage.tag == page){
            return prevPage;
        }
        
        if (currPage && currPage.tag == page){
            return currPage;
        }

        if (nextPage && nextPage.tag == page){
            return nextPage;
        }
    }
    
    return [self newPageViewForPage:page];

}

- (PageViewController *)wrapperViewController:(BakerWrapper *)wrapperViewController viewControllerAfterViewController:(PageViewController *)viewController{
   return [self getPageViewForPage:viewController.tag + 1];
}

- (PageViewController *)wrapperViewController:(BakerWrapper *)wrapperViewController viewControllerBeforeViewController:(PageViewController *)viewController{
   return [self getPageViewForPage:viewController.tag - 1];
}

- (NSInteger)presentationCountForWrapperViewController:(BakerWrapper *)wrapperViewController{
    return pages.count;
}

- (NSInteger)presentationIndexForWrapperViewController:(BakerWrapper *)wrapperViewController{
    return currPage.tag;
}

- (void)wrapperViewController:(BakerWrapper *)wrapperViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers{
    
}

- (void)wrapperViewController:(BakerWrapper *)wrapperViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    
}

#pragma mark - STATUS BAR
- (void)toggleStatusBar {
    
    // if modal view is up, don't toggle.
    if (!self.modalViewController) {
        NSLog(@"• Toggle status bar visibility");
        
        UIApplication *sharedApplication = [UIApplication sharedApplication];
        BOOL hidden = sharedApplication.statusBarHidden;
        [sharedApplication setStatusBarHidden:!hidden withAnimation:UIStatusBarAnimationSlide];
        if(![indexViewController isDisabled]) {
            [indexViewController setIndexViewHidden:!hidden withAnimation:YES];
        }
    }
}
- (void)hideStatusBar {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    if(![indexViewController isDisabled]) {
        [indexViewController setIndexViewHidden:YES withAnimation:YES];
    }
}

#pragma mark - DOWNLOAD NEW BOOKS
- (void)downloadBook:(NSNotification *)notification {
    
    if (notification != nil) {
        URLDownload = [[NSString stringWithString:(NSString *)[notification object]] retain];
    }
    NSLog(@"• Download file %@", URLDownload);
    
    feedbackAlert = [[UIAlertView alloc] initWithTitle:@""
                                               message:[NSString stringWithFormat:OPEN_BOOK_MESSAGE, URLDownload]
                                              delegate:self
                                     cancelButtonTitle:ALERT_FEEDBACK_CANCEL
                                     otherButtonTitles:OPEN_BOOK_CONFIRM, nil];
    [feedbackAlert show];
    [feedbackAlert release];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:CLOSE_BOOK_CONFIRM])
    {
        // If a "book" directory already exists remove it (quick solution, improvement needed)
        if ([[NSFileManager defaultManager] fileExistsAtPath:documentsBookPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:documentsBookPath error:NULL];
        }
        
        
        [self loadBookWithBookPath:bundleBookPath];
        [self startReading];
    }
    else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:OPEN_BOOK_CONFIRM])
    {
        [self startDownloadRequest];
    }
}
- (void)startDownloadRequest {
    
    downloader = [[Downloader alloc] initDownloader:@"handleDownloadResult"];
    [downloader makeHTTPRequest:URLDownload];
}
- (void)handleDownloadResult:(NSNotification *)notification {
    
    NSDictionary *requestSummary = [NSDictionary dictionaryWithDictionary:(NSMutableDictionary *)[notification object]];
    [downloader release];
    
    if ([requestSummary objectForKey:@"error"] != nil) {
        
        NSLog(@"• Error while downloading new book data");
        feedbackAlert = [[UIAlertView alloc] initWithTitle:ERROR_FEEDBACK_TITLE
                                                   message:ERROR_FEEDBACK_MESSAGE
                                                  delegate:self
                                         cancelButtonTitle:ALERT_FEEDBACK_CANCEL
                                         otherButtonTitles:ERROR_FEEDBACK_CONFIRM, nil];
        [feedbackAlert show];
        [feedbackAlert release];
        
    } else if ([requestSummary objectForKey:@"data"] != nil) {
        
        NSLog(@"• New book data received succesfully");
        feedbackAlert = [[UIAlertView alloc] initWithTitle:EXTRACT_FEEDBACK_TITLE
                                                   message:nil
                                                  delegate:self
                                         cancelButtonTitle:nil
                                         otherButtonTitles:nil];
        
        UIActivityIndicatorView *extractingWheel = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(124,50,37,37)];
        extractingWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [extractingWheel startAnimating];
        
        [feedbackAlert addSubview:extractingWheel];
        [feedbackAlert show];
        
        [extractingWheel release];
        [feedbackAlert release];
        
        [self performSelector:@selector(manageDownloadData:) withObject:[requestSummary objectForKey:@"data"] afterDelay:0.1];
    }
}
- (void)manageDownloadData:(NSData *)data {
    
    NSArray *URLSections = [NSArray arrayWithArray:[URLDownload pathComponents]];
    NSString *targetPath = [NSTemporaryDirectory() stringByAppendingString:[URLSections lastObject]];
    
    [data writeToFile:targetPath atomically:YES];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath]) {
        NSLog(@"• File hpub create successfully at path: %@", targetPath);
        NSLog(@"    Book destination path: %@", documentsBookPath);
        
        // If a "book" directory already exists remove it (quick solution, improvement needed)
        if ([[NSFileManager defaultManager] fileExistsAtPath:documentsBookPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:documentsBookPath error:NULL];
        }
        
        [SSZipArchive unzipFileAtPath:targetPath toDestination:documentsBookPath];
        
        NSLog(@"    Book successfully unzipped. Removing .hpub file");
        [[NSFileManager defaultManager] removeItemAtPath:targetPath error:NULL];
        
        NSLog(@"    Add skip backup attribute to book folder");
        [self addSkipBackupAttributeToItemAtPath:documentsBookPath];
        
        [feedbackAlert dismissWithClickedButtonIndex:feedbackAlert.cancelButtonIndex animated:YES];
        [self loadBookWithBookPath:documentsBookPath];
        [self startReading];
    }
}

#pragma mark - ORIENTATION
- (NSString *)getCurrentInterfaceOrientation {
    
    if ([availableOrientation isEqualToString:@"portrait"] || [availableOrientation isEqualToString:@"landscape"]) {
        return availableOrientation;
    } else {
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            return @"landscape";
        } else {
            return @"portrait";
        }
    }
     
}
- (NSInteger)supportedInterfaceOrientations {
    if ([availableOrientation isEqualToString:@"portrait"]) {
        return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationPortraitUpsideDown);
    } else if ([availableOrientation isEqualToString:@"landscape"]) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([availableOrientation isEqualToString:@"portrait"]) {
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    } else if ([availableOrientation isEqualToString:@"landscape"]) {
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    } else {
        return YES;
    }
}
- (BOOL)shouldAutorotate {
    return YES;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Notify the index view
    [indexViewController willRotate];
    
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [indexViewController rotateFromOrientation:fromInterfaceOrientation toOrientation:self.interfaceOrientation];
    
    [self updateBookLayout];
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


#pragma mark - MEMORY
- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    //Jettison Next and Previous Pages
    if (prevPage){
        [prevPage release];
    }
    
    if (nextPage){
        [nextPage release];
    }
    
}

- (void)dealloc {
    
    [cachedScreenshotsPath release];
    [defaultScreeshotsPath release];
    
    [documentsBookPath release];
    [currentBookPath release];
    
    [toLoad release];
    [pages release];
    
    [indexViewController release];
    [myModalViewController release];
    [currPage release];
    [nextPage release];
    [prevPage release];
    
    [super dealloc];
}

#pragma mark - MFMailComposeController

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    
    // Log the result for debugging purpose
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"    Mail cancelled.");
            break;
            
        case MFMailComposeResultSaved:
            NSLog(@"    Mail saved.");
            break;
            
        case MFMailComposeResultSent:
            NSLog(@"    Mail send.");
            break;
            
        case MFMailComposeResultFailed:
            NSLog(@"    Mail failed, check NSError.");
            break;
            
        default:
            NSLog(@"    Mail not sent.");
            break;
    }
   
    
    // Remove the mail view
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - INDEX VIEW
- (BOOL)isIndexView:(UIWebView *)webView {
    if (webView == indexViewController.view) {
        return YES;
    } else {
        return NO;
    }
}


@end