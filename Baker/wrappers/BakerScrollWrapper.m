//
//  BakerScrollWrapper.m
//  Baker
//
//  Created by James Campbell on 04/11/2012.
//
//

#import "BakerScrollWrapper.h"

@implementation BakerScrollWrapper

@synthesize viewControllers = _viewControllers;

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        
        // ****** SCROLLVIEW INIT
        
        _scrollView = [[[UIScrollView alloc] initWithFrame:frame] retain];
        
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.delegate = self;
        _scrollView.showsHorizontalScrollIndicator = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delaysContentTouches = NO;
        _scrollView.pagingEnabled = YES;
        
        [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        
        // ****** INIT PROPERTIES
        _properties = [Properties properties];
        
        // ****** BAKER SWIPES
        _scrollView.scrollEnabled = [[_properties get:@"-baker-page-turn-swipe", nil] boolValue];
    }
    return self;
}

- (void)loadView{
    //Set Scroll View to be Wrapper's View
    self.view = [_scrollView retain];
}

- (void)viewDidLoad{
    _scrollView.contentSize = CGSizeMake((self.view.frame.size.width * ([self.dataSource presentationCountForWrapperViewController:self] - 1)), self.view.frame.size.height);
}

- (void)setViewControllers:(NSArray *)viewControllers direction:(BakerWrapperNavigationDirection)direction animated:(BOOL)animated completion:(void (^)(BOOL finished))completion{
    
    [super setViewControllers:viewControllers direction:direction animated:animated completion:completion];
    
    PageViewController *newPageViewController = [viewControllers objectAtIndex:0];
    
    newPageViewController.view.frame = [self frameForPage:newPageViewController.tag];
    
    if (_currentPage){
        
        _currentPage = [newPageViewController retain];
        
        [_scrollView addSubview:_currentPage.view];
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")){
            [self addChildViewController:_currentPage];
        }
        
    } else {
         [_scrollView scrollRectToVisible:newPageViewController.view.frame animated:animated];
    }
    
    completion(YES);
    
    return;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    [self updatePages];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)updatePages{
    
    if (!_pageViewInBeforeTransition) {
        
        id newPage = [self.dataSource wrapperViewController:self viewControllerBeforeViewController:_currentPage];
        
        if (newPage){
            _pageViewInBeforeTransition = [newPage retain];
            _pageViewInBeforeTransition.view.frame = [self frameForPage:_pageViewInBeforeTransition.tag];
            [_scrollView addSubview:_pageViewInBeforeTransition.view];
        }
    }
    
    if (!_pageViewInAfterTransition) {
        
        id newPage = [self.dataSource wrapperViewController:self viewControllerAfterViewController:_currentPage];
        
        if (newPage){
            _pageViewInAfterTransition = [newPage retain];
            _pageViewInAfterTransition.view.frame = [self frameForPage:_pageViewInAfterTransition.tag];
            [_scrollView addSubview:_pageViewInAfterTransition.view];
        }
    }
    
    id newPage = nil;
    
    if (_pageViewInBeforeTransition && _pageViewInBeforeTransition.view.frame.origin.x == _scrollView.contentOffset.x){
        newPage = _pageViewInBeforeTransition;
    }
    
    if (_pageViewInAfterTransition && _pageViewInAfterTransition.view.frame.origin.x == _scrollView.contentOffset.x){
        newPage = _pageViewInAfterTransition;
    }
    
    if (newPage){
        NSArray *oldViewControllers = [self.viewControllers copy];
        
        if (_currentPage){
             if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")){
                 [_currentPage removeFromParentViewController];
             }
            [_currentPage.view removeFromSuperview];
            [_currentPage release];
            _currentPage = nil;
        }
        
        _viewControllers = [@[[newPage retain]] retain];
        _currentPage = [newPage retain];
        
        _currentPage.view.frame = [self frameForPage:_currentPage.tag];
        [_scrollView addSubview:_currentPage.view];
        
        [self addChildViewController:_currentPage];
        
        [self.delegate wrapperViewController:self didFinishAnimating:YES previousViewControllers:[oldViewControllers autorelease] transitionCompleted:YES];
        
        if (_pageViewInBeforeTransition){
            [_pageViewInBeforeTransition release];
            _pageViewInBeforeTransition = nil;
        }
        
        if (_pageViewInAfterTransition){
            [_pageViewInAfterTransition release];
            _pageViewInAfterTransition = nil;
        }
        
        NSLog(@"Showing Page %i", _currentPage .tag);
    }
}

- (CGRect)frameForPage:(int)page {
    return CGRectMake(self.view.frame.size.width * (page - 1), 0, self.view.frame.size.width, self.view.frame.size.height);
}

@end
