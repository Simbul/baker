//
//  BKRShelfViewLayout.h
//  Baker
//
//  Created by Tobias Strebitzer on 10/11/14.
//
//

#import <UIKit/UIKit.h>

@interface BKRShelfViewLayout : UICollectionViewFlowLayout

@property (nonatomic, readonly) BOOL isSticky;
@property (nonatomic, readonly) BOOL isStretch;

- (id)initWithSticky:(BOOL)sticky stretch:(BOOL)stretch;

@end
