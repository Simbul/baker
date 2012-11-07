//
//  BakerWrapper.h
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import <UIKit/UIKit.h>
#import "BakerWrapperDataSource.h"
#import "BakerWrapperDelegate.h"

enum {
    BakerWrapperNavigationDirectionHorizontal,
    BakerWrapperNavigationDirectionVertical
} typedef  BakerWrapperNavigationDirection;

@interface BakerWrapper : UIViewController{
    PageViewController *_pageViewInBeforeTransition;
    PageViewController *_pageViewInAfterTransition;
}

@property(nonatomic, assign) id<BakerWrapperDataSource> dataSource;
@property(nonatomic, assign) id<BakerWrapperDelegate> delegate;
@property(nonatomic, assign) BakerWrapperNavigationDirection direction;
@property(retain, readonly) NSArray *viewControllers;

- (id)initWithFrame:(CGRect)frame;
- (void)setViewControllers:(NSArray *)viewControllers direction:(BakerWrapperNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end
