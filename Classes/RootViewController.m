//
//  RootViewController.m
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

#import <QuartzCore/QuartzCore.h>
#import "RootViewController.h"
#import "Downloader.h"
#import "SSZipArchive.h"
#import "NSDictionary_JSONExtensions.h"
#import "PageTitleLabel.h"
#import "Utils.h"

// THREE CARD
// Enable three card loading method.
//  NO (Default) - Only the current page is load.
//  YES - Three pages (current, next and previous) are loaded.
#define ENABLE_THREE_CARD NO

// PINCH-TO-ZOOM
// Enable pinch-to-zoom on the book page.
//   NO (Default) - Because it creates a more uniform reading experience: you should zoom only specific items with JavaScript.
//   YES - Not recommended. You have to manually set the zoom in EACH of your HTML files.
#define PAGE_ZOOM_GESTURE NO

// VERTICAL BOUNCE
// Enable bounce effect on vertical scrolls.
// Should be set to NO only when the book pages don't need any vertical scrolling.
#define PAGE_VERTICAL_BOUNCE YES

// MEDIA PLAYBACK REQUIRES USER ACTION
// Enable automatic HTML5 media playback.
//   YES (Default) - Media required user action to be started.
//   NO - Media can be played automatically.
#define MEDIA_PLAYBACK_REQUIRES_USER_ACTION YES

// ALERT LABELS
#define OPEN_BOOK_MESSAGE @"Do you want to download "
#define OPEN_BOOK_CONFIRM @"Open book"

#define CLOSE_BOOK_MESSAGE @"Do you want to close this book?"
#define CLOSE_BOOK_CONFIRM @"Close book"

#define ZERO_PAGES_TITLE   @"Whoops!"
#define ZERO_PAGES_MESSAGE @"Sorry, that book had no pages."

#define ERROR_FEEDBACK_TITLE   @"Whoops!"
#define ERROR_FEEDBACK_MESSAGE @"There was a problem downloading the book."
#define ERROR_FEEDBACK_CONFIRM @"Retry"

#define EXTRACT_FEEDBACK_TITLE @"Extracting..."

#define ALERT_FEEDBACK_CANCEL  @"Cancel"

// AVAILABLE ORIENTATION
// Define the available orientation of the book
//	@"Any" (Default) - Book is available in both orientation
//	@"Portrait" - Book is available only in portrait orientation
//	@"Landscape" - Book is available only in landscape orientation
#define	AVAILABLE_ORIENTATION @"Any"

