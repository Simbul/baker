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
        
        // ****** SCROLLVIEW INIT
        
        _scrollView = [[[UIScrollView alloc] initWithFrame:frame] retain];
        
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.showsHorizontalScrollIndicator = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delaysContentTouches = NO;
        _scrollView.pagingEnabled = YES;
        
        // ****** INIT PROPERTIES
        _properties = [Properties properties];
        
        // ****** BAKER SWIPES
        _scrollView.scrollEnabled = [[_properties get:@"-baker-page-turn-swipe", nil] boolValue];
        
        //Set Scroll View to be Wrapper's View
        self.view = _scrollView;
    }
    return self;
}

@end
