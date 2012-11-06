//
//  BakerWrapperDataSource.h
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PageViewController.h"

@class BakerWrapper;
@protocol BakerWrapperDataSource <NSObject>

@required

- (PageViewController *)wrapperViewController:(BakerWrapper *)wrapperViewController viewControllerBeforeViewController:(PageViewController *)viewController;
- (PageViewController *)wrapperViewController:(BakerWrapper *)wrapperViewController viewControllerAfterViewController:(PageViewController *)viewController;
- (NSInteger)presentationCountForWrapperViewController:(BakerWrapper *)wrapperViewController;
- (NSInteger)presentationIndexForWrapperViewController:(BakerWrapper *)wrapperViewController;

@end
