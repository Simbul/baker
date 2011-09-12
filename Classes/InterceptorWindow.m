//
//  InterceptorWindow.m
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

#import "InterceptorWindow.h"
#import "RootViewController.h"

@implementation InterceptorWindow

#pragma mark - Init

- (id)initWithTarget:(UIView *)targetView eventsDelegate:(UIViewController *)delegateController frame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        target = targetView;
        eventsDelegate = (RootViewController *)delegateController;
    }
    return self;
}

#pragma mark - Events management

- (void)sendEvent:(UIEvent *)event {
	
    // At the moment, all the events are propagated (by calling the sendEvent method
	// in the parent class) except single-finger multitaps.
	
	BOOL shouldCallParent = YES;
	
	if (event.type == UIEventTypeTouches) {
		
        NSSet *touches = [event allTouches];		
		if (touches.count == 1) {
			
            UITouch *touch = touches.anyObject;
			
			if (touch.phase == UITouchPhaseBegan) {
				isScrolling = NO;
			} else if (touch.phase == UITouchPhaseMoved) {
				isScrolling = YES;
			}
        
			if (touch.tapCount > 1) {
                // Touch is not the first of multiple subsequent touches
                if (touch.phase == UITouchPhaseEnded && !isScrolling) {
                    NSLog(@"Multi Tap");
					[self performSelector:@selector(forwardTap:) withObject:touch];
				}
				shouldCallParent = NO;
                
			} else if ([touch.view isDescendantOfView:target] == YES) {
                // Touch was on the target view (or one of its descendants) ...
                if (isScrolling) {
					// ... and is not a single tap but a scrollin gesture
                    NSLog(@"Scrolling");
					[self performSelector:@selector(forwardScroll:) withObject:touch];
				
                } else if (touch.phase == UITouchPhaseEnded) {
					
					// ... and a single tap has just been completed
					NSLog(@"Single Tap");
					[self performSelector:@selector(forwardTap:) withObject:touch];
				}
			}
		}
	}
	
	if (shouldCallParent) {
		[super sendEvent:event];
	}
}

- (void)forwardTap:(UITouch *)touch {
	[eventsDelegate userDidTap:touch];
}
- (void)forwardScroll:(UITouch *)touch {
	[eventsDelegate userDidScroll:touch];
}

- (void)dealloc {
	
    [target release];
	[eventsDelegate release];
    
    [super dealloc];
}

@end
