//
//  NSObject+Extensions.m
//  Baker
//
//  Created by Pieter Claerhout on 03/11/14.
//
//

#import "NSObject+BakerExtensions.h"

@implementation NSObject (BakerExtensions)

- (NSString*)bkrCachePath {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
}

@end
