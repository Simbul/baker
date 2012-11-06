//
//  BakerWrapper.m
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import "BakerWrapper.h"
#import "PageViewController.h"
@interface BakerWrapper ()

@end

@implementation BakerWrapper

- (id)initWithFrame:(CGRect)frame{
    return [super init];
}

- (void)setViewControllers:(NSArray *)viewControllers direction:(BakerWrapperNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion{
    
    _direction = direction;
    _viewControllers = viewControllers;
    
    PageViewController *pageViewController = [viewControllers objectAtIndex:0];
   
    NSLog(@"%@",  NSStringFromCGRect(pageViewController.view.frame));
    [pageViewController.webView setHidden:NO];
    [self.view addSubview:pageViewController.view];
    
    return;
}

@end
