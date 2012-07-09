//
//  IndexViewController.m
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

#import "IndexViewController.h"


@implementation IndexViewController

- (id)initWithBookPath:(NSString *)path fileName:(NSString *)name webViewDelegate:(UIViewController<UIWebViewDelegate> *)delegate {
    
    self = [super init];
    if (self) {
        
        fileName = name;
        bookPath = path;
        webViewDelegate = delegate;
        
        disabled = NO;
        indexWidth = 0;
        indexHeight = 0;
        
        // ****** INIT PROPERTIES
        properties = [Properties properties];
        
        [self setPageSizeForOrientation:[self interfaceOrientation]];
    }
    return self;
}
- (void)dealloc
{
    [indexScrollView release];
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
    
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    if (sharedApplication.statusBarHidden) {
        pageY = 0;
    } else {
        pageY = -20;
    }
    
    NSLog(@"Set IndexView size to %dx%d, with pageY set to %d", pageWidth, pageHeight, pageY);
}

- (void)setActualSize {
    actualIndexWidth = MIN(indexWidth, pageWidth);
    actualIndexHeight = MIN(indexHeight, pageHeight);
}

- (BOOL)isIndexViewHidden {
    return [UIApplication sharedApplication].statusBarHidden;
}

- (BOOL)isDisabled {
    return disabled;
}

- (void)setIndexViewHidden:(BOOL)hidden withAnimation:(BOOL)animation {
    CGRect frame;
    if (hidden) {
        if ([self stickToLeft]) {
            frame = CGRectMake(-actualIndexWidth, pageHeight - actualIndexHeight, actualIndexWidth, actualIndexHeight);
        } else {
            frame = CGRectMake(0, pageHeight + pageY, actualIndexWidth, actualIndexHeight);
        }
    } else {
        if ([self stickToLeft]) {
            frame = CGRectMake(0, pageHeight - actualIndexHeight, actualIndexWidth, actualIndexHeight);
        } else {
            frame = CGRectMake(0, pageHeight + pageY - indexHeight, actualIndexWidth, actualIndexHeight);
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

- (void)loadContent {
    NSString* path = [self indexPath];
    
    [self assignProperties];
    
    NSLog(@"Path to index view is %@", path);
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        disabled = NO;
        [(UIWebView *)self.view loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    } else {
        NSLog(@"Could not find index view at that path");
        disabled = YES;
    }
}

- (void)assignProperties {
    UIWebView *webView = (UIWebView*) self.view;
    webView.mediaPlaybackRequiresUserAction = ![[properties get:@"-baker-media-autoplay", nil] boolValue];
    
    BOOL bounce = [[properties get:@"-baker-index-bounce", nil] boolValue];
    [self setBounceForWebView:webView bounces:bounce];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    id width = [properties get:@"-baker-index-width", nil];
    id height = [properties get:@"-baker-index-height", nil];
    
    if (width != [NSNull null]) {
        indexWidth = (int) [width integerValue];
    } else {
        indexWidth = [self sizeFromContentOf:webView].width;
    }
    if (height != [NSNull null]) {
        indexHeight = (int) [height integerValue];
    } else {
        indexHeight = [self sizeFromContentOf:webView].height;
    }
    
    cachedContentSize = indexScrollView.contentSize;
    // get correct contentsize
    if (cachedContentSize.width < indexWidth) {
        cachedContentSize = CGSizeMake(indexWidth, indexHeight);
    }
    [self setActualSize];
    
    NSLog(@"Set size for IndexView to %dx%d (constrained from %dx%d)", actualIndexWidth, actualIndexHeight, indexWidth, indexHeight);
    
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
    return [bookPath stringByAppendingPathComponent:fileName];
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
