//
//  NSObject+Extensions.m
//  Baker
//
//  Created by Pieter Claerhout on 03/11/14.
//
//

#import "NSObject+Extensions.h"

@implementation NSObject (Extensions)

- (NSString*)cachePath {
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
}

@end
