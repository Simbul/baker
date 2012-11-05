//
//  BakerWrapperDataSource.h
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BakerWrapper;
@protocol BakerWrapperDataSource <NSObject>

@required

- (UIViewController *)wrapperViewController:(BakerWrapper *)wrapperViewController viewControllerBeforeViewController:(UIViewController *)viewController;
- (UIViewController *)wrapperViewController:(BakerWrapper *)wrapperViewController viewControllerAfterViewController:(UIViewController *)viewController;
- (NSInteger)presentationCountForWrapperViewController:(BakerWrapper *)wrapperViewController;
- (NSInteger)presentationIndexForWrapperViewController:(BakerWrapper *)wrapperViewController;

@end
