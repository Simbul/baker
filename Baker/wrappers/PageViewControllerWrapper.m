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
        
        //Create a Page View Controller
        _pageViewController = [[[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil] retain];
        
        //Set Page View Controller's View to be Wrapper's View
        self.view = _pageViewController.view;
    }
    return self;
}

@end
