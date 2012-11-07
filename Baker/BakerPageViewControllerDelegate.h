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

- (bool)pageViewController:(PageViewController*)pageViewController handleURL:(NSString*)url;
- (void)pageViewControllerDidLoadPage:(PageViewController*)pageViewController;

@end
