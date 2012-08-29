//
//  PageTitleLabel.m
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2010-2011, Davide Casali, Marco Colombo, Alessandro Morandi
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

#import "PageTitleLabel.h"
#import "Utils.h"
#import "GTMNSString+HTML.h"

@implementation PageTitleLabel

- (id)initWithFile:(NSString *)path {
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error == nil) {
        return [self initWithFileContent:fileContent];
    } else {
        NSLog(@"Error while loading %@ : %@ : Check that encoding is UTF8 for the file.", path, [error localizedDescription]);
        return [super init];
    }
}

- (id)initWithFileContent:(NSString *)fileContent {
    properties = [Properties properties];
    
    NSRegularExpression *titleRegex = [NSRegularExpression regularExpressionWithPattern:@"<title>(.*)</title>" options:NSRegularExpressionCaseInsensitive error:NULL];
    NSRange matchRange = [[titleRegex firstMatchInString:fileContent options:0 range:NSMakeRange(0, [fileContent length])] rangeAtIndex:1];
    if (!NSEqualRanges(matchRange, NSMakeRange(NSNotFound, 0))) {
        NSString *titleText = [[fileContent substringWithRange:matchRange] gtm_stringByUnescapingFromHTML];
        
        CGSize titleDimension = CGSizeMake(672, 330);
        UIFont *titleFont = [UIFont fontWithName:@"Helvetica" size:24.0];
        
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        if (screenBounds.size.width < 768) {
            titleDimension = CGSizeMake(280, 134);
            titleFont = [UIFont fontWithName:@"Helvetica" size:15.0];
        }
        
        CGSize titleTextSize = [titleText sizeWithFont:titleFont constrainedToSize:titleDimension lineBreakMode:UILineBreakModeTailTruncation];
        CGRect titleFrame = CGRectMake(0, 0, titleTextSize.width, titleTextSize.height);
        
        id ret = [super initWithFrame:titleFrame];
        
        [self initStyle];
        self.font = titleFont;
        self.text = titleText;
        
        return ret;
    } else {
        return [super init];
    }
}

- (void)initStyle {
    self.backgroundColor = [UIColor clearColor];
    id alpha = [properties get:@"-baker-page-numbers-alpha", nil];
    self.alpha = [(NSNumber*) alpha floatValue];
    self.textColor = [Utils colorWithHexString:[properties get:@"-baker-page-numbers-color", nil]];
    self.textAlignment = UITextAlignmentCenter;
    self.lineBreakMode = UILineBreakModeTailTruncation;
    self.numberOfLines = 0;
}

- (void)setX:(CGFloat)x Y:(CGFloat)y {
    CGRect titleFrame = self.frame;
    titleFrame.origin.x = x;
    titleFrame.origin.y = y;
    self.frame = titleFrame;
}

@end
