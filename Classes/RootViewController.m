//
//  RootViewController.m
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2010-2011, Davide Casali, Marco Colombo, Alessandro Morandi
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

#import "RootViewController.h"
#import "Downloader.h"
#import "SSZipArchive.h"
#import "PageTitleLabel.h"
#import "Utils.h"

// ALERT LABELS
#define OPEN_BOOK_MESSAGE       @"Do you want to download "
#define OPEN_BOOK_CONFIRM       @"Open book"

#define CLOSE_BOOK_MESSAGE      @"Do you want to close this book?"
#define CLOSE_BOOK_CONFIRM      @"Close book"

#define ZERO_PAGES_TITLE        @"Whoops!"
#define ZERO_PAGES_MESSAGE      @"Sorry, that book had no pages."

#define ERROR_FEEDBACK_TITLE    @"Whoops!"
#define ERROR_FEEDBACK_MESSAGE  @"There was a problem downloading the book."
#define ERROR_FEEDBACK_CONFIRM  @"Retry"

#define EXTRACT_FEEDBACK_TITLE  @"Extracting..."

#define ALERT_FEEDBACK_CANCEL   @"Cancel"

#define INDEX_FILE_NAME         @"index.html"

#define URL_OPEN_EXTERNAL       @"referrer=Baker"


// IOS VERSION >= 5.0 MACRO
#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_5_0
    #define kCFCoreFoundationVersionNumber_iPhoneOS_5_0 675.00
#endif
#ifndef __IPHONE_5_0
    #define __IPHONE_5_0 50000
#endif
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_5_0
    #define IF_IOS5_OR_GREATER(...) \
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_5_0) { \
        __VA_ARGS__ \
    }
#else
    #define IF_IOS5_OR_GREATER(...)
#endif

@implementation RootViewController

#pragma mark - SYNTHESIS
@synthesize scrollView;
@synthesize currPage;
@synthesize currentPageNumber;

