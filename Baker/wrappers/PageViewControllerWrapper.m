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
        _pageViewController.dataSource = self;
        _pageViewController.delegate = self;
        
        self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
    }
    return self;
}

- (void)viewDidLoad{
    //Setup Page View Controller
    [self.view addSubview: _pageViewController.view];
    [self addChildViewController:_pageViewController];
    [_pageViewController isMovingToParentViewController];
}

- (void)setViewControllers:(NSArray *)viewControllers direction:(BakerWrapperNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL))completion{
    [_pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished) {
        NSLog(@"Page View Controller Setup");
    }];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
    
    if (!_PageViewInTransition){
        _PageViewInTransition = [[self.dataSource wrapperViewController:self viewControllerBeforeViewController:(PageViewController*)viewController] retain];
    }
    
    return _PageViewInTransition;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{

    
    if (!_PageViewInTransition){
        _PageViewInTransition = [[self.dataSource wrapperViewController:self viewControllerAfterViewController:(PageViewController*)viewController] retain];
    }
    
    return [self.dataSource wrapperViewController:self viewControllerAfterViewController:(PageViewController*)viewController];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed{
    
    if (completed){
        [_PageViewInTransition release];
    }
}

@end
