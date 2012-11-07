//
//  BakerScrollWrapper.m
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import "BakerScrollWrapper.h"

@implementation BakerScrollWrapper

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        
        // ****** SCROLLVIEW INIT
        
        _scrollView = [[[UIScrollView alloc] initWithFrame:frame] retain];
        
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.showsHorizontalScrollIndicator = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delaysContentTouches = NO;
        _scrollView.pagingEnabled = YES;
        
        [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        
        // ****** INIT PROPERTIES
        _properties = [Properties properties];
        
        // ****** BAKER SWIPES
        _scrollView.scrollEnabled = [[_properties get:@"-baker-page-turn-swipe", nil] boolValue];
    }
    return self;
}

- (void)loadView{
    //Set Scroll View to be Wrapper's View
    self.view = [_scrollView retain];
}

- (void)viewDidLoad{
    _scrollView.contentSize = CGSizeMake((self.view.frame.size.width * [self.dataSource presentationCountForWrapperViewController:self]), self.view.frame.size.height);
}

- (void)setViewControllers:(NSArray *)viewControllers direction:(BakerWrapperNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion{
    
    PageViewController *pageViewController = [[viewControllers objectAtIndex:0] retain];
  
    [_scrollView addSubview:pageViewController.view];

    [self addChildViewController:pageViewController];
    
    return;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

/*

#pragma mark - GESTURES

- (void)handleInterceptedTouch:(NSNotification *)notification {
    
    NSDictionary *userInfo = notification.userInfo;
    UITouch *touch = [userInfo objectForKey:@"touch"];
    
    if (touch.phase == UITouchPhaseBegan) {
        userIsScrolling = NO;
        //shouldPropagateInterceptedTouch = ([touch.view isDescendantOfView:scrollView]);
    } else if (touch.phase == UITouchPhaseMoved) {
        userIsScrolling = YES;
    }
    
    if (shouldPropagateInterceptedTouch) {
        if (userIsScrolling) {
            [self userDidScroll:touch];
        } else if (touch.phase == UITouchPhaseEnded) {
            [self userDidTap:touch];
        }
    }
}
- (void)userDidTap:(UITouch *)touch {
    /****************************************************************************************************
     * This function handles all the possible user navigation taps:
     * up, down, left, right and double-tap.
     
    
    
    CGPoint tapPoint = [touch locationInView:self.view];
    NSLog(@"• User tap at [%f, %f]", tapPoint.x, tapPoint.y);
    
    // Swipe or scroll the page.
    if (!currentPageIsLocked)
    {
        if (CGRectContainsPoint(upTapArea, tapPoint)) {
            NSLog(@"    Tap UP /\\!");
            [self scrollUpCurrentPage:([self getCurrentPageOffset] - pageHeight + 50) animating:YES];
        } else if (CGRectContainsPoint(downTapArea, tapPoint)) {
            NSLog(@"    Tap DOWN \\/");
            [self scrollDownCurrentPage:([self getCurrentPageOffset] + pageHeight - 50) animating:YES];
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
        }
        else if (touch.tapCount == 2) {
            NSLog(@"    Multi Tap TOGGLE STATUS BAR");
            [self toggleStatusBar];
        }
    }
}
- (void)userDidScroll:(UITouch *)touch {
    NSLog(@"• User scroll");
    [self hideStatusBar];
    
    //  currPage.backgroundColor = webViewBackground;
    // currPage.opaque = YES;
}

#pragma mark - PAGE SCROLLING
- (void)setCurrentPageHeight {
    
    /*  for (UIView *subview in currPage.subviews) {
     if ([subview isKindOfClass:[UIScrollView class]]) {
     CGSize size = ((UIScrollView *)subview).contentSize;
     NSLog(@"• Setting current page height from %d to %f", currentPageHeight, size.height);
     currentPageHeight = size.height;
     }
     }
}
- (int)getCurrentPageOffset {
    
    int currentPageOffset = [[currPage stringByEvaluatingJavaScriptFromString:@"window.scrollY;"] intValue];
    if (currentPageOffset < 0) return 0;
    
    int currentPageMaxScroll = currentPageHeight - pageHeight;
    if (currentPageOffset > currentPageMaxScroll) return currentPageMaxScroll;
    
    return currentPageOffset;
    return 0;
}
- (void)scrollUpCurrentPage:(int)targetOffset animating:(BOOL)animating {
    
    if ([self getCurrentPageOffset] > 0)
    {
        if (targetOffset < 0) targetOffset = 0;
        
        NSLog(@"• Scrolling page up to %d", targetOffset);
        [self scrollPage:currPage to:[NSString stringWithFormat:@"%d", targetOffset] animating:animating];
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
- (void)scrollDownCurrentPage:(int)targetOffset animating:(BOOL)animating {
    
    int currentPageMaxScroll = currentPageHeight - pageHeight;
    if ([self getCurrentPageOffset] < currentPageMaxScroll)
    {
        if (targetOffset > currentPageMaxScroll) targetOffset = currentPageMaxScroll;
        
        NSLog(@"• Scrolling page down to %d", targetOffset);
        [self scrollPage:currPage to:[NSString stringWithFormat:@"%d", targetOffset] animating:animating];
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
        
        NSString *offsetString = [currPage stringByEvaluatingJavaScriptFromString:jsAnchorHandler];
        if (![offsetString isEqualToString:@""])
        {
            int offset = [offsetString intValue];
            int currentPageOffset = [self getCurrentPageOffset];
            
            if (offset > currentPageOffset) {
                [self scrollDownCurrentPage:offset animating:animating];
            } else if (offset < currentPageOffset) {
                [self scrollUpCurrentPage:offset animating:animating];
            }
        }
        
        anchorFromURL = nil;
    }
}

- (CGRect)frameForPage:(int)page {
    return CGRectZero;// CGRectMake((USEPAGEVIEW)?0:(pageWidth * (page - 1)), 0, pageWidth, pageHeight);
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

- (void)updateBookLayout {
    NSLog(@"    Prevent page from changing until layout is updated");
    [self lockPage:[NSNumber numberWithBool:YES]];
    
    [self setPageSize:[self getCurrentInterfaceOrientation]];
    
    if ([renderingType isEqualToString:@"screenshots"]) {
        // TODO: BE SURE TO KNOW THE CORRECT CURRENT PAGE!
        [self removeScreenshots];
        [self updateScreenshots];
    }
    
    
    // HACK TO HANDLE STATUS BAR ON ROTATION, TODO: MOVE IT IN ITS OWN METHOD
    int scrollViewY = 0;
    if (![UIApplication sharedApplication].statusBarHidden) {
        scrollViewY = -20;
    }/*
      
      [UIView animateWithDuration:0.2
      animations:^{
      if (!USEPAGEVIEW){
      scrollView.frame = CGRectMake(0, scrollViewY, pageWidth, pageHeight);
      } else {
      pageView.view.frame = CGRectMake(0, scrollViewY, pageWidth, pageHeight);
      }
      }];
      
      
      [self setFrame:[self frameForPage:currentPageNumber] forPage:currPage];
      [self setFrame:[self frameForPage:currentPageNumber + 1] forPage:nextPage];
      [self setFrame:[self frameForPage:currentPageNumber - 1] forPage:prevPage];
      
      if (!USEPAGEVIEW){
      [scrollView scrollRectToVisible:[self frameForPage:currentPageNumber] animated:NO];
      } else {
      
      currentPageViewController  = [[[UIViewController alloc] init] retain];
      currentPageViewController.view = [[UIView alloc] init];
      currentPageViewController.view.bounds = self.pageView.view.bounds;
      currentPageViewController.view.backgroundColor = [Utils colorWithHexString:[properties get:@"-baker-background", nil]];
      
      NSDictionary *details = [pageDetails objectAtIndex:0];
      
      [currentPageViewController.view addSubview:[details objectForKey:@"background"]];
      [currentPageViewController.view addSubview:[details objectForKey:@"spinner"]];
      [currentPageViewController.view addSubview:[details objectForKey:@"number"]];
      [currentPageViewController.view addSubview:[details objectForKey:@"title"]];
      
      
      NSArray *viewControllers = @[currentPageViewController];
      
      [pageView setViewControllers:viewControllers
      direction:UIPageViewControllerNavigationDirectionForward
      animated:NO
      completion:nil];
      }
      NSLog(@"    Unlock page changing");
      [self lockPage:[NSNumber numberWithBool:NO]];
}
- (void)setPageSize:(NSString *)orientation {
    
    [self setTappableAreaSize];
    
    
    /* if (!USEPAGEVIEW){
     scrollView.contentSize = CGSizeMake(pageWidth * totalPages, pageHeight);
     }
}

- (void)setFrame:(CGRect)frame forPage:(UIWebView *)page {
    /* if (page && [page.superview isEqual:scrollView]) {
     page.frame = frame;
     [scrollView bringSubviewToFront:page];
     }
}
*/

@end
