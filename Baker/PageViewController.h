//
//  PageViewController.h
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import <UIKit/UIKit.h>
#import "BakerDefines.h"
#import "PageTitleLabel.h"
#import "Properties.h"
#import "Utils.h"

@interface PageViewController : UIViewController{
    NSNumber *_pageNumberAlpha;
    UIColor *_pageNumberColor;
    
    NSString *_pageURL;
    
    Properties *_properties;
}

@property (strong, retain)UIImageView *backgroundImageView;
@property (strong, retain)UIActivityIndicatorView *activityIndicatorView;
@property (strong, retain)UILabel *numberLabel;
@property (strong, retain)PageTitleLabel *titleLabel;
@property (strong, retain)UIWebView *webView;
@property (readwrite, atomic)int tag;

- (id)initWithFrame:(CGRect)frame;
- (void)loadPage:(NSString*)pageURL;
- (void)updatePageInfomation;

@end
