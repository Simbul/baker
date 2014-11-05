//
//  UIColor+Extensions.h
//  Pirelli
//
//  Created by Marco Colombo on 27/09/11.
//  Copyright 2011 Marco Natale Colombo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (BakerExtensions)

#pragma mark - Hex color management

+ (UIColor*)bkrColorWithRGBHex:(UInt32)hex;
+ (UIColor*)bkrColorWithHexString:(NSString*)stringToConvert;

@end
