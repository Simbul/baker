//
//  Utils.m
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

#define ISPAGED_JS_SNIPPET @"\
    var elem = document.getElementsByName('paged')[0];\
    if (elem) {\
        elem.getAttribute('content');\
    }"

#import "Utils.h"
#import <sys/xattr.h>

@implementation Utils

+ (UIColor *)colorWithRGBHex:(UInt32)hex {
	int r = (hex >> 16) & 0xFF;
	int g = (hex >> 8) & 0xFF;
	int b = (hex) & 0xFF;

	return [UIColor colorWithRed:r / 255.0f
						   green:g / 255.0f
							blue:b / 255.0f
						   alpha:1.0f];
}
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert {
    // Returns a UIColor by scanning the string for a hex number and passing that to (UIColor *)colorWithRGBHex:(UInt32)hex
    // Skips any leading whitespace and ignores any trailing characters

    NSString *hexString = [stringToConvert stringByReplacingOccurrencesOfString:@"#" withString:@""];
	NSScanner *scanner = [NSScanner scannerWithString:hexString];

    unsigned hexNum;
	if (![scanner scanHexInt:&hexNum]) {
        return nil;
    }
	return [Utils colorWithRGBHex:hexNum];
}
+ (NSString *)stringFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
		case UIInterfaceOrientationPortrait:           return @"UIInterfaceOrientationPortrait";
		case UIInterfaceOrientationPortraitUpsideDown: return @"UIInterfaceOrientationPortraitUpsideDown";
		case UIInterfaceOrientationLandscapeLeft:      return @"UIInterfaceOrientationLandscapeLeft";
		case UIInterfaceOrientationLandscapeRight:     return @"UIInterfaceOrientationLandscapeRight";
	}
	return nil;
}
+ (BOOL)webViewShouldBePaged:(UIWebView*)webView forBook:(BakerBook *)book {
    BOOL shouldBePaged = NO;

    NSString *pagePagination = [webView stringByEvaluatingJavaScriptFromString:ISPAGED_JS_SNIPPET];
    if ([pagePagination length] > 0) {
        shouldBePaged = [pagePagination boolValue];
    } else {
        shouldBePaged = [book.bakerVerticalPagination boolValue];
    }
    //NSLog(@"[Utils] Current page Pagination Mode status = %d", shouldBePaged);

    return shouldBePaged;
}
+ (NSString *)appID {
    return [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSDate *)dateWithFormattedString:(NSString *)string {
    static NSDateFormatter *dateFormat = nil;
    if (dateFormat == nil) {
        dateFormat = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease];
        [dateFormat setLocale:enUSPOSIXLocale];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormat setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return [dateFormat dateFromString:string];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:buttonTitle
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

+ (void)webView:(UIWebView *)webView dispatchHTMLEvent:(NSString *)event {
    [Utils webView:webView dispatchHTMLEvent:event withParams:[NSDictionary dictionary]];
}
+ (void)webView:(UIWebView *)webView dispatchHTMLEvent:(NSString *)event withParams:(NSDictionary *)params {
    __block NSMutableString *jsDispatchEvent = [NSMutableString stringWithFormat:
                                                @"var bakerDispatchedEvent = document.createEvent('Events');\
                                                bakerDispatchedEvent.initEvent('%@', false, false);", event];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *jsParamSet = [NSString stringWithFormat:@"bakerDispatchedEvent.%@='%@';\n", key, obj];
        [jsDispatchEvent appendString:jsParamSet];
    }];
    [jsDispatchEvent appendString:@"window.dispatchEvent(bakerDispatchedEvent);"];

    [webView stringByEvaluatingJavaScriptFromString:jsDispatchEvent];
}

@end
