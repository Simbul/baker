
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

- (id)initWithPageSize:(CGSize)size
{
    self = [super init];
    if (self) {
        //Setup View for Page
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0,0,size.width, size.height)];
        
        // ****** INIT PROPERTIES
        properties = [Properties properties];
        
        //Get Page Number Alpha
        pageNumberAlpha = [properties get:@"-baker-page-numbers-alpha", nil];
        
        //Get Page Number Color
        pageNumberColor = [Utils colorWithHexString:[properties get:@"-baker-page-numbers-color", nil]];
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // ****** Background Image
    _backgroundImageView = [[[UIImageView alloc] initWithFrame:self.view.frame] autorelease];
         
    // ****** Activity Indicator
    _activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    _activityIndicatorView.backgroundColor = [UIColor clearColor];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5.0")) {
            _activityIndicatorView.color = pageNumberColor;
            _activityIndicatorView.alpha = [pageNumberAlpha floatValue];
    };
    
    CGSize pageSize = self.view.frame.size;
    CGRect frame = _activityIndicatorView.frame;
    
    frame.origin.x = (pageSize.width - frame.size.width) / 2;
    frame.origin.y = (pageSize.height - frame.size.height) / 2;
    _activityIndicatorView.frame = frame;
        
    [_activityIndicatorView startAnimating];
            
    // ****** Numbers
    _numberLabel = [[[UILabel alloc] initWithFrame:CGRectMake((pageSize.width - 115) / 2, pageSize.height / 2 - 55, 115, 30)] autorelease];
    _numberLabel.backgroundColor = [UIColor clearColor];
    _numberLabel.font = [UIFont fontWithName:@"Helvetica" size:40.0];
    _numberLabel.textColor = pageNumberColor;
    _numberLabel.textAlignment = UITextAlignmentCenter;
    _numberLabel.alpha = [pageNumberAlpha floatValue];

    // ****** Title
    /*PageTitleLabel *title = [[[PageTitleLabel alloc]initWithFile:[pages objectAtIndex: i]] autorelease];
    [title setX:((pageWidth * (x*i)) + ((pageWidth - title.frame.size.width) / 2)) Y:(pageHeight / 2 + 20)];*/

}

@end
