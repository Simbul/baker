//
//  BakerAPI.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
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

#import "BakerAPI.h"
#import "Constants.h"
#import "NSMutableURLRequest+WebServiceClient.h"

#import "Utils.h"
#ifdef BAKER_NEWSSTAND
#import "PurchasesManager.h"
#endif

@implementation BakerAPI

#pragma mark - Singleton

+ (BakerAPI *)sharedInstance {
    static dispatch_once_t once;
    static BakerAPI *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - APNS

- (BOOL)postAPNSToken:(NSString *)apnsToken {
    if ([POST_APNS_TOKEN_URL length] > 0) {
        NSDictionary *params = [NSDictionary dictionaryWithObject:apnsToken forKey:@"apns_token"];
        NSError *error = nil;
        
        [self postParams:params toURL:[NSURL URLWithString:POST_APNS_TOKEN_URL] error:&error];
        if (error) {
            NSLog(@"Error sending APNS device token %@", error);
            return NO;
        }
        return YES;
    }
    return NO;
}

#pragma mark - Helpers

- (NSData *)postParams:(NSDictionary *)params toURL:(NSURL *)url error:(NSError **)error {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [postParams setObject:[Utils appID] forKey:@"app_id"];
    
    #ifdef BAKER_NEWSSTAND
    [postParams setObject:[PurchasesManager UUID] forKey:@"user_id"];
    #endif
    
    NSURLResponse *response = nil;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT];
    [request setHTTPMethod:@"POST"];
    [request setFormPostParameters:postParams];
    
    return [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
}

@end
