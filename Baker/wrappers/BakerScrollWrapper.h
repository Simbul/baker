//
//  BakerScrollWrapper.h
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import <UIKit/UIKit.h>

#import "BakerWrapper.h"
#import "Properties.h"

@interface BakerScrollWrapper : BakerWrapper{
    UIScrollView *_scrollView;
    
    Properties *_properties;
}

@end
