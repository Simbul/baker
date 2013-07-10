//
//  JSResponseHandler.m
//  Baker
//
//  Created by Arthur Sakharov on 7/10/13.
//
//

#import "JSResponseHandler.h"

@implementation JSResponseHandler

- (BOOL)parseJSResponce : (NSString*) response
{
//    responce from
//    function ObjCAlert() {
//        document.location = "laResponse:event:event_from_JS";
//    };
    NSArray *components = [response componentsSeparatedByString:@":"];
    if (components.count) {
        if ([[components objectAtIndex:0] isEqualToString:@"laResponse"]) {
            if ([[components objectAtIndex:1] isEqualToString:@"event"]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Objective-C Alert"
                                                                message:[components objectAtIndex:2]
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            
            [self.delegate jsResponseEvent:self];
            return NO;
        }
    }
    
    return YES;
}

@end