#pragma mark - INIT
- (id)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        NSLog(@"• INIT");
        
        // ****** INIT PROPERTIES
        properties = [Properties properties];
        
        // ****** DEVICE SCREEN BOUNDS
        screenBounds = [[UIScreen mainScreen] bounds];
        NSLog(@"    Device Width: %f", screenBounds.size.width);
        NSLog(@"    Device Height: %f", screenBounds.size.height);
        
        // ****** BOOK DIRECTORIES        
        NSString *privateDocsPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Private Documents"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:privateDocsPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:privateDocsPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        bundleBookPath        = [[[NSBundle mainBundle] pathForResource:@"book" ofType:nil] retain];
        documentsBookPath     = [[privateDocsPath stringByAppendingPathComponent:@"book"] retain];
        
        defaultScreeshotsPath = [[cachePath stringByAppendingPathComponent:@"baker-screenshots"] retain];
        [self addSkipBackupAttributeToItemAtPath:defaultScreeshotsPath];
        
        // ****** BOOK ENVIRONMENT
        pages = [[NSMutableArray array] retain];
        toLoad = [[NSMutableArray array] retain];
        pageDetails = [[NSMutableArray array] retain];

        pageNameFromURL = nil;
        anchorFromURL = nil;
                
        tapNumber = 0;
        stackedScrollingAnimations = 0;
        
        currentPageFirstLoading = YES;
        currentPageIsDelayingLoading = YES;
        currentPageHasChanged = NO;
        currentPageIsLocked = NO;
                        
        // ****** LISTENER FOR DOWNLOAD NOTIFICATION
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadBook:) name:@"downloadNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadResult:) name:@"handleDownloadResult" object:nil];
                
        [self setPageSize:[self getCurrentInterfaceOrientation]];
        [self hideStatusBar];
        
        // ****** SCROLLVIEW INIT
        self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)] autorelease];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.showsHorizontalScrollIndicator = YES;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.delaysContentTouches = NO;
        scrollView.pagingEnabled = YES;
        scrollView.delegate = self;
        
        [self.view addSubview:scrollView];
        
        // ****** INDEX WEBVIEW INIT
        indexViewController = [[IndexViewController alloc] initWithBookBundlePath:bundleBookPath documentsBookPath:documentsBookPath fileName:INDEX_FILE_NAME webViewDelegate:self];
        [self.view addSubview:indexViewController.view];
        
        // ****** BOOK INIT
        if ([[NSFileManager defaultManager] fileExistsAtPath:documentsBookPath]) {
            [self initBook:documentsBookPath];
        } else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:bundleBookPath]) {
                [self initBook:bundleBookPath];
            } else {
              // Do something if there are no books available to show
            }
        }
	}
	return self;
}
- (void)setupWebView:(UIWebView *)webView {
    NSLog(@"• Setup webView");
    
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
- (void)setPageSize:(NSString *)orientation {
	NSLog(@"• Set size for orientation: %@", orientation);
    
    pageWidth = screenBounds.size.width;
    pageHeight = screenBounds.size.height;
	if ([orientation isEqualToString:@"landscape"]) {
		pageWidth = screenBounds.size.height;
		pageHeight = screenBounds.size.width;
	}
}
- (void)setTappableAreaSize {
    NSLog(@"• Set tappable area size");

    int tappableAreaSize = screenBounds.size.width/16;
    if (screenBounds.size.width < 768) {
        tappableAreaSize = screenBounds.size.width/8;
    }
    
    upTapArea    = CGRectMake(tappableAreaSize, 0, pageWidth - (tappableAreaSize * 2), tappableAreaSize);
    downTapArea  = CGRectMake(tappableAreaSize, pageHeight - tappableAreaSize, pageWidth - (tappableAreaSize * 2), tappableAreaSize);
    leftTapArea  = CGRectMake(0, tappableAreaSize, tappableAreaSize, pageHeight - (tappableAreaSize * 2));
    rightTapArea = CGRectMake(pageWidth - tappableAreaSize, tappableAreaSize, tappableAreaSize, pageHeight - (tappableAreaSize * 2));
}
- (void)resetScrollView {
    NSLog(@"• Reset scrollview subviews");
    
    NSLog(@"    Prevent page from changing until scrollview reset is finished");
    [self lockPage:YES];
    
    [self setTappableAreaSize];
    
    for (NSMutableDictionary *details in pageDetails) {
        for (NSString *key in details) {
            UIView *value = [details objectForKey:key];
            value.hidden = YES;
        }
    }
    
    [self showPageDetails];

    scrollView.contentSize = CGSizeMake(pageWidth * totalPages, pageHeight);

	int scrollViewY = 0;
	if (![UIApplication sharedApplication].statusBarHidden) {
		scrollViewY = -20;
	}    
    [UIView animateWithDuration:0.2 
                     animations:^{ scrollView.frame = CGRectMake(0, scrollViewY, pageWidth, pageHeight); }];
	
    if (prevPage && [prevPage.superview isEqual:scrollView]) {
        prevPage.frame = [self frameForPage:currentPageNumber - 1];
        [scrollView bringSubviewToFront:prevPage];
    }
    
    if (nextPage && [nextPage.superview isEqual:scrollView]) {
        nextPage.frame = [self frameForPage:currentPageNumber + 1];
        [scrollView bringSubviewToFront:nextPage];
    }
    
    if (currPage) {
        currPage.frame = [self frameForPage:currentPageNumber];
    }
    
    [scrollView bringSubviewToFront:currPage];
    [scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
    
    NSLog(@"    Unlock page changing");
    [self lockPage:NO];
}
- (void)initPageDetails {
    NSLog(@"• Init page details for the book pages");
    
    for (int i = 0; i < totalPages; i++) {
        
        UIColor *foregroundColor = [Utils colorWithHexString:[properties get:@"-baker-page-numbers-color", nil]];
        id foregroundAlpha = [properties get:@"-baker-page-numbers-alpha", nil];
        
        // ****** Background
        UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(pageWidth * i, 0, pageWidth, pageHeight)];
        [self setImageFor:backgroundView];
        [scrollView addSubview:backgroundView];
        [backgroundView release];
        
        // ****** Spinners
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.backgroundColor = [UIColor clearColor];
        IF_IOS5_OR_GREATER(
            spinner.color = foregroundColor;
            spinner.alpha = [(NSNumber *)foregroundAlpha floatValue];
        );
        
        CGRect frame = spinner.frame;
        frame.origin.x = pageWidth * i + (pageWidth - frame.size.width) / 2;
        frame.origin.y = (pageHeight - frame.size.height) / 2;        
        spinner.frame = frame;
        
        [scrollView addSubview:spinner];
        [spinner startAnimating];
        [spinner release];
        
        // ****** Numbers
        UILabel *number = [[UILabel alloc] initWithFrame:CGRectMake(pageWidth * i + (pageWidth - 115) / 2, pageHeight / 2 - 55, 115, 30)];
        number.backgroundColor = [UIColor clearColor];
        number.font = [UIFont fontWithName:@"Helvetica" size:40.0];
        number.textColor = foregroundColor;
        number.textAlignment = UITextAlignmentCenter;
        number.alpha = [(NSNumber *)foregroundAlpha floatValue];
        
        number.text = [NSString stringWithFormat:@"%d", i + 1];
        if ([[properties get:@"-baker-start-at-page", nil] intValue] < 0) {
            number.text = [NSString stringWithFormat:@"%d", totalPages - i];
        }
        
        [scrollView addSubview:number];
        [number release];
        
        // ****** Title
        PageTitleLabel *title = [[PageTitleLabel alloc]initWithFile:[pages objectAtIndex: i]];
        [title setX:(pageWidth * i + ((pageWidth - title.frame.size.width) / 2)) Y:(pageHeight / 2 + 20)];
        [scrollView addSubview:title];
        [title release];
        
        // ****** Store instances for later use
        NSMutableDictionary *details = [NSMutableDictionary dictionaryWithObjectsAndKeys:spinner, @"spinner", number, @"number", title, @"title", backgroundView, @"background", nil];
        [pageDetails insertObject:details atIndex:i];
    }
    
    if ([renderingType isEqualToString:@"screenshots"]) {
        [self initScreenshots];
    }
}
- (void)showPageDetails {
    NSLog(@"• Show page details for the book pages");
    
	for (int i = 0; i < totalPages; i++) {
        
        if (pageDetails.count > i && [pageDetails objectAtIndex:i] != nil) {
            
            NSDictionary *details = [NSDictionary dictionaryWithDictionary:[pageDetails objectAtIndex:i]];              
            UIView *screenshotView = [details objectForKey:[NSString stringWithFormat:@"screenshot-%@", [self getCurrentInterfaceOrientation]]];
            if (screenshotView != nil)
            {
                screenshotView.hidden = NO;
            } 
            else
            {
                for (NSString *key in details) {
                    UIView *value = [details objectForKey:key];
                    if (value != nil) {
                        
                        CGRect frame = value.frame;
                        if ([key isEqualToString:@"spinner"]) {
                            
                            frame.origin.x = pageWidth * i + (pageWidth - frame.size.width) / 2;
                            frame.origin.y = (pageHeight - frame.size.height) / 2;
                            value.frame = frame;
                            value.hidden = NO;
                            
                        } else if ([key isEqualToString:@"number"]) {
                            
                            frame.origin.x = pageWidth * i + (pageWidth - 115) / 2;
                            frame.origin.y = pageHeight / 2 - 55;
                            value.frame = frame;
                            value.hidden = NO;
                            
                            
                        } else if ([key isEqualToString:@"title"]) {
                            
                            frame.origin.x = pageWidth * i + (pageWidth - frame.size.width) / 2;
                            frame.origin.y = pageHeight / 2 + 20;
                            value.frame = frame;
                            value.hidden = NO;
                            
                        } else if ([key isEqualToString:@"background"]) {
                            
                            [self setImageFor:(UIImageView *)value];
                            frame.origin.x = pageWidth * i;
                            frame.size.width = pageWidth;
                            frame.size.height = pageHeight;
                            value.frame = frame;
                            value.hidden = NO;
                            
                        } else {
                            
                            value.hidden = YES;
                        }
                    }
                }
            }
        } 
	}
}
- (void)resetPageDetails {
    NSLog(@"• Reset page details array and empty screenshot directory");
    
    for (NSMutableDictionary *details in pageDetails) {
        for (NSString *key in details) {
            UIView *value = [details objectForKey:key];
            [value removeFromSuperview];
        }
    }
    
    [pageDetails removeAllObjects];
    [pages removeAllObjects];
}
- (void)initBookProperties:(NSString *)path {
    /****************************************************************************************************
     * Initializes the 'properties' object from book.json and inits also some static properties.
     */
    
    NSString *filePath = [path stringByAppendingPathComponent:@"book.json"];
    [properties loadManifest:filePath];
    
    // ****** ORIENTATION
    availableOrientation = [[[properties get:@"orientation", nil] retain] autorelease];
    NSLog(@"available orientation: %@", availableOrientation);
    
    // ****** RENDERING
    renderingType = [[[properties get:@"-baker-rendering", nil] retain] autorelease];
    NSLog(@"rendering type: %@", renderingType);
    
    // ****** SWIPES
    scrollView.scrollEnabled = [[properties get:@"-baker-page-turn-swipe", nil] boolValue];
    
    // ****** BACKGROUND
    scrollView.backgroundColor = [Utils colorWithHexString:[properties get:@"-baker-background", nil]];
    backgroundImageLandscape   = nil;
    backgroundImagePortrait    = nil;
    
    NSString *backgroundPathLandscape = [properties get:@"-baker-background-image-landscape", nil];
    if (backgroundPathLandscape != nil) {
        backgroundPathLandscape  = [path stringByAppendingPathComponent:backgroundPathLandscape];
        backgroundImageLandscape = [[UIImage imageWithContentsOfFile:backgroundPathLandscape] retain];        
    }
    
    NSString *backgroundPathPortrait = [properties get:@"-baker-background-image-portrait", nil];
    if (backgroundPathPortrait != nil) {
        backgroundPathPortrait  = [path stringByAppendingPathComponent:backgroundPathPortrait];
        backgroundImagePortrait = [[UIImage imageWithContentsOfFile:backgroundPathPortrait] retain];
    }
}
- (void)initBook:(NSString *)path {
    NSLog(@"• Init Book");
    
    [self initBookProperties:path];
    [self resetPageDetails];
	
    NSEnumerator *pagesEnumerator = [[properties get:@"contents", nil] objectEnumerator];
    id page;
    
    while ((page = [pagesEnumerator nextObject])) {
        NSString *pageFile = nil;
        if ([page isKindOfClass:[NSString class]]) {
            pageFile = [path stringByAppendingPathComponent:page];
        } else if ([page isKindOfClass:[NSDictionary class]]) {
            pageFile = [path stringByAppendingPathComponent:[page objectForKey:@"url"]];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:pageFile]) {
            [pages addObject:pageFile];
        } else {
            NSLog(@"Page %@ does not exist in %@", page, path);
        }
    }
    
	totalPages = [pages count];
	NSLog(@"    Pages in this book: %d", totalPages);
	
	if (totalPages > 0) {
		// Check if there is a saved starting page        
		NSString *currPageToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageViewed"];
		
        int startingPage = [[properties get:@"-baker-start-at-page", nil] intValue];
        if (startingPage < 0) {
            startingPage = MAX(1, totalPages + startingPage + 1);
        } else if (startingPage == 0) {
            startingPage = 1;
        } else if (startingPage > 0) {
            startingPage = MIN(totalPages, startingPage);
        }
        
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
		}
        
        NSLog(@"    Starting page: %i", currentPageNumber);
		
        currentPageIsDelayingLoading = YES;
        [toLoad removeAllObjects];
		
        NSString *screenshotFolder = [properties get:@"-baker-page-screenshots", nil];
        if (screenshotFolder != nil) {
            cachedScreenshotsPath = [path stringByAppendingPathComponent:screenshotFolder];
        }
        
        if (screenshotFolder == nil || ![[NSFileManager defaultManager] fileExistsAtPath:cachedScreenshotsPath]) {
            cachedScreenshotsPath = [path stringByAppendingPathComponent:@"baker-screenshots"];
            if ([path isEqualToString:bundleBookPath]) {
                cachedScreenshotsPath = defaultScreeshotsPath;
            }
        }
    
        [cachedScreenshotsPath retain];
        
        [self initPageDetails];
        [self resetScrollView];
        [self addPageLoading:0];
        
        if ([renderingType isEqualToString:@"three-cards"]) {
            if (currentPageNumber != totalPages) {
                [self addPageLoading:+1];
            }
            
            if (currentPageNumber != 1) {
                [self addPageLoading:-1];
            }
        }
        [self handlePageLoading];
        
        [indexViewController loadContentFromBundle:[path isEqualToString:bundleBookPath]];
		
	} else if (![path isEqualToString:bundleBookPath]) {
		
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
 		feedbackAlert = [[UIAlertView alloc] initWithTitle:ZERO_PAGES_TITLE
												   message:ZERO_PAGES_MESSAGE
												  delegate:self
										 cancelButtonTitle:ALERT_FEEDBACK_CANCEL
										 otherButtonTitles:nil];
		[feedbackAlert show];
		[feedbackAlert release];		
	}
}
- (void)setImageFor:(UIImageView *)view {
    if (pageWidth > pageHeight && backgroundImageLandscape != NULL) {
        // Landscape
        view.image = backgroundImageLandscape;
    } else if (pageWidth < pageHeight && backgroundImagePortrait != NULL) {
        // Portrait
        view.image = backgroundImagePortrait;
    } else {
        view.image = NULL;
    }
}
- (void)addSkipBackupAttributeToItemAtPath:(NSString *)path {
    const char *filePath = [path fileSystemRepresentation];
    const char *attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    if (result == 0) {
        NSLog(@"Successfully added skip backup attribute to item %@", path);
    }
}

