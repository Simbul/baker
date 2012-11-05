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

@interface BakerWrapper : UIViewController

@property(nonatomic, assign) id<BakerWrapperDataSource> dataSource;
@property(nonatomic, assign) id<BakerWrapperDelegate> delegate;

@end
