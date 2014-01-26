//
//  IndexViewController.m
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

#import "IndexViewController.h"
#import "BakerViewController.h"

@implementation IndexViewController

@synthesize book;

- (id)initWithBook:(BakerBook *)bakerBook fileName:(NSString *)name webViewDelegate:(UIViewController<UIWebViewDelegate> *)delegate {
    self = [super init];
    if (self) {

        self.book = bakerBook;

        fileName = name;
        webViewDelegate = delegate;

        disabled = NO;
        indexWidth = 0;
        indexHeight = 0;

        [self setPageSizeForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
    return self;
}
- (void)dealloc
{
    [book release];
    [indexScrollView release];

    [super dealloc];
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    // Initialization to 1x1px is required to get sizeThatFits to work
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 1024, 1, 1)];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.delegate = self;

    webView.backgroundColor = [UIColor clearColor];
    [webView setOpaque:NO];


    self.view = webView;
    for (UIView *subView in webView.subviews) {
        if ([subView isKindOfClass:[UIScrollView class]]) {
            indexScrollView = [(UIScrollView *)subView retain];
            break;
        }
    }
    [webView release];

    [self loadContent];
}

- (void)setBounceForWebView:(UIWebView *)webView bounces:(BOOL)bounces {
    indexScrollView.bounces = bounces;
}

- (void)setPageSizeForOrientation:(UIInterfaceOrientation)orientation {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];

    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        pageWidth = screenBounds.size.height;
        pageHeight = screenBounds.size.width;
    } else {
        pageWidth = screenBounds.size.width;
        pageHeight = screenBounds.size.height;
    }

    NSLog(@"[IndexView] Set IndexView size to %dx%d", pageWidth, pageHeight);
}

- (void)setActualSize {
    actualIndexWidth = MIN(indexWidth, pageWidth);
    actualIndexHeight = MIN(indexHeight, pageHeight);
}

- (BOOL)isIndexViewHidden {
    return ((BakerViewController*) webViewDelegate).barsHidden;
}

- (BOOL)isDisabled {
    return disabled;
}

- (void)setIndexViewHidden:(BOOL)hidden withAnimation:(BOOL)animation {
    CGRect frame;
    if (hidden) {
        if ([self stickToLeft]) {
            frame = CGRectMake(-actualIndexWidth, [self trueY] + pageHeight - actualIndexHeight, actualIndexWidth, actualIndexHeight);
        } else {
            frame = CGRectMake(0, [self trueY] + pageHeight, actualIndexWidth, actualIndexHeight);
        }
    } else {
        if ([self stickToLeft]) {
            frame = CGRectMake(0, [self trueY] + pageHeight - actualIndexHeight, actualIndexWidth, actualIndexHeight);
        } else {
            frame = CGRectMake(0, [self trueY] + pageHeight - indexHeight, actualIndexWidth, actualIndexHeight);
        }

    }

    if (animation) {
        [UIView beginAnimations:@"slideIndexView" context:nil]; {
            [UIView setAnimationDuration:0.3];

            [self setViewFrame:frame];
        }
        [UIView commitAnimations];
    } else {
        [self setViewFrame:frame];
    }
}

- (int)trueY {
    // Sometimes the origin (0,0) is not where it should be: this horrible hack
    // compensates for it, by exploiting the fact that the superview height is
    // slightly smaller then the viewport height when the origin's y needs to be adjusted.
    int height = self.view.superview.frame.size.height;

    if (height == 320 || height == 480 || height == 568 || height == 768 || height == 1024) {
        return 0;
    } else {
        return -20;
    }
}

- (void)setViewFrame:(CGRect)frame {
    self.view.frame = frame;

    // Orientation changes tend to screw the content size detection performed by the scrollView embedded in the webView.
    // Let's show the scrollView who's boss.
    indexScrollView.contentSize = cachedContentSize;
}

- (void)fadeOut {
    [UIView beginAnimations:@"fadeOutIndexView" context:nil]; {
        [UIView setAnimationDuration:0.0];

        self.view.alpha = 0.0;
    }
    [UIView commitAnimations];
}

- (void)fadeIn {
    [UIView beginAnimations:@"fadeInIndexView" context:nil]; {
        [UIView setAnimationDuration:0.2];

        self.view.alpha = 1.0;
    }
    [UIView commitAnimations];
}

- (void)willRotate {
    [self fadeOut];
}

- (void)rotateFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation toOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    BOOL hidden = [self isIndexViewHidden]; // cache hidden status before setting page size

    [self setPageSizeForOrientation:toInterfaceOrientation];
    [self setActualSize];
    [self setIndexViewHidden:hidden withAnimation:NO];
    [self fadeIn];
}

- (void)adjustIndexView {
    [self setPageSizeForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    [self setActualSize];
    [self setIndexViewHidden:self.isIndexViewHidden withAnimation:NO];
}

- (void)loadContent {
    NSString* path = [self indexPath];

    UIWebView *webView = (UIWebView*) self.view;
    webView.mediaPlaybackRequiresUserAction = ![book.bakerMediaAutoplay boolValue];
    [self setBounceForWebView:webView bounces:[book.bakerIndexBounce boolValue]];

    //NSLog(@"[IndexView] Path to index view is %@", path);
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        disabled = NO;
        [(UIWebView *)self.view loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    } else {
        NSLog(@"[IndexView] Index HTML not found at %@", path);
        disabled = YES;
    }
}
-(void)webViewDidFinishLoad:(UIWebView *)webView {
    id width = book.bakerIndexWidth;
    id height = book.bakerIndexHeight;

    if (width != nil) {
        indexWidth = (int)[width integerValue];
    } else {
        indexWidth = [self sizeFromContentOf:webView].width;
    }
    if (height != nil) {
        indexHeight = (int)[height integerValue];
    } else {
        indexHeight = [self sizeFromContentOf:webView].height;
    }

    cachedContentSize = indexScrollView.contentSize;
    // get correct contentsize
    if (cachedContentSize.width < indexWidth) {
        cachedContentSize = CGSizeMake(indexWidth, indexHeight);
    }
    [self setActualSize];

    NSLog(@"[IndexView] Set size for IndexView to %dx%d (constrained from %dx%d)", actualIndexWidth, actualIndexHeight, indexWidth, indexHeight);

    // After the first load, point the delegate to the main view controller
    webView.delegate = webViewDelegate;

    [self setIndexViewHidden:[self isIndexViewHidden] withAnimation:NO];
}

- (BOOL)stickToLeft {
    return (actualIndexHeight > actualIndexWidth);
}

- (CGSize)sizeFromContentOf:(UIView *)view {
    // Setting the frame to 1x1 is required to get meaningful results from sizeThatFits when
    // the orientation of the is anything but Portrait.
    // See: http://stackoverflow.com/questions/3936041/how-to-determine-the-content-size-of-a-uiwebview/3937599#3937599
    CGRect frame = view.frame;
    frame.size.width = 1;
    frame.size.height = 1;
    view.frame = frame;

    return [view sizeThatFits:CGSizeZero];
}

- (NSString *)indexPath {
    return [book.path stringByAppendingPathComponent:fileName];
}

@end
