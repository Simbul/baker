//
//  PageViewControllerWrapper.h
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import <UIKit/UIKit.h>

#import "BakerWrapper.h"
#import "BakerWrapperDataSource.h"
#import "BakerWrapperDelegate.h"
#import "PageViewController.h"

@interface PageViewControllerWrapper : BakerWrapper<UIPageViewControllerDataSource, UIPageViewControllerDelegate>{
    UIPageViewController *_pageViewController;
    PageViewController *_PageViewInTransition;
    
    UIColor *webViewBackground;
}

@end
