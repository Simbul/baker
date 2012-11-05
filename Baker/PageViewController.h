//
//  PageViewController.h
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#import <UIKit/UIKit.h>
#import "PageTitleLabel.h"
#import "Properties.h"
#import "Utils.h"

@interface PageViewController : UIViewController{
    NSNumber *pageNumberAlpha;
    UIColor *pageNumberColor;
    
    Properties *properties;
}

@property (strong, retain)UIImageView *backgroundImageView;
@property (strong, retain)UIActivityIndicatorView *activityIndicatorView;
@property (strong, retain)UILabel *numberLabel;
@property (strong, retain)PageTitleLabel *titleLabel;

@end
