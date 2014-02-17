//
//  PurchasesManager.h
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

#import "Constants.h"
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#ifdef BAKER_NEWSSTAND
@interface PurchasesManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    NSMutableDictionary *_purchases;
    BOOL _enableProductRequestFailureNotifications;
}

@property (retain, nonatomic) NSMutableDictionary *products;
@property (retain, nonatomic) NSNumberFormatter *numberFormatter;
@property (nonatomic) BOOL subscribed;

#pragma mark - Singleton

+ (PurchasesManager *)sharedInstance;

#pragma mark - Purchased flag

- (BOOL)isMarkedAsPurchased:(NSString *)productID;
- (void)markAsPurchased:(NSString *)productID;

#pragma mark - Prices and display information

- (void)retrievePricesFor:(NSSet *)productIDs;
- (void)retrievePricesFor:(NSSet *)productIDs andEnableFailureNotifications:(BOOL)enable;

- (void)retrievePriceFor:(NSString *)productID;
- (void)retrievePriceFor:(NSString *)productID andEnableFailureNotification:(BOOL)enable;

- (NSString *)priceFor:(NSString *)productID;
- (NSString *)displayTitleFor:(NSString*)productID;

#pragma mark - Purchases

- (BOOL)purchase:(NSString *)productID;
- (BOOL)finishTransaction:(SKPaymentTransaction *)transaction;
- (void)restore;
- (void)retrievePurchasesFor:(NSSet *)productIDs withCallback:(void (^)(NSDictionary*))callback;
- (BOOL)isPurchased:(NSString *)productID;

#pragma mark - Products

- (SKProduct *)productFor:(NSString *)productID;

#pragma mark - Subscriptions

- (BOOL)hasSubscriptions;

@end
#endif
