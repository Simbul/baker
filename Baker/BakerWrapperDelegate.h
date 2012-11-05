//
//  BakerWrapperDelegate.h
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import <Foundation/Foundation.h>

@class BakerWrapper;
@protocol BakerWrapperDelegate <NSObject>

@required
- (void)wrapperViewController:(BakerWrapper *)wrapperViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers;
- (void)wrapperViewController:(BakerWrapper *)wrapperViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed;

@end
