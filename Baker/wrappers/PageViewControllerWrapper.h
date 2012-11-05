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

@interface PageViewControllerWrapper : BakerWrapper{
    UIPageViewController *_pageViewController;
}

@end
