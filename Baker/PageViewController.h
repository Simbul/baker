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
    
    NSString *_pageURL;
    
    Properties *_properties;
}

@property (strong, retain, atomic)UIImageView *backgroundImageView;
@property (strong, retain, atomic)UIActivityIndicatorView *activityIndicatorView;
@property (strong, retain, atomic)UILabel *numberLabel;
@property (strong, retain, atomic)PageTitleLabel *titleLabel;
@property (strong, retain, atomic)UIWebView *webView;
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