#pragma mark - LOADING
- (BOOL)changePage:(int)page {
    NSLog(@"• Check if page has changed");
    
    BOOL pageChanged = NO;
	
    if (page < 1)
    {
		currentPageNumber = 1;
	}
    else if (page > totalPages)
    {
		currentPageNumber = totalPages;
	} 
    else if (page != currentPageNumber)
    {
        // While we are tapping, we don't want scrolling event to get in the way
        scrollView.scrollEnabled = NO;
        stackedScrollingAnimations++;
        
        lastPageNumber = currentPageNumber;
		currentPageNumber = page;
        
        tapNumber = tapNumber + (lastPageNumber - currentPageNumber);
        
        [self hideStatusBar];
        [scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:YES];
        
        [self gotoPageDelayer];

        pageChanged = YES;
	}
	
	return pageChanged;
}
- (void)gotoPageDelayer {
	// This delay is required in order to avoid stuttering when the animation runs.
	// The animation lasts 0.5 seconds: so we start loading after that.
    
	if (currentPageIsDelayingLoading) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(gotoPage) object:nil];
    }
	
	currentPageIsDelayingLoading = YES;
	[self performSelector:@selector(gotoPage) withObject:nil afterDelay:0.5];
}
- (void)gotoPage {    
    
    NSString *path = [NSString stringWithString:[pages objectAtIndex:currentPageNumber - 1]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] && tapNumber != 0) {
        
        NSLog(@"• Goto page: book/%@", [[NSFileManager defaultManager] displayNameAtPath:path]);
        
        if ([renderingType isEqualToString:@"three-cards"])
        {
            // ****** THREE CARD VIEW METHOD
            
            // Dispatch blur event on old current page
            [self webView:currPage dispatchHTMLEvent:@"blur"];
            
            // Calculate move direction and normalize tapNumber
            int direction = 1;
            if (tapNumber < 0) {
                direction = -direction;
                tapNumber = -tapNumber;
            }
            NSLog(@"    Tap number: %d", tapNumber);
            
            if (tapNumber > 2) {
                tapNumber = 0;
                
                // Moved away for more than 2 pages: RELOAD ALL pages
                [toLoad removeAllObjects];
                
                [currPage removeFromSuperview];
                [nextPage removeFromSuperview];
                [prevPage removeFromSuperview];
                
                [self addPageLoading:0];
                if (currentPageNumber < totalPages)
                    [self addPageLoading:+1];
                if (currentPageNumber > 1)
                    [self addPageLoading:-1];
                            
            } else {
                
                int tmpSlot = 0;
                if (tapNumber == 2) {
                
                    // Moved away for 2 pages: RELOAD CURRENT page
                    if (direction < 0) {
                        // Move LEFT <<<
                        [prevPage removeFromSuperview];
                        UIWebView *tmpView = prevPage;
                        prevPage = nextPage;
                        nextPage = tmpView;
                    } else {
                        // Move RIGHT >>>
                        [nextPage removeFromSuperview];
                        UIWebView *tmpView = nextPage; 
                        nextPage = prevPage;
                        prevPage = tmpView;
                    }
                                        
                    // Adjust pages slot in the stack to reflect the webviews pointer change
                    for (int i = 0; i < [toLoad count]; i++) {
                        tmpSlot =  -1 * [[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue];
                        [[toLoad objectAtIndex:i] setObject:[NSNumber numberWithInt:tmpSlot] forKey:@"slot"];
                    }
                    
                    [currPage removeFromSuperview];
                    [self addPageLoading:0];
                
                } else if (tapNumber == 1) {
                                    
                    if (direction < 0) {
                        // ****** Move LEFT <<<
                        [prevPage removeFromSuperview];
                        UIWebView *tmpView = prevPage;
                        prevPage = currPage;
                        currPage = nextPage;
                        nextPage = tmpView;
                        
                    } else {
                        // ****** Move RIGHT >>>
                        [nextPage removeFromSuperview];
                        UIWebView *tmpView = nextPage;
                        nextPage = currPage;
                        currPage = prevPage;
                        prevPage = tmpView;                        
                    }
                    
                    // Adjust pages slot in the stack to reflect the webviews pointer change
                    for (int i = 0; i < [toLoad count]; i++) {
                        tmpSlot = [[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue];
                        if (direction < 0) {
                            if (tmpSlot == +1) {
                                tmpSlot = 0;
                            } else if (tmpSlot == 0) {
                                tmpSlot = -1;
                            } else if (tmpSlot == -1) {
                                tmpSlot = +1;
                            }
                        } else {
                            if (tmpSlot == -1) {
                                tmpSlot = 0;
                            } else if (tmpSlot == 0) {
                                tmpSlot = +1;
                            } else if (tmpSlot == +1) {
                                tmpSlot = -1;
                            }
                        }
                        [[toLoad objectAtIndex:i] setObject:[NSNumber numberWithInt:tmpSlot] forKey:@"slot"];
                    }
                                        
                    // Since we are not loading anything we have to reset the delayer flag
                    currentPageIsDelayingLoading = NO;
                    
                    // Dispatch focus event on new current page
                    [self webView:currPage dispatchHTMLEvent:@"focus"];
                }
                
                [self getPageHeight];
                
                tapNumber = 0;
                if (direction < 0) {
                    
                    // REMOVE OTHER NEXT page from toLoad stack
                    for (int i = 0; i < [toLoad count]; i++) {
                        if ([[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue] == +1) {
                            [toLoad removeObjectAtIndex:i];
                        }   
                    }
                    
                    // PRELOAD NEXT page
                    if (currentPageNumber < totalPages) {
                        [self addPageLoading:+1];
                    }
                    
                } else {
                    
                    // REMOVE OTHER PREV page from toLoad stack
                    for (int i = 0; i < [toLoad count]; i++) {
                        if ([[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue] == -1) {
                            [toLoad removeObjectAtIndex:i];
                        }   
                    }
                    
                    // PRELOAD PREV page
                    if (currentPageNumber > 1) {
                        [self addPageLoading:-1];
                    }
                }
            }
            
            [self handlePageLoading];
        }
        else
        {
            tapNumber = 0;
            
            [toLoad removeAllObjects];
            [currPage removeFromSuperview];            
            
            [self addPageLoading:0];
            [self handlePageLoading];
        }
    }
}
- (void)lockPage:(BOOL)lock {
    if (lock)
    {
        if (scrollView.scrollEnabled) {
            scrollView.scrollEnabled = NO;
        }
        currentPageIsLocked = YES;
    }
    else
    {
        if (stackedScrollingAnimations == 0) {
            scrollView.scrollEnabled = [[properties get:@"-baker-page-turn-swipe", nil] boolValue]; // YES by default, NO if specified
        }
        currentPageIsLocked = NO;
    }
}
- (void)addPageLoading:(int)slot {    
    NSLog(@"• Add page to the loding queue");

    NSArray *objs = [NSArray arrayWithObjects:[NSNumber numberWithInt:slot], [NSNumber numberWithInt:currentPageNumber + slot], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"slot", @"page", nil];
    
    if (slot == 0) {
        [toLoad insertObject:[NSMutableDictionary dictionaryWithObjects:objs forKeys:keys] atIndex:0];
    } else {
        [toLoad addObject:[NSMutableDictionary dictionaryWithObjects:objs forKeys:keys]];
    }
}
- (void)handlePageLoading {
    if ([toLoad count] != 0) {
                
        int slot = [[[toLoad objectAtIndex:0] valueForKey:@"slot"] intValue];
        int page = [[[toLoad objectAtIndex:0] valueForKey:@"page"] intValue];
        
        NSLog(@"• Handle loading of slot %d with page %d", slot, page);
        
        [toLoad removeObjectAtIndex:0];
        
        if ([renderingType isEqualToString:@"screenshots"] && ![self checkScreeshotForPage:page andOrientation:[self getCurrentInterfaceOrientation]]) {
            [self lockPage:YES];
        }
        
        [self loadSlot:slot withPage:page];
    }
}
- (void)loadSlot:(int)slot withPage:(int)page {
	NSLog(@"• Setup new page for loading");
    
    UIWebView *webView = [[[UIWebView alloc] init] autorelease];
    [self setupWebView:webView];
    
    webView.frame = [self frameForPage:page];
    webView.hidden = YES;
	
	// ****** SELECT
    // Since pointers can change at any time we've got to handle them directly on a slot basis.
    // Save the page pointer to a temp view to avoid code redundancy make Baker go apeshit.
	if (slot == 0) {
        
        if (currPage) {
            currPage.delegate = nil;
            if ([currPage isLoading]) {
                [currPage stopLoading];
            }
            [currPage release];
        }
        currPage = [webView retain];
        currentPageHasChanged = YES;
        
	} else if (slot == +1) {
        
        if (nextPage) {
            nextPage.delegate = nil;
            if ([nextPage isLoading]) {
                [nextPage stopLoading];
            }
            [nextPage release];
        }
        nextPage = [webView retain];
    
    } else if (slot == -1) {
        
        if (prevPage) {
            prevPage.delegate = nil;
            if ([prevPage isLoading]) {
                [prevPage stopLoading];
            }
            [prevPage release];
        }
        prevPage = [webView retain];
    }
    
    
    ((UIScrollView *)[[webView subviews] objectAtIndex:0]).pagingEnabled = [[properties get:@"-baker-vertical-pagination", nil] boolValue];

    [scrollView addSubview:webView];
	[self loadWebView:webView withPage:page];
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

#pragma mark - SCROLLVIEW
- (CGRect)frameForPage:(int)page {
	return CGRectMake(pageWidth * (page - 1), 0, pageWidth, pageHeight);
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scroll {
    NSLog(@"• Scrollview will begin dragging");
	[self hideStatusBar];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scroll willDecelerate:(BOOL)decelerate {
    NSLog(@"• Scrollview did end dragging");
}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scroll {
    NSLog(@"• Scrollview will begin decelerating");
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll {
    
    int page = (int)(scroll.contentOffset.x / pageWidth) + 1;
	NSLog(@"• Swiping to page: %d", page);
    
    if (currentPageNumber != page) {
        
        lastPageNumber = currentPageNumber;
        currentPageNumber = page;
        
        tapNumber = tapNumber + (lastPageNumber - currentPageNumber);
        
		currentPageIsDelayingLoading = YES;
		[self gotoPage];
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scroll {
    NSLog(@"• Scrollview did end scrolling animation");
    
    stackedScrollingAnimations--;
    if (stackedScrollingAnimations == 0) {
        NSLog(@"    Scroll enabled");
		scroll.scrollEnabled = [[properties get:@"-baker-page-turn-swipe", nil] boolValue]; // YES by default, NO if specified
	}
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
		return YES;
	}
    else
    {        
		// ****** Handle URI schemes
		if (url)
        {
			// Existing, checking if index...
            if([[url lastPathComponent] isEqualToString:INDEX_FILE_NAME])
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
                        NSRegularExpression *referrerRegex = [NSRegularExpression regularExpressionWithPattern:URL_OPEN_EXTERNAL options:NSRegularExpressionCaseInsensitive error:NULL];
                        NSUInteger matches = [referrerRegex numberOfMatchesInString:params options:0 range:NSMakeRange(0, [params length])];
                        
                        if (matches > 0) {
                            NSLog(@"    Link contain param \"%@\" --> open link in Safari", URL_OPEN_EXTERNAL);
                            
                            // Generate new URL without
                            // We are regexp-ing three things: the string alone, the string first with other content, the string with other content in any other position
                            NSRegularExpression *replacerRegexp = [NSRegularExpression regularExpressionWithPattern:[[NSString alloc] initWithFormat:@"\\?%@$|(?<=\\?)%@&?|()&?%@", URL_OPEN_EXTERNAL, URL_OPEN_EXTERNAL, URL_OPEN_EXTERNAL] options:NSRegularExpressionCaseInsensitive error:NULL];
                            NSString *oldURL = [url absoluteString];
                            NSLog(@"  kjasdkajdals: %@", [replacerRegexp pattern]);
                            NSString *newURL = [replacerRegexp stringByReplacingMatchesInString:oldURL options:0 range:NSMakeRange(0, [oldURL length]) withTemplate:@""];
                            
                            NSLog(@"    Opening with updated URL: %@", newURL);
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:newURL]];
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
    
    if (webView.hidden == YES)
    {
        if ([webView isEqual:currPage]) {
            currentPageHasChanged = NO;
            [self getPageHeight];
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
        
    if (animating) {
        
        webView.hidden = NO;
        webView.alpha = 0.0;
        
        [scrollView addSubview:webView];
        [UIView animateWithDuration:0.5
                         animations:^{ webView.alpha = 1.0; }
                         completion:^(BOOL finished) { [self webViewDidAppear:webView animating:animating]; }];
	} else {
        
        [scrollView addSubview:webView];
        [self webViewDidAppear:webView animating:animating];
	}
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
                [self goDownInPage:currPageScrollIndex animating:YES];
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
- (void)webView:(UIWebView *)webView dispatchHTMLEvent:(NSString *)event;
{
    NSString *jsDispatchEvent = [NSString stringWithFormat:@"var bakerDispatchedEvent = document.createEvent('Events');\
                                                             bakerDispatchedEvent.initEvent('%@', false, false);\
                                                             window.dispatchEvent(bakerDispatchedEvent);", event];
    
    [webView stringByEvaluatingJavaScriptFromString:jsDispatchEvent];
}

#pragma mark - SCREENSHOTS
- (void)initScreenshots {
    
    for (int i = 1; i <= totalPages; i++)
    {
        if ([self checkScreeshotForPage:i andOrientation:@"portrait"]) {
            [self placeScreenshotForView:nil andPage:i andOrientation:@"portrait"];
        }
            
        if ([self checkScreeshotForPage:i andOrientation:@"landscape"]) {
            [self placeScreenshotForView:nil andPage:i andOrientation:@"landscape"];
        }
    }
}
- (BOOL)checkScreeshotForPage:(int)pageNumber andOrientation:(NSString *)interfaceOrientation {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachedScreenshotsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachedScreenshotsPath withIntermediateDirectories:YES attributes:nil error:nil];
        [self addSkipBackupAttributeToItemAtPath:cachedScreenshotsPath];
    }
    
    NSString *screenshotFile = [cachedScreenshotsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"screenshot-%@-%i.jpg", interfaceOrientation, pageNumber]];
    return [[NSFileManager defaultManager] fileExistsAtPath:screenshotFile];
}
- (void)takeScreenshotFromView:(UIWebView *)webView forPage:(int)pageNumber andOrientation:(NSString *)interfaceOrientation {
    
    BOOL shouldRevealWebView = YES;
    BOOL animating = YES;
    
    if (![self checkScreeshotForPage:pageNumber andOrientation:interfaceOrientation]) {
        
        NSLog(@"• Taking screenshot of page %d", pageNumber);
        
        NSString *screenshotFile = [cachedScreenshotsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"screenshot-%@-%i.jpg", interfaceOrientation, pageNumber]];
        UIImage *screenshot = nil;
        
        if ([interfaceOrientation isEqualToString:[self getCurrentInterfaceOrientation]] && !currentPageHasChanged) {
            
            UIGraphicsBeginImageContextWithOptions(webView.frame.size, NO, [[UIScreen mainScreen] scale]);
            [webView.layer renderInContext:UIGraphicsGetCurrentContext()];
            screenshot = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if (screenshot) {
                BOOL saved = [UIImageJPEGRepresentation(screenshot, 0.6) writeToFile:screenshotFile options:NSDataWritingAtomic error:nil];
                if (saved) {
                    NSLog(@"    Screenshot succesfully saved to file %@", screenshotFile);
                    [self placeScreenshotForView:webView andPage:pageNumber andOrientation:interfaceOrientation];
                    
                    shouldRevealWebView = NO;
                }
            }
        }
    } 
    else
    {
        animating = NO;
    }
    
    [self lockPage:NO];
    
    if (!currentPageHasChanged && shouldRevealWebView) {
        
        if (animating)
        {
            [self webView:webView hidden:NO animating:animating];
        } 
        else
        {
            webView.hidden = YES;
            [scrollView addSubview:webView];
            [webView performSelector:@selector(setHidden:) withObject:NO afterDelay:0.1];
            [self webViewDidAppear:webView animating:animating];
        }
    }
}
- (void)placeScreenshotForView:(UIWebView *)webView andPage:(int)pageNumber andOrientation:(NSString *)interfaceOrientation {
            
    int i = pageNumber - 1;
    NSString    *screenshotFile = [cachedScreenshotsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"screenshot-%@-%i.jpg", interfaceOrientation, pageNumber]];
    UIImageView *screenshotView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:screenshotFile]];
 
    CGSize pageSize = CGSizeMake(screenBounds.size.width, screenBounds.size.height);
    if ([interfaceOrientation isEqualToString:@"landscape"]) {
        pageSize = CGSizeMake(screenBounds.size.height, screenBounds.size.width);
    }
    
    screenshotView.frame = CGRectMake(pageSize.width * i, 0, pageSize.width, pageSize.height);
    screenshotView.hidden = YES;
    
    BOOL alreadyPlaced = NO;
    if (pageDetails.count > i && [pageDetails objectAtIndex:i] != nil)
    {
        NSMutableDictionary *details = [pageDetails objectAtIndex:i];
        NSString *key = [NSString stringWithFormat:@"screenshot-%@", interfaceOrientation];
        UIImageView *oldScreenshotView = [details objectForKey:key]; 
        
        if (oldScreenshotView != nil) {            
            [scrollView addSubview:screenshotView];
            [oldScreenshotView removeFromSuperview];
            [details removeObjectForKey:key];
            
            alreadyPlaced = YES;
        }
        [details setObject:screenshotView forKey:[NSString stringWithFormat:@"screenshot-%@", interfaceOrientation]];
    }
    
    if (webView == nil) {
        [scrollView addSubview:screenshotView];
    }
    
    if (webView != nil) {
        
        if (alreadyPlaced) {
            
            screenshotView.hidden = NO;
            [self webView:webView hidden:NO animating:NO];
            
        } else if ([interfaceOrientation isEqualToString:[self getCurrentInterfaceOrientation]] && !currentPageHasChanged) {
        
            screenshotView.hidden = NO;
            screenshotView.alpha = 0.0;
            
            [scrollView addSubview:screenshotView];
            [UIView animateWithDuration:0.5
                             animations:^{ screenshotView.alpha = 1.0; }
                             completion:^(BOOL finished) { if (!currentPageHasChanged) { [self webView:webView hidden:NO animating:NO]; }}];
        }
    }
    
    [screenshotView release];
}

#pragma mark - GESTURES
- (void)userDidTap:(UITouch *)touch {
	/****************************************************************************************************
     * This function handles all the possible user navigation taps:
     * up, down, left, right and double-tap.
     */
    
    CGPoint tapPoint = [touch locationInView:self.view];
    NSLog(@"• User tap at [%f, %f]", tapPoint.x, tapPoint.y);
    
    // Swipe or scroll the page.
    if (!currentPageIsLocked) {
        if (CGRectContainsPoint(upTapArea, tapPoint)) {
            NSLog(@"    Tap UP /\\!");
            [self goUpInPage:@"1004" animating:YES];	
        } else if (CGRectContainsPoint(downTapArea, tapPoint)) {
            NSLog(@"    Tap DOWN \\/");
            [self goDownInPage:@"1004" animating:YES];	
        } else if (CGRectContainsPoint(leftTapArea, tapPoint) || CGRectContainsPoint(rightTapArea, tapPoint)) {
            int page = 0;
            if (CGRectContainsPoint(leftTapArea, tapPoint)) {
                NSLog(@"    Tap LEFT >>>");
                page = currentPageNumber - 1;
            } else if (CGRectContainsPoint(rightTapArea, tapPoint)) {
                NSLog(@"    Tap RIGHT <<<");
                page = currentPageNumber + 1;
            }
            if ([[properties get:@"-baker-page-turn-tap", nil] boolValue]) [self changePage:page];
        } else if ((touch.tapCount%2) == 0) {
            [self toggleStatusBar];
        }
    }

}
- (void)userDidScroll:(UITouch *)touch {
	NSLog(@"• User scroll");
	[self hideStatusBar];
}

#pragma mark - PAGE SCROLLING
- (void)getPageHeight {
	for (UIView *subview in currPage.subviews) {
		if ([subview isKindOfClass:[UIScrollView class]]) {
			CGSize size = ((UIScrollView *)subview).contentSize;
			NSLog(@"• Setting current page height from %d to %f", currentPageHeight, size.height);
			currentPageHeight = size.height;
		}
	}
}
- (void)goUpInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	
	int currentPageOffset = [currPageOffset intValue];
	if (currentPageOffset > 0) {
		
		int targetOffset = currentPageOffset-[offset intValue];
		if (targetOffset < 0)
			targetOffset = 0;
		
		NSLog(@"• Scrolling page up to %d", targetOffset);
		
		offset = [NSString stringWithFormat:@"%d", targetOffset];
		[self scrollPage:currPage to:offset animating:animating];
	}
}
- (void)goDownInPage:(NSString *)offset animating:(BOOL)animating {
	
	NSString *currPageOffset = [currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"];
	
	int currentPageMaxScroll = currentPageHeight - pageHeight;
	int currentPageOffset = [currPageOffset intValue];
	
	if (currentPageOffset < currentPageMaxScroll) {
		
		int targetOffset = currentPageOffset+[offset intValue];
		if (targetOffset > currentPageMaxScroll)
			targetOffset = currentPageMaxScroll;
		
		NSLog(@"• Scrolling page down to %d", targetOffset);
		
		offset = [NSString stringWithFormat:@"%d", targetOffset];
		[self scrollPage:currPage to:offset animating:animating];
	}

}
- (void)scrollPage:(UIWebView *)webView to:(NSString *)offset animating:(BOOL)animating {
    [self hideStatusBar];
	
	NSString *jsCommand = [NSString stringWithFormat:@"window.scrollTo(0,%@);", offset];
	if (animating) {
        [UIView animateWithDuration:0.35 animations:^{ [webView stringByEvaluatingJavaScriptFromString:jsCommand]; }];
	} else {
		[webView stringByEvaluatingJavaScriptFromString:jsCommand];
	}
}
- (void)handleAnchor:(BOOL)animating {
	if (anchorFromURL != nil) {
		NSString *jsAnchorHandler = [NSString stringWithFormat:@"(function() {\
									 var target = '%@';\
									 var elem = document.getElementById(target);\
									 if (!elem) elem = document.getElementsByName(target)[0];\
									 return elem.offsetTop;\
									 })();", anchorFromURL];
		
		NSString *offset = [currPage stringByEvaluatingJavaScriptFromString:jsAnchorHandler];
		
		if (![offset isEqualToString:@""]) {
			[self goDownInPage:offset animating:animating];
        }
		anchorFromURL = nil;
	}
}

#pragma mark - STATUS BAR
- (void)toggleStatusBar {
    NSLog(@"• Toggle status bar visibility");
    
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    BOOL hidden = sharedApplication.statusBarHidden;
    [sharedApplication setStatusBarHidden:!hidden withAnimation:UIStatusBarAnimationSlide];
    if(![indexViewController isDisabled]) {
        [indexViewController setIndexViewHidden:!hidden withAnimation:YES];
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
											   message:[OPEN_BOOK_MESSAGE stringByAppendingFormat:@"%@?", URLDownload]
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
        
        currentPageIsDelayingLoading = YES;
		[self initBook:bundleBookPath];
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
		[self initBook:documentsBookPath];
	}
}

#pragma mark - ORIENTATION
- (NSString *)getCurrentInterfaceOrientation {
    if ([availableOrientation isEqualToString:@"portrait"] || [availableOrientation isEqualToString:@"landscape"])
    {
        return availableOrientation;
    } 
    else {
		// WARNING!!! Seems like checking [[UIDevice currentDevice] orientation] against "UIInterfaceOrientationPortrait" is broken (return FALSE with the device in portrait orientation)
		// Safe solution: always check if the device is in landscape orientation, if FALSE then it's in portrait.
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            return @"landscape";
        } else {
            return @"portrait";
        }
	}
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Overriden to allow any orientation.
	if ([availableOrientation isEqualToString:@"portrait"]) {
		return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	} else if ([availableOrientation isEqualToString:@"landscape"]) {
		return (interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
	} else {
		return YES;
	}	
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    // Notify the index view
    [indexViewController willRotate];
    
    // Since the UIWebView doesn't handle orientationchange events correctly we have to do handle them ourselves 
    // 1. Set the correct value for window.orientation property
    NSString *jsOrientationGetter;
    switch (toInterfaceOrientation) {
        case UIDeviceOrientationPortrait:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 0; });";
            break;
        case UIDeviceOrientationLandscapeLeft:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 90; });";
            break;
        case UIDeviceOrientationLandscapeRight:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return -90; });";
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            jsOrientationGetter = @"window.__defineGetter__('orientation', function() { return 180; });";
            break;
        default:
            break;
    }
    
    // 2. Create and dispatch a orientationchange event    
    NSString *jsOrientationChange = @"if (typeof bakerOrientationChangeEvent === 'undefined') {\
                                          var bakerOrientationChangeEvent = document.createEvent('Events');\
                                              bakerOrientationChangeEvent.initEvent('orientationchange', false, false);\
                                      }; window.dispatchEvent(bakerOrientationChangeEvent)";
    
    // 3. Merge the scripts and load them on the current UIWebView
    NSString *jsCommand = [jsOrientationGetter stringByAppendingString:jsOrientationChange];
    [currPage stringByEvaluatingJavaScriptFromString:jsCommand];
}
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [indexViewController rotateFromOrientation:fromInterfaceOrientation toOrientation:self.interfaceOrientation];
    
    [self setPageSize:[self getCurrentInterfaceOrientation]];
    [self getPageHeight];    
	[self resetScrollView];
}

#pragma mark - MEMORY
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}
- (void)viewDidUnload {
    
	[super viewDidUnload];
	
	// Set web views delegates to nil, mandatory before releasing UIWebview instances
    currPage.delegate = nil;
	nextPage.delegate = nil;
	prevPage.delegate = nil;
}
- (void)dealloc {
    
    [cachedScreenshotsPath release];
    [defaultScreeshotsPath release];

    [documentsBookPath release];
    [bundleBookPath release];

    [pageDetails release];
    [toLoad release];
    [pages release];
    
    [indexViewController release];
    [scrollView release];
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

@end
