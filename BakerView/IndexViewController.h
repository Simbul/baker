//
//  IndexViewController.h
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this list of
//  conditions and the following disclaimer.
//  Redistributions in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or other materials
//  provided with the distribution.
//  Neither the name of the Baker Framework nor the names of its contributors may be used to
//  endorse or promote products derived from this software without specific prior written
//  permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
//  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
//  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <UIKit/UIKit.h>
#import "BakerBook.h"

@interface IndexViewController : UIViewController <UIWebViewDelegate> {

    NSString *fileName;
    UIScrollView *indexScrollView;
    UIViewController <UIWebViewDelegate> *webViewDelegate;

    int pageY;
    int pageWidth;
    int pageHeight;
    int indexWidth;
    int indexHeight;
    int actualIndexWidth;
    int actualIndexHeight;

    BOOL disabled;
    BOOL loadedFromBundle;

    CGSize cachedContentSize;
}

@property (strong, nonatomic) BakerBook *book;

- (id)initWithBook:(BakerBook *)bakerBook fileName:(NSString *)name webViewDelegate:(UIViewController *)delegate;
- (void)loadContent;
- (void)setBounceForWebView:(UIWebView *)webView bounces:(BOOL)bounces;
- (void)setPageSizeForOrientation:(UIInterfaceOrientation)orientation;
- (BOOL)isIndexViewHidden;
- (BOOL)isDisabled;
- (void)setIndexViewHidden:(BOOL)hidden withAnimation:(BOOL)animation;
- (void)willRotate;
- (void)rotateFromOrientation:(UIInterfaceOrientation)fromInterfaceOrientation toOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
- (void)fadeOut;
- (void)fadeIn;
- (BOOL)stickToLeft;
- (CGSize)sizeFromContentOf:(UIView *)view;
- (void)setActualSize;
- (void)adjustIndexView;
- (void)setViewFrame:(CGRect)frame;
- (NSString *)indexPath;

@end
