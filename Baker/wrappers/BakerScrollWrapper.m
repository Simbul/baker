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
        
        // ****** INIT PROPERTIES
        _properties = [Properties properties];
        
        // ****** BAKER SWIPES
        _scrollView.scrollEnabled = [[_properties get:@"-baker-page-turn-swipe", nil] boolValue];
        
        //Set Scroll View to be Wrapper's View
        self.view = _scrollView;
    }
    return self;
}

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
     */
    
    
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
     }*/
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

@end
