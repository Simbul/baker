//
//  JSResponseHandler.h
//  Baker
//
//  Created by Arthur Sakharov on 7/10/13.
//
//

#import <Foundation/Foundation.h>

@class JSResponseHandler;
@protocol JSResponseDelegate
- (void) jsResponseEvent: (JSResponseHandler *) sender;
@end

@interface JSResponseHandler : NSObject

@property (nonatomic) id <JSResponseDelegate> delegate;

- (BOOL)parseJSResponce : (NSString*) response;

@end
