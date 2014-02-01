//
//  BakerAPI.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau
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
#import "Utils.h"

#import "NSMutableURLRequest+WebServiceClient.h"
#import "NSURL+Extensions.h"
#import "NSString+UUID.h"

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

#pragma mark - Shelf

- (BOOL)canGetShelfJSON {
    return ([self manifestURL] != nil);
}

- (void)getShelfJSON:(void (^)(NSData*)) callback {

    if ([NSThread isMainThread]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *data = [self getFromURL:[self manifestURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
            if (callback) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    callback(data);
                });
            }
        });
    } else {
        NSData *data = [self getFromURL:[self manifestURL] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        if (callback) {
            callback(data);
        }
    }
}

#pragma mark - Purchases

- (BOOL)canGetPurchasesJSON {
    return ([self purchasesURL] != nil);
}

- (void)getPurchasesJSON:(void (^)(NSData*)) callback  {

    if ([self canGetPurchasesJSON]) {
        if ([NSThread isMainThread]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *data = [self getFromURL:[self purchasesURL] cachePolicy:NSURLRequestUseProtocolCachePolicy];
                if (callback) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        callback(data);
                    });
                }
            });
        } else {
            NSData *data = [self getFromURL:[self purchasesURL] cachePolicy:NSURLRequestUseProtocolCachePolicy];
            if (callback) {
                callback(data);
            }
        }
    } else if (callback) {
        callback(nil);
    }
}

- (BOOL)canPostPurchaseReceipt {
    return ([self purchaseConfirmationURL] != nil);
}
- (BOOL)postPurchaseReceipt:(NSString *)receipt ofType:(NSString *)type {
    if ([self canPostPurchaseReceipt]) {
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                type, @"type",
                                receipt, @"receipt_data",
                                nil];

        return [self postParams:params toURL:[self purchaseConfirmationURL]];
    }
    return NO;
}

#pragma mark - APNS

- (BOOL)canPostAPNSToken {
    return ([self postAPNSTokenURL] != nil);
}
- (BOOL)postAPNSToken:(NSString *)apnsToken {
    if ([self canPostAPNSToken]) {
        NSDictionary *params = [NSDictionary dictionaryWithObject:apnsToken forKey:@"apns_token"];

        return [self postParams:params toURL:[self postAPNSTokenURL]];
    }
    return NO;
}

#pragma mark - User ID

+ (BOOL)generateUUIDOnce {
    if (![self UUID]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSString uuid] forKey:@"UUID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)UUID {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"UUID"];
}

#pragma mark - Helpers

- (NSURLRequest *)requestForURL:(NSURL *)url method:(NSString *)method {
    return [self requestForURL:url parameters:[NSDictionary dictionary] method:method cachePolicy:NSURLRequestUseProtocolCachePolicy];
}
- (NSURLRequest *)requestForURL:(NSURL *)url parameters:(NSDictionary *)parameters method:(NSString *)method cachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [requestParams setObject:[Utils appID] forKey:@"app_id"];
    [requestParams setObject:[BakerAPI UUID] forKey:@"user_id"];

    #if DEBUG
        [requestParams setObject:@"debug" forKey:@"environment"];
    #else
        [requestParams setObject:@"production" forKey:@"environment"];
    #endif
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        [requestParams setObject:@"tablet" forKey:@"devicetype"];
    }
    else{
        [requestParams setObject:@"phone" forKey:@"devicetype"];
    }

    NSURL *requestURL = [self replaceParameters:requestParams inURL:url];
    NSMutableURLRequest *request = nil;

    if ([method isEqualToString:@"GET"]) {
        NSString *queryString = [self queryStringFromParameters:requestParams];
        requestURL = [requestURL URLByAppendingQueryString:queryString];
        request = [NSURLRequest requestWithURL:requestURL cachePolicy:cachePolicy timeoutInterval:REQUEST_TIMEOUT];
    } else if ([method isEqualToString:@"POST"]) {
        request = [[[NSMutableURLRequest alloc] initWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:REQUEST_TIMEOUT] autorelease];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setFormPostParameters:requestParams];
    }

    return request;
}

- (BOOL)postParams:(NSDictionary *)params toURL:(NSURL *)url {
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSURLRequest *request = [self requestForURL:url parameters:params method:@"POST" cachePolicy:NSURLRequestUseProtocolCachePolicy];

    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (error) {
        NSLog(@"[ERROR] Failed POST request to %@: %@", [request URL], [error localizedDescription]);
        return NO;
    } else if ([response statusCode] == 200) {
        return YES;
    } else {
        NSLog(@"[ERROR] Failed POST request to %@: response was %d %@",
              [request URL],
              [response statusCode],
              [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]);
        return NO;
    }
}

- (NSData *)getFromURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSURLRequest *request = [self requestForURL:url parameters:[NSDictionary dictionary] method:@"GET" cachePolicy:cachePolicy];

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (error) {
        NSLog(@"[ERROR] Failed GET request to %@: %@", [request URL], [error localizedDescription]);
        return nil;
    } else if ([response statusCode] == 200) {
        return data;
    } else {
        NSLog(@"[ERROR] Failed GET request to %@: response was %d %@",
              [request URL],
              [response statusCode],
              [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]);
        return nil;
    }
}

- (NSURL *)replaceParameters:(NSMutableDictionary *)parameters inURL:(NSURL *)url {
    __block NSMutableString *urlString = [NSMutableString stringWithString:[url absoluteString]];
    NSDictionary *allParameters = [NSDictionary dictionaryWithDictionary:parameters];
    [allParameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *keyToReplace = [@":" stringByAppendingString:key];
        NSRange range = [urlString rangeOfString:keyToReplace options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) {
            [urlString replaceCharactersInRange:range withString:obj];
            [parameters removeObjectForKey:key];
        }
    }];
    return [NSURL URLWithString:urlString];
}

- (NSString *)queryStringFromParameters:(NSDictionary *)parameters {
    __block NSMutableString *queryString = [NSMutableString stringWithString:@""];
    if ([parameters count] > 0) {
        [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *queryParameter = [NSString stringWithFormat:@"%@=%@&", key, obj];
            [queryString appendString:queryParameter];
        }];
        // Remove the last "&"
        [queryString deleteCharactersInRange:NSMakeRange([queryString length] - 1, 1)];
    }
    return queryString;
}

- (NSURL *)manifestURL {
    #ifdef BAKER_NEWSSTAND
    if ([NEWSSTAND_MANIFEST_URL length] > 0) {
        return [NSURL URLWithString:NEWSSTAND_MANIFEST_URL];
    }
    #endif
    return nil;
}
- (NSURL *)purchasesURL {
    #ifdef BAKER_NEWSSTAND
    if ([PURCHASES_URL length] > 0) {
        return [NSURL URLWithString:PURCHASES_URL];
    }
    #endif
    return nil;
}
- (NSURL *)purchaseConfirmationURL {
    #ifdef BAKER_NEWSSTAND
    if ([PURCHASE_CONFIRMATION_URL length] > 0) {
        return [NSURL URLWithString:PURCHASE_CONFIRMATION_URL];
    }
    #endif
    return nil;
}
- (NSURL *)postAPNSTokenURL {
    #ifdef BAKER_NEWSSTAND
    if ([POST_APNS_TOKEN_URL length] > 0) {
        return [NSURL URLWithString:POST_APNS_TOKEN_URL];
    }
    #endif
    return nil;
}

@end
