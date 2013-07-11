//
//  JSResponseHandler.h
//  Baker
//
//  Created by Arthur Sakharov on 7/10/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PageRelPos) {
    pPrev,
    pCurr,
    pNext
};

@class JSResponseHandler;
@protocol JSResponseDelegate
- (void) jsResponseEvent: (JSResponseHandler *) sender
                 inPage :(PageRelPos)pagePos;
@end

@interface JSResponseHandler : NSObject

@property (assign, nonatomic) id <JSResponseDelegate> delegate;

- (BOOL)parseJSResponse : (NSString*) response
                forPage :(PageRelPos)pagePos;

@end
