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

@interface PageViewController : UIViewController<UIWebViewDelegate>{
    NSNumber *_pageNumberAlpha;
    UIColor *_pageNumberColor;
    
    UIImageView *_backgroundImageView;
    UIActivityIndicatorView *_activityIndicatorView;
    UILabel *_numberLabel;
    PageTitleLabel *_titleLabel;
    UIWebView *_webView;
    
    NSString *_pageURL;
    
    Properties *_properties;
}


@property (readwrite, atomic)int tag;
@property (nonatomic, assign)id<UIWebViewDelegate> *delegate;
@property (strong, retain, atomic)UIImage *backgroundImagePortrait;
@property (strong, retain, atomic)UIImage *backgroundImageLandscape;

- (id)initWithFrame:(CGRect)frame andPageURL:(NSString*)pageURL;
- (void)loadPage:(NSString*)pageURL;
- (void)updateLayout;
- (void)updateBackgroundImageToOrientation:(UIInterfaceOrientation)orientation;
- (void)updatePageInfomation;

@end
