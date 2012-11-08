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

//TODO: Generic Method that sub classes can use to reuse views when they have only moved one page along, or perhaps this is redundant if we introduce a hybrid mode or just use three-cards (i.e threecards with screenshots)

enum {
    BakerWrapperNavigationDirectionForward,
    BakerWrapperNavigationDirectionBackward
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
