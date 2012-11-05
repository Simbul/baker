//
//  PageViewControllerWrapper.m
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import "PageViewControllerWrapper.h"

@interface PageViewControllerWrapper ()

@end

@implementation PageViewControllerWrapper

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        
        // ***** PAGEVIEWCONTROLLER INIT
        
        _pageViewController = [[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil] retain];
        
        //Set Page View Controller's View to be Wrapper's View
        self.view = _pageViewController.view;
        
        //Attach Gestures to View to enable page turning
        self.view.gestureRecognizers = _pageViewController.gestureRecognizers;
    }
    return self;
}

@end