#define INDEX_FILE_NAME @"index.html"

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
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"book/book" ofType:@"json"];
        [properties loadManifest:filePath];
      
        // ****** DEVICE SCREEN BOUNDS
        screenBounds = [[UIScreen mainScreen] bounds];
        NSLog(@"    Device Width: %f", screenBounds.size.width);
        NSLog(@"    Device Height: %f", screenBounds.size.height);
        
        // ****** BOOK DIRECTORIES
        NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [NSString stringWithString:[documentsPaths objectAtIndex:0]];
        documentsBookPath = [[documentsPath stringByAppendingPathComponent:@"book"] retain];
        
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = ([cachePaths count] > 0) ? [cachePaths objectAtIndex:0] : nil;
        cachedSnapshotsPath = [[cachePath stringByAppendingPathComponent:@"snapshots"] retain];
        [[NSFileManager defaultManager] createDirectoryAtPath:cachedSnapshotsPath withIntermediateDirectories:YES attributes:nil error:nil];

        bundleBookPath = [[[NSBundle mainBundle] pathForResource:@"book" ofType:nil] retain];
        
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
        currentPageIsLocked = YES;
        discardNextStatusBarToggle = NO;
                
        // ****** LISTENER FOR DOWNLOAD NOTIFICATION
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadBook:) name:@"downloadNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadResult:) name:@"handleDownloadResult" object:nil];
                
        [self setPageSize:[self getCurrentInterfaceOrientation]];
        [self hideStatusBar];
        
        // ****** SCROLLVIEW INIT
        scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, pageWidth, pageHeight)];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.backgroundColor = [Utils colorWithHexString:[properties get:@"-baker-background", nil]];
        scrollView.showsHorizontalScrollIndicator = YES;
        scrollView.showsVerticalScrollIndicator = NO;
        scrollView.delaysContentTouches = NO;
        scrollView.pagingEnabled = YES;
        scrollView.delegate = self;
        [self.view addSubview:scrollView];
        
        // ****** CURR WEBVIEW INIT
        currPage = [[UIWebView alloc] init];
        [self setupWebView:currPage];
        
        // ****** NEXT WEBVIEW INIT
        nextPage = [[UIWebView alloc] init];
        [self setupWebView:nextPage];
        
        // ****** PREV WEBVIEW INIT
        prevPage = [[UIWebView alloc] init];
        [self setupWebView:prevPage];
        
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
    
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	webView.mediaPlaybackRequiresUserAction = MEDIA_PLAYBACK_REQUIRES_USER_ACTION;
	webView.scalesPageToFit = PAGE_ZOOM_GESTURE;
    webView.delegate = self;
	if (!PAGE_VERTICAL_BOUNCE) {
		for (UIView *subview in webView.subviews) {
			if ([subview isKindOfClass:[UIScrollView class]]) {
				((UIScrollView *)subview).bounces = NO;
            }
        }
	}
}
- (void)setPageSize:(NSString *)orientation {	
	NSLog(@"• Set size for orientation: %@", orientation);
    
    pageWidth = screenBounds.size.width;
    pageHeight = screenBounds.size.height;
	if ([orientation isEqualToString:@"Landscape"]) {
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
    currentPageIsLocked = YES;
    
    [self setTappableAreaSize];
    
    for (NSMutableDictionary *details in pageDetails) {
        for (NSString *key in details) {
            UIView *value = [details objectForKey:key];
            value.hidden = YES;
        }
    }
    [self initPageDetailsForPages:totalPages];

    scrollView.contentSize = CGSizeMake(pageWidth * totalPages, pageHeight);

	int scrollViewY = 0;
	if (![UIApplication sharedApplication].statusBarHidden) {
		scrollViewY = -20;
	}    
    [UIView animateWithDuration:0.2 animations:^{
        scrollView.frame = CGRectMake(0, scrollViewY, pageWidth, pageHeight);
    }];
	
    if (prevPage.superview == scrollView) {
        prevPage.frame = [self frameForPage:currentPageNumber - 1];
        [scrollView bringSubviewToFront:prevPage];
    }
    
    if (nextPage.superview == scrollView) {
        nextPage.frame = [self frameForPage:currentPageNumber + 1];
        [scrollView bringSubviewToFront:nextPage];
    }
    
    currPage.frame = [self frameForPage:currentPageNumber];
    [scrollView bringSubviewToFront:currPage];
    [scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
    
    NSLog(@"    Unlock page changing");
    currentPageIsLocked = NO;
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
    
    [[NSFileManager defaultManager] removeItemAtPath:cachedSnapshotsPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:cachedSnapshotsPath withIntermediateDirectories:YES attributes:nil error:nil];
}
- (void)initBook:(NSString *)path {	
    NSLog(@"• Init Book");
    
    [self resetPageDetails];
	
	NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	for (NSString *fileName in dirContent) {
		if ([[fileName pathExtension] isEqualToString:@"html"] && ![fileName isEqualToString:INDEX_FILE_NAME]) {
			[pages addObject:[path stringByAppendingPathComponent:fileName]];
        }
	}
		
	totalPages = [pages count];
	NSLog(@"    Pages in this book: %d", totalPages);
	
	if (totalPages > 0) {
		// Check if there is a saved starting page        
		NSString *currPageToLoad = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageViewed"];
		
        currentPageNumber = 1;
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
		
        currentPageIsDelayingLoading = YES;
        [toLoad removeAllObjects];
		
        [self resetScrollView];        
        [scrollView addSubview:currPage];
        [self addPageLoading:0];
        
        if (ENABLE_THREE_CARD) {
            if (currentPageNumber != totalPages) {
                if (nextPage.superview != scrollView) {
                    [scrollView addSubview:nextPage];
                }
                [self addPageLoading:+1];
            } else if (currentPageNumber == totalPages && nextPage.superview == scrollView) {
                [nextPage removeFromSuperview];
            }
            
            if (currentPageNumber != 1) {
                if (prevPage.superview != scrollView) {
                    [scrollView addSubview:prevPage];
                }
                [self addPageLoading:-1];
            } else if (currentPageNumber == 1 && prevPage.superview == scrollView) {
                [prevPage removeFromSuperview];
            }
        }
            
        [self handlePageLoading];
        [indexViewController loadContentFromBundle:[path isEqualToString:bundleBookPath]];
		
	} else {
		
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
 		feedbackAlert = [[UIAlertView alloc] initWithTitle:ZERO_PAGES_TITLE
												   message:ZERO_PAGES_MESSAGE
												  delegate:self
										 cancelButtonTitle:ALERT_FEEDBACK_CANCEL
										 otherButtonTitles:nil];
		[feedbackAlert show];
		[feedbackAlert release];
		
		[self initBook:bundleBookPath];
	}
}
- (void)initPageDetailsForPages:(int)count {
    NSLog(@"• Init and show page details for the book pages");
    
	for (int i = 0; i < count; i++) {
        
        if (pageDetails.count > i && [pageDetails objectAtIndex:i] != nil) {
            
            NSDictionary *details = [NSDictionary dictionaryWithDictionary:[pageDetails objectAtIndex:i]];  
            
            NSString *orientation = [self getCurrentInterfaceOrientation];
            UIView *snapView = [details objectForKey:[NSString stringWithFormat:@"snap-%@", orientation]];
            if (snapView != nil)
            {
                snapView.hidden = NO;
            } 
            else {
                
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
                        
                        } else {
                            
                            value.hidden = YES;
                        }
                    }
                }
            }
                        
        } else {
        
            // ****** Spinners
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            spinner.backgroundColor = [UIColor clearColor];
            
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
            number.textColor = [Utils colorWithHexString:[properties get:@"-baker-page-numbers-color", nil]];
            number.textAlignment = UITextAlignmentCenter;
            id alpha = [properties get:@"-baker-page-numbers-alpha", nil];
            number.alpha = [(NSNumber*) alpha floatValue];
            number.text = [NSString stringWithFormat:@"%d", i + 1];
            
            [scrollView addSubview:number];
            [number release];
            
            // ****** Title
            PageTitleLabel *title = [[PageTitleLabel alloc]initWithFile:[pages objectAtIndex: i]];
            [title setX:(pageWidth * i + ((pageWidth - title.frame.size.width) / 2)) Y:(pageHeight / 2 + 20)];
            [scrollView addSubview:title];
            [title release];
            
            NSMutableDictionary *details = [NSMutableDictionary dictionaryWithObjectsAndKeys:spinner, @"spinner", number, @"number", title, @"title", nil];
            [pageDetails insertObject:details atIndex:i];
        }
	}
}

