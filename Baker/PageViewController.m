
//
//  PageViewController.m
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import "PageViewController.h"

@interface PageViewController ()

@end

@implementation PageViewController

- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        //Setup View for Page
        self.view = [[UIView alloc] initWithFrame:frame];
        
        // ****** INIT PROPERTIES
        _properties = [Properties properties];
        
        //Get Page Number Alpha
        _pageNumberAlpha = [_properties get:@"-baker-page-numbers-alpha", nil];
        
        //Get Page Number Color
        _pageNumberColor = [Utils colorWithHexString:[_properties get:@"-baker-page-numbers-color", nil]];
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // ****** Background Image
    _backgroundImageView = [[[UIImageView alloc] initWithFrame:self.view.frame] autorelease];
    [self.view addSubview:_backgroundImageView];
    
    // ****** Activity Indicator
    _activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    _activityIndicatorView.backgroundColor = [UIColor clearColor];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
            _activityIndicatorView.color = _pageNumberColor;
            _activityIndicatorView.alpha = [_pageNumberAlpha floatValue];
    };
    
    CGSize pageSize = self.view.frame.size;
    CGRect frame = _activityIndicatorView.frame;
    
    frame.origin.x = (pageSize.width - frame.size.width) / 2;
    frame.origin.y = (pageSize.height - frame.size.height) / 2;
    _activityIndicatorView.frame = frame;
        
    [_activityIndicatorView startAnimating];
    [self.view addSubview:_activityIndicatorView];
            
    // ****** Numbers
    _numberLabel = [[[UILabel alloc] initWithFrame:CGRectMake((pageSize.width - 115) / 2, pageSize.height / 2 - 55, 115, 30)] autorelease];
    _numberLabel.backgroundColor = [UIColor clearColor];
    _numberLabel.font = [UIFont fontWithName:@"Helvetica" size:40.0];
    _numberLabel.text = @"0";
    _numberLabel.textColor = _pageNumberColor;
    _numberLabel.textAlignment = UITextAlignmentCenter;
    _numberLabel.alpha = [_pageNumberAlpha floatValue];
    
    [self.view addSubview:_numberLabel];
}

- (void)viewWillAppear:(BOOL)animated{
    
    //Make Sure Number Label is updated to show relevant page number
    _numberLabel.text = [NSString stringWithFormat:@"%d", self.tag];
    
}

- (void)loadPage:(NSString*)pageURL{
    
    // ****** Title
    
    //Remove and Release Exsisting Title Label if it exsists already
    if (_titleLabel){
        [_titleLabel removeFromSuperview];
        [_titleLabel release];
        _titleLabel = nil;
    }
    
    CGSize pageSize = self.view.frame.size;
    
    _titleLabel = [[[PageTitleLabel alloc]initWithFile:pageURL] autorelease];
    [_titleLabel setX:((pageSize.width - _titleLabel.frame.size.width) / 2) Y:(pageSize.height / 2 + 20)];
    [self.view addSubview:_titleLabel];
    
    // ****** Webview
    
    //Remove and Release Exsisting Web View if it exsists already
    if (_webView){
        [_webView removeFromSuperview];
        [_webView release];
        _webView = nil;
    }
    
    _webView = [[[UIWebView alloc] initWithFrame:self.view.frame] autorelease];
    _webView.hidden = YES;
}

- (void)setTag:(int)tag{
    self.view.tag = tag;
}

- (int)tag{
    return self.view.tag;
}

@end
