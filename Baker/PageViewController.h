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

- (id)initWithFrame:(CGRect)frame;
- (void)loadPage:(NSString*)pageURL;
- (void)updatePageInfomation;

@end
