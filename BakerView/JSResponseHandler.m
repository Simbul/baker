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
            if ([[components objectAtIndex:2] isEqualToString:@"css_updated"])
            {
                [self.delegate styleSheetUpdated:self inPage:pagePos];
            }
            if ([[components objectAtIndex:2] isEqualToString:@"page_loaded"])
            {
                [self.delegate pageFinishedLoading:self inPage:pagePos];
            }
            return YES;
        }
    }
    
    return NO;
}

@end
