//
//  JSResponseHandler.m
//  Baker
//
//  Created by Arthur Sakharov on 7/10/13.
//
//

#import "JSResponseHandler.h"

@implementation JSResponseHandler

- (BOOL)parseJSResponse : (NSString*) response
                forPage : (PageRelPos)pagePos
{
//    response from
//        document.location = "laresponse:event:event_from_js";
    NSArray *components = [response componentsSeparatedByString:@":"];
    if (components.count) {
        if ([[components objectAtIndex:0] isEqualToString:@"laresponse"]) {
            [self.delegate jsResponseEvent:self inPage:pagePos];
            return YES;
        }
    }
    
    return NO;
}

@end
