//
//  BakerScrollWrapper.h
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import <UIKit/UIKit.h>

#import "BakerWrapper.h"
#import "Properties.h"

@interface BakerScrollWrapper : BakerWrapper{
    
    int tapNumber;
    int stackedScrollingAnimations;
    
    BOOL currentPageFirstLoading;
    BOOL currentPageIsDelayingLoading;
    BOOL currentPageHasChanged;
    BOOL currentPageIsLocked;
    BOOL userIsScrolling;
    BOOL shouldPropagateInterceptedTouch;
    
    CGRect upTapArea;
    CGRect downTapArea;
    CGRect leftTapArea;
    CGRect rightTapArea;
    
    UIScrollView *_scrollView;
    
    Properties *_properties;
}

#pragma mark - SCROLLVIEW
- (CGRect)frameForPage:(int)page;
- (void)updateBookLayout;

@end
