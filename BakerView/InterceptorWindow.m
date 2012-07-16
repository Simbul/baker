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

@implementation InterceptorWindow

#pragma mark - Events management

- (void)sendEvent:(UIEvent *)event {
    
    [super sendEvent:event];
    [self interceptEvent:event];
}
- (void)interceptEvent:(UIEvent *)event {
    
    if (event.type == UIEventTypeTouches)
    {
        NSSet *touches = [event allTouches];
        if (touches.count == 1)
        {
            UITouch *touch = touches.anyObject;
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:touch, @"touch", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_touch_intercepted" object:nil userInfo:userInfo];
        }
    }
}

@end
