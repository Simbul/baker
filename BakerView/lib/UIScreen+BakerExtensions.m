//
//  NSString+Extensions.h
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2014, Pieter Claerhout
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

#import "UIScreen+BakerExtensions.h"

@implementation UIScreen (BakerExtensions)

- (CGFloat)bkrScreenWidthPortrait {
    CGFloat screenSize1 = self.bounds.size.width;
    CGFloat screenSize2 = self.bounds.size.height;
    return MIN(screenSize1, screenSize2);
}

- (CGFloat)bkrScreenHeightPortrait {
    CGFloat screenSize1 = self.bounds.size.width;
    CGFloat screenSize2 = self.bounds.size.height;
    return MAX(screenSize1, screenSize2);
}

- (CGFloat)bkrScreenWidth {
    return self.bounds.size.width;
}

- (CGFloat)bkrScreenHeight {
    return self.bounds.size.height;
}

- (NSString*)bkrLayoutName {
    CGFloat screenWidth  = [self bkrScreenWidthPortrait];
    CGFloat screenHeight = [self bkrScreenHeightPortrait];
    if (screenWidth == 320 && screenHeight == 480) {
        screenHeight = 568; // Special case for iPhone 4s
    }
    return [NSString stringWithFormat:@"%.0fx%.0f", screenHeight, screenWidth];
}

- (CGFloat)bkrWidthForOrientationName:(NSString*)orientationName {
    if ([orientationName isEqualToString:@"portrait"]) {
        return [self bkrScreenWidthPortrait];
    } else {
        return [self bkrScreenHeightPortrait];
    }
}

- (CGFloat)bkrHeightForOrientationName:(NSString*)orientationName {
    if ([orientationName isEqualToString:@"portrait"]) {
        return [self bkrScreenHeightPortrait];
    } else {
        return [self bkrScreenWidthPortrait];
    }
}

- (CGFloat)bkrWidthForOrientation:(UIInterfaceOrientation)orientation {
    NSString *orientationName = UIInterfaceOrientationIsPortrait(orientation) ? @"portrait" : @"landscape";
    return [self bkrWidthForOrientationName:orientationName];
}

- (CGFloat)bkrHeightForOrientation:(UIInterfaceOrientation)orientation {
    NSString *orientationName = UIInterfaceOrientationIsPortrait(orientation) ? @"portrait" : @"landscape";
    return [self bkrHeightForOrientationName:orientationName];
}

@end