#pragma mark - LOADING
- (BOOL)changePage:(int)page {
    NSLog(@"• Check if page has changed");
    
    BOOL pageChanged = NO;
	
    if (page < 1) {
		currentPageNumber = 1;
	} else if (page > totalPages) {
		currentPageNumber = totalPages;
	} else if (page != currentPageNumber) {
        
        NSLog(@"    Prevent page from changing until its loading is finished");
        currentPageIsLocked = YES;
        scrollView.scrollEnabled = NO;
        //stackedScrollingAnimations++;
        
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
        
        if (ENABLE_THREE_CARD)
        {
            // ****** THREE CARD VIEW METHOD
            // ****** Calculate move direction and normalize tapNumber
            int direction = 1;
            if (tapNumber < 0) {
                direction = -direction;
                tapNumber = -tapNumber;
            }
            
            NSLog(@"    Tap number: %d", tapNumber);
            
            if (tapNumber > 2) {
                
                [toLoad removeAllObjects];
                
                // ****** Moved away for more than 2 pages: RELOAD ALL pages
                tapNumber = 0;
                
                [self addPageLoading:0];
                if (currentPageNumber < totalPages)
                    [self addPageLoading:+1];
                if (currentPageNumber > 1)
                    [self addPageLoading:-1];
                            
            } else {
                
                int tmpSlot = 0;
                if (tapNumber == 2) {
                
                    // ****** Moved away for 2 pages: RELOAD CURRENT page

                    if (direction < 0) {
                        // ****** Move LEFT <<<
                        UIWebView *tmpView = prevPage;
                        prevPage = nextPage;
                        nextPage = tmpView;
                    } else {
                        // ****** Move RIGHT >>>
                        UIWebView *tmpView = nextPage; 
                        nextPage = prevPage;
                        prevPage = tmpView;
                    }
                    
                    // Adjust pages slot in the stack to reflect the webviews pointer change
                    for (int i = 0; i < [toLoad count]; i++) {
                        tmpSlot =  -1 * [[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue];
                        [[toLoad objectAtIndex:i] setObject:[NSNumber numberWithInt:tmpSlot] forKey:@"slot"];
                    }
                    
                    [self addPageLoading:0];
                
                } else if (tapNumber == 1) {
                                    
                    if (direction < 0) { 
                        // ****** Move LEFT <<<
                        UIWebView *tmpView = prevPage;
                        prevPage = currPage;
                        currPage = nextPage;
                        nextPage = tmpView;
                    } else { 
                        // ****** Move RIGHT >>>
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
                    
                    [scrollView bringSubviewToFront:currPage];
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
                    if (currentPageNumber < totalPages)
                        [self addPageLoading:+1];
                    
                } else {
                    
                    // REMOVE OTHER PREV page from toLoad stack
                    for (int i = 0; i < [toLoad count]; i++) {
                        if ([[[toLoad objectAtIndex:i] valueForKey:@"slot"] intValue] == -1) {
                            [toLoad removeObjectAtIndex:i];
                        }   
                    }
                    
                    // PRELOAD PREV page
                    if (currentPageNumber > 1)
                        [self addPageLoading:-1];
                }
            }
            
            if (currentPageNumber != totalPages && nextPage.superview != scrollView) {
                [scrollView addSubview:nextPage];
            } else if (currentPageNumber == totalPages && nextPage.superview == scrollView) {
                [nextPage removeFromSuperview];
                
                NSLog(@"    Nothing to load, unlock page");
                currentPageIsLocked = NO;
                scrollView.scrollEnabled = YES;
            }
            
            if (currentPageNumber != 1 && prevPage.superview != scrollView) {
                [scrollView addSubview:prevPage];
            } else if (currentPageNumber == 1 && prevPage.superview == scrollView) {
                [prevPage removeFromSuperview];
                
                NSLog(@"    Nothing to load, unlock page");
                currentPageIsLocked = NO;
                scrollView.scrollEnabled = YES;
            }
            
            [self handlePageLoading];
        }
        else
        {
            [toLoad removeAllObjects];
            
            tapNumber = 0;
            
            [self addPageLoading:0];
            [self handlePageLoading];
        }
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
        [self loadSlot:slot withPage:page];
    }
}
- (void)loadSlot:(int)slot withPage:(int)page {
	NSLog(@"• Setup new page for loading");
    
	UIWebView *webView = nil;
	
	// ****** SELECT
	if (slot == 0) {
		webView = currPage;
	} else if (slot == +1) {
		webView = nextPage;
	} else if (slot == -1) {
		webView = prevPage;
	}
    
    if ([webView isLoading]) {
        [webView stopLoading];
    }

    webView.frame = [self frameForPage:page];
	[self loadWebView:webView withPage:page];
}
- (BOOL)loadWebView:(UIWebView*)webView withPage:(int)page {
	
	NSString *path = [NSString stringWithString:[pages objectAtIndex:page-1]];
		
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSLog(@"• Loading: book/%@", [[NSFileManager defaultManager] displayNameAtPath:path]);
        webView.hidden = YES; // use direct property instead of [self webView:hidden:animating:] otherwise it won't work
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
    scrollView.scrollEnabled = NO;
}
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scroll {
    NSLog(@"• Scrollview will begin decelerating");
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scroll {
    
    int page = (int)(scroll.contentOffset.x / pageWidth) + 1;
	NSLog(@"• Swiping to page: %d", page);
    
    if (currentPageNumber != page) {
        
        NSLog(@"    Prevent page from changing until its loading is finished");
        currentPageIsLocked = YES;
        scrollView.scrollEnabled = NO;
        
        lastPageNumber = currentPageNumber;
        currentPageNumber = page;
        
        tapNumber = tapNumber + (lastPageNumber - currentPageNumber);
        
		currentPageIsDelayingLoading = YES;
		[self gotoPage];
    } else {
        scrollView.scrollEnabled = YES;
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scroll {
    NSLog(@"• Scrollview did end scrolling animation");
    
    /*
    stackedScrollingAnimations--;
    if (stackedScrollingAnimations == 0) {
        NSLog(@"    Scroll enabled");
		scroll.scrollEnabled = YES;
	}
    */
}

#pragma mark - WEBVIEW
- (void)webViewDidStartLoad:(UIWebView *)webView {
	// Sent before a web view begins loading content.
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"• Page did finish load");
    
	// Sent after a web view finishes loading content.	
	
	if ([webView isEqual:currPage]) {
		// Get current page max scroll offset
		[self getPageHeight];
		
        if ([self checkSnapshot:currentPageNumber]) {
            NSLog(@"   Handle saved hash reference if necessary");
            [self handleAnchor:NO];
        }
	}
	
	// /!\ hack to make it load at the right time and not too early
	// source: http://stackoverflow.com/questions/1422146/webviewdidfinishload-firing-too-soon
	//NSString *javaScript = @"<script type=\"text/javascript\">function myFunction(){return 1+1;}</script>";
	//[webView stringByEvaluatingJavaScriptFromString:javaScript];
	
	[self performSelector:@selector(revealWebView:) withObject:webView afterDelay:0.1]; // This seems fixing the WebView-Flash-Of-Old-Content-webBug 
    [self handlePageLoading];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	// Sent if a web view failed to load content.
    if (webView == currPage) {
		NSLog(@"• CurrPage failed to load content with error: %@", error);
	} else if (webView == prevPage) {
		NSLog(@"• PrevPage failed to load content with error: %@", error);
	} else if (webView == nextPage) {
		NSLog(@"• NextPage failed to load content with error: %@", error);
    }
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	// Sent before a web view begins loading content, useful to trigger actions before the WebView.	
	NSLog(@"• Should webView load the page ?");
    
    if ([webView isEqual:prevPage]) {
        NSLog(@"    Page is prev page --> load page");
        return YES;
    } else if ([webView isEqual:nextPage]) {
        NSLog(@"    Page is next page --> load page");
        return YES;
    } else if (currentPageIsDelayingLoading) {		
		NSLog(@"    Page is current page and current page IS delaying loading --> load page");
		currentPageIsDelayingLoading = NO;
		return YES;
	} else {
		
		[self hideStatusBarDiscardingToggle:YES];
		
		NSURL *url = [request URL];
		NSLog(@"    Page is current page and current page IS NOT delaying loading --> handle index or clicked link: %@", [url absoluteString]);
		
		// ****** Handle URI schemes
		if (url) {
			// Existing, checking schemes...
			if([[url lastPathComponent] isEqualToString:INDEX_FILE_NAME]){
                NSLog(@"    Page is index --> load index");
                return YES; // Let the index view load
            }
			if ([[url scheme] isEqualToString:@"file"]) {
				// ****** Handle: file://
				NSLog(@"    Page is a link with scheme file:// --> load internal link");
				
				anchorFromURL = [[url fragment] retain];
				NSString *file = [[url relativePath] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				
                int page = (int)[pages indexOfObject:file] + 1;
                
				if (![self changePage:page]) {
					[self handleAnchor:YES];
				}
				
			} else if ([[url scheme] isEqualToString:@"book"]) {
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
					
					// *** Download book
					URLDownload = [[@"http:" stringByAppendingString:[url resourceSpecifier]] retain];
					
					if ([[[NSURL URLWithString:URLDownload] pathExtension] isEqualToString:@""]) {
						URLDownload = [[URLDownload stringByAppendingString:@".hpub"] retain];
					}
					
					[self downloadBook:nil];
				}
			} else {
				// ****** Handle: *
                NSLog(@"    Page is a external link --> open Safari");
				[[UIApplication sharedApplication] openURL:[request URL]];
			}
		}
		
		return NO;
	}
}
- (void)webView:(UIWebView *)webView hidden:(BOOL)status animating:(BOOL)animating {
	NSLog(@"• webView hidden: %d animating: %d", status, animating);
	
    webView.alpha = 0.0;
    webView.hidden = NO;
        
    if (animating && ![self checkSnapshot:currentPageNumber]) {
        [UIView animateWithDuration:0.5
                         animations:^{ webView.alpha = 1.0; }
                         completion:^(BOOL finished) {
                             if ([webView isEqual:currPage]) {
                                 if (!ENABLE_THREE_CARD) {
                                     NSLog(@"   Current page has appeared, taking snapshot if necessary");
                                     [self takeSnapshot];
                                 }
                                 
                                 [scrollView bringSubviewToFront:webView];
                                                                  
                                 // If is the first time i load something in the currPage web view...
                                 if (currentPageFirstLoading) {			
                                     // ... check if there is a saved starting scroll index and set it
                                     NSLog(@"   Handle last scroll index if necessary");
                                     NSString *currPageScrollIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastScrollIndex"];
                                     if (currPageScrollIndex != nil) {
                                         [self goDownInPage:currPageScrollIndex animating:YES];
                                     }
                                     currentPageFirstLoading = NO;
                                 } else {
                                     NSLog(@"   Handle saved hash reference if necessary");
                                     [self handleAnchor:YES];
                                 }
                             }
                             
                             if ([toLoad count] == 0) {
                                 NSLog(@"   There are no more pages to load, unlock pages");
                                 currentPageIsLocked = NO;
                                 scrollView.scrollEnabled = YES;
                             }
                         }];
	} else {
        
		webView.alpha = 1.0;
        if ([toLoad count] == 0) {
            NSLog(@"   Page has appeared, there are no more pages to load, unlock pages");
            currentPageIsLocked = NO;
            scrollView.scrollEnabled = YES;
        }
        
        if ([webView isEqual:currPage]) {
            NSLog(@"   Handle saved hash reference if necessary");
            [self handleAnchor:YES];
        }
	}
    
}
- (void)revealWebView:(UIWebView *)webView {
    // Delayed run to fix the WebView-Flash-Of-Old-Content-Bug
	[self webView:webView hidden:NO animating:YES];
}

#pragma mark - SNAPSHOTS
- (BOOL)checkSnapshot:(int)pageNumber {
    NSString *snapshotFile = [cachedSnapshotsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"snap-%@-%i.jpg", [self getCurrentInterfaceOrientation], pageNumber]];
    return [[NSFileManager defaultManager] fileExistsAtPath:snapshotFile];
}
- (void)takeSnapshot {
    
    if (![self checkSnapshot:currentPageNumber]) {
        
        NSLog(@"• Taking snapshot of page %d", currentPageNumber);
        
        NSString *snapshotFile = [cachedSnapshotsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"snap-%@-%i.jpg", [self getCurrentInterfaceOrientation], currentPageNumber]];
        UIImage *snapshot = nil;
        CGSize pageSize = CGSizeMake(pageWidth, pageHeight);
        
        UIGraphicsBeginImageContextWithOptions(pageSize, NO, 1.0);
        [currPage.layer renderInContext:UIGraphicsGetCurrentContext()];
        snapshot = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (snapshot) {
            NSError *error = nil;
            if (![UIImageJPEGRepresentation(snapshot, 0.6) writeToFile:snapshotFile options:NSDataWritingAtomic error:&error]) {
                NSLog(@"    Error while taking snapshot: %@", [error localizedDescription]);
            } else {
                NSLog(@"    Snapshot succesfully saved to file %@", snapshotFile);
                [self placeSnapshot:currentPageNumber];
            }
        }
    }
}
- (void)placeSnapshot:(int)pageNumber {
   
 if ([self checkSnapshot:pageNumber]) {
        
        int i = pageNumber - 1;
        NSString *orientation = [self getCurrentInterfaceOrientation];    
        NSString *snapshotFile = [cachedSnapshotsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"snap-%@-%i.jpg", orientation, pageNumber]];
        
        UIImage *snapshot = [UIImage imageWithContentsOfFile:snapshotFile];
        UIImageView *snapView = [[UIImageView alloc] initWithImage:snapshot];
        snapView.frame = CGRectMake(pageWidth * i, 0, pageWidth, pageHeight);
        
        if (pageDetails.count > i && [pageDetails objectAtIndex:i] != nil) {
            NSMutableDictionary *details = [pageDetails objectAtIndex:i];            
            [details setObject:snapView forKey:[NSString stringWithFormat:@"snap-%@", orientation]];
        }
        
        [scrollView addSubview:snapView];
        [snapView release];
    }
}

#pragma mark - GESTURES
- (void)userDidTap:(UITouch *)touch {
	
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
            [self changePage:page];
        } else if ((touch.tapCount%2) == 0) {
            [self performSelector:@selector(toggleStatusBar) withObject:nil];
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
	if (discardNextStatusBarToggle) {
		// do nothing, but reset the variable
		discardNextStatusBarToggle = NO;
	} else {
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
	[self hideStatusBarDiscardingToggle:NO];
}
- (void)hideStatusBarDiscardingToggle:(BOOL)discardToggle {
	NSLog(@"• Hide status bar %@", (discardToggle ? @"discarding toggle" : @""));
	discardNextStatusBarToggle = discardToggle;
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
	if (buttonIndex != alertView.cancelButtonIndex) {
		if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:CLOSE_BOOK_CONFIRM]){
            currentPageIsDelayingLoading = YES;
			[self initBook:bundleBookPath];
        }
		else{
			[self startDownloadRequest];
        }
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
		NSString *destinationPath = documentsBookPath;
		NSLog(@"    Book destination path: %@", destinationPath);
		
		// If a "book" directory already exists remove it (quick solution, improvement needed) 
		if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:destinationPath error:NULL];
        }
    
		[SSZipArchive unzipFileAtPath:targetPath toDestination:destinationPath];
		NSLog(@"    Book successfully unzipped. Removing .hpub file");
		[[NSFileManager defaultManager] removeItemAtPath:targetPath error:NULL];
				
		[feedbackAlert dismissWithClickedButtonIndex:feedbackAlert.cancelButtonIndex animated:YES];
		[self initBook:destinationPath];
	} /* else {
	   Do something if it was not possible to write the book file on the iPhone/iPad file system...
	} */
}

#pragma mark - ORIENTATION
- (NSString *)getCurrentInterfaceOrientation {
    if ([AVAILABLE_ORIENTATION isEqualToString:@"Portrait"] || [AVAILABLE_ORIENTATION isEqualToString:@"Landscape"])
    {
        return AVAILABLE_ORIENTATION;
    } 
    else {
		// WARNING!!! Seems like checking [[UIDevice currentDevice] orientation] against "UIInterfaceOrientationPortrait" is broken (return FALSE with the device in portrait orientation)
		// Safe solution: always check if the device is in landscape orientation, if FALSE then it's in portrait.
        if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
            return @"Landscape";
        } else {
            return @"Portrait";
        }
	}
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Overriden to allow any orientation.
	if ([AVAILABLE_ORIENTATION isEqualToString:@"Portrait"]) {
		return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	} else if ([AVAILABLE_ORIENTATION isEqualToString:@"Landscape"]) {
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
                                              bakerOrientationChangeEvent.initEvent('orientationchange', true, false);\
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
    
    [indexViewController release];
    [scrollView release];
    [currPage release];
	[nextPage release];
	[prevPage release];
    
    [super dealloc];
}

@end
