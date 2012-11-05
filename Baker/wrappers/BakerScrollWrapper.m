//
//  BakerScrollWrapper.m
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import "BakerScrollWrapper.h"

@implementation BakerScrollWrapper

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        
        //Create a Scroll View
        _scrollView = [[[UIScrollView alloc] initWithFrame:frame] retain];
        
        //Set Scroll View to be Wrapper's View
        self.view = _scrollView;
    }
    return self;
}

@end
