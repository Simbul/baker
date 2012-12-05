//
//  BakerPageViewControllerDelegate.h
//  Baker
//
//  Created by James Campbell on 07/11/2012.
//
//

#import <Foundation/Foundation.h>

@class PageViewController;
@protocol BakerPageViewControllerDelegate <NSObject>
- (bool)pageViewController:(PageViewController*)pageViewController shouldStartPageLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
- (void)pageViewControllerWillLoadPage:(PageViewController*)pageViewController;
- (void)pageViewControllerDidLoadPage:(PageViewController*)pageViewController;
- (void)pageViewControllerWillUnloadPage:(PageViewController*)pageViewController;

@end
