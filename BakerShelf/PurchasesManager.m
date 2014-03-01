//
//  PurchasesManager.m
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

#import "PurchasesManager.h"
#import "BakerAPI.h"

#import "NSData+Base64.h"
#import "NSMutableURLRequest+WebServiceClient.h"
#import "Utils.h"
#import "NSURL+Extensions.h"

#ifdef BAKER_NEWSSTAND
@implementation PurchasesManager

@synthesize products;
@synthesize subscribed;

-(id)init {
    self = [super init];

    if (self) {
        self.products = [[[NSMutableDictionary alloc] init] autorelease];
        self.subscribed = NO;

        _purchases = [[NSMutableDictionary alloc] init];

        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

        _enableProductRequestFailureNotifications = YES;
    }

    return self;
}

#pragma mark - Singleton

+ (PurchasesManager *)sharedInstance {
    static dispatch_once_t once;
    static PurchasesManager *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Purchased flag

- (BOOL)isMarkedAsPurchased:(NSString *)productID {
    return [[NSUserDefaults standardUserDefaults] boolForKey:productID];
}

- (void)markAsPurchased:(NSString *)productID {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:productID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Prices

- (void)retrievePricesFor:(NSSet *)productIDs {
    [self retrievePricesFor:productIDs andEnableFailureNotifications:YES];
}
- (void)retrievePricesFor:(NSSet *)productIDs andEnableFailureNotifications:(BOOL)enable {
    if ([productIDs count] > 0) {
        _enableProductRequestFailureNotifications = enable;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIDs];
            productsRequest.delegate = self;
            [productsRequest start];
        });
    }
}

- (void)retrievePriceFor:(NSString *)productID {
    [self retrievePriceFor:productID andEnableFailureNotification:YES];
}
- (void)retrievePriceFor:(NSString *)productID andEnableFailureNotification:(BOOL)enable {
    NSSet *productIDs = [NSSet setWithObject:productID];
    [self retrievePricesFor:productIDs andEnableFailureNotifications:enable];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    [self logProducts:response.products];

    for (NSString *productID in response.invalidProductIdentifiers) {
        NSLog(@"Invalid product identifier: %@", productID);
    }

    NSMutableSet *ids = [NSMutableSet setWithCapacity:response.products.count];
    for (SKProduct *skProduct in response.products) {
        [self.products setObject:skProduct forKey:skProduct.productIdentifier];
        [ids addObject:skProduct.productIdentifier];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:ids forKey:@"ids"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_products_retrieved" object:self userInfo:userInfo];

    [request release];
}

- (void)logProducts:(NSArray *)skProducts {
    NSLog(@"Received %d products from App Store", [skProducts count]);
    for (SKProduct *skProduct in skProducts) {
        NSLog(@"- %@", skProduct.productIdentifier);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"App Store request failure: %@", error);

    if (_enableProductRequestFailureNotifications) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_products_request_failed" object:self userInfo:userInfo];
    }

    [request release];
}

- (NSString *)priceFor:(NSString *)productID {
    SKProduct *product = [products objectForKey:productID];
    if (product) {
        [_numberFormatter setLocale:product.priceLocale];
        return [_numberFormatter stringFromNumber:product.price];
    }
    return nil;
}

- (NSString *)displayTitleFor:(NSString *)productID {
    SKProduct *product = [products objectForKey:productID];
    if(product) {
        return product.localizedTitle;
    }
    // If for some reason we can't find the product, then fallback to the old
    // behaviour of looking for a localized string
    return NSLocalizedString(productID, nil);
}

#pragma mark - Purchases

- (BOOL)purchase:(NSString *)productID {
    SKProduct *product = [self productFor:productID];
    if (product) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];

        return YES;
    } else {
        NSLog(@"Trying to buy unavailable product %@", productID);

        return NO;
    }
}

- (BOOL)finishTransaction:(SKPaymentTransaction *)transaction {
    if ([self recordTransaction:transaction]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)recordTransaction:(SKPaymentTransaction *)transaction {
    [[NSUserDefaults standardUserDefaults] setObject:transaction.transactionIdentifier forKey:@"receipt"];

    BakerAPI *api = [BakerAPI sharedInstance];
    if ([api canPostPurchaseReceipt]) {
        NSString *receipt = [transaction.transactionReceipt base64EncodedString];
        NSString *type = [self transactionType:transaction];

        return [api postPurchaseReceipt:receipt ofType:type];
    }

    return YES;
}

- (NSString *)transactionType:(SKPaymentTransaction *)transaction {
    NSString *productID = transaction.payment.productIdentifier;
    if ([productID isEqualToString:FREE_SUBSCRIPTION_PRODUCT_ID]) {
        return @"free-subscription";
    } else if ([AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS containsObject:productID]) {
        return @"auto-renewable-subscription";
    } else {
        return @"issue";
    }
}

- (void)retrievePurchasesFor:(NSSet *)productIDs withCallback:(void (^)(NSDictionary*))callback {
    BakerAPI *api = [BakerAPI sharedInstance];

    if ([api canGetPurchasesJSON]) {
        [api getPurchasesJSON:^(NSData* jsonResponse) {
            if (jsonResponse) {
                NSError* error = nil;
                NSDictionary *purchasesResponse = [NSJSONSerialization JSONObjectWithData:jsonResponse
                                                                                  options:0
                                                                                    error:&error];
                // TODO: handle error
                
                if (purchasesResponse) {
                    NSArray *purchasedIssues = [purchasesResponse objectForKey:@"issues"];
                    self.subscribed = [[purchasesResponse objectForKey:@"subscribed"] boolValue];
                    
                    [productIDs enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                        [_purchases setObject:[NSNumber numberWithBool:[purchasedIssues containsObject:obj]] forKey:obj];
                    }];
                } else {
                    NSLog(@"ERROR: Could not parse response from purchases API call. Received: %@", jsonResponse);
                }
            }

            if (callback) {
                callback([NSDictionary dictionaryWithDictionary:_purchases]);
            }
        }];
    } else if (callback) {
        callback(nil);
    }
}

- (BOOL)isPurchased:(NSString *)productID {
    id purchased = [_purchases objectForKey:productID];
    if (purchased) {
        return [purchased boolValue];
    } else {
        return [self isMarkedAsPurchased:productID];
    }
}

#pragma mark - Payment queue

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    [self logTransactions:transactions];

    BOOL isRestoring = NO;
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                // Nothing to do at the moment
                break;
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                isRestoring = YES;
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }

    if (isRestoring) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_multiple_restores" object:self userInfo:nil];
    }
}

- (void)logTransactions:(NSArray *)transactions {
    NSLog(@"Received %d transactions from App Store", [transactions count]);
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"- purchasing: %@", transaction.payment.productIdentifier);
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"- purchased: %@", transaction.payment.productIdentifier);
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"- failed: %@", transaction.payment.productIdentifier);
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"- restored: %@", transaction.payment.productIdentifier);
                break;
            default:
                NSLog(@"- unsupported transaction type: %@", transaction.payment.productIdentifier);
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:transaction forKey:@"transaction"];
    NSString *productId = transaction.payment.productIdentifier;

    if ([productId isEqualToString:FREE_SUBSCRIPTION_PRODUCT_ID] || [AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS containsObject:productId]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_subscription_purchased" object:self userInfo:userInfo];
    } else if ([self productFor:productId]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_issue_purchased" object:self userInfo:userInfo];
    } else {
        NSLog(@"ERROR: Completed transaction for %@, which is not a Product ID this app recognises", productId);
    }
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:transaction forKey:@"transaction"];
    NSString *productId = transaction.payment.productIdentifier;

    if ([productId isEqualToString:FREE_SUBSCRIPTION_PRODUCT_ID] || [AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS containsObject:productId]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_subscription_restored" object:self userInfo:userInfo];
    } else if ([self productFor:productId]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_issue_restored" object:self userInfo:userInfo];
    } else {
        NSLog(@"ERROR: Trying to restore %@, which is not a Product ID this app recognises", productId);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_restored_issue_not_recognised" object:self userInfo:userInfo];
    }
}

-(void)failedTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Payment transaction failure: %@", transaction.error);

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:transaction forKey:@"transaction"];
    NSString *productId = transaction.payment.productIdentifier;

    if ([productId isEqualToString:FREE_SUBSCRIPTION_PRODUCT_ID] || [AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS containsObject:productId]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_subscription_failed" object:self userInfo:userInfo];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_issue_purchase_failed" object:self userInfo:userInfo];
    }

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restore {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_restore_finished" object:self userInfo:nil];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"Transaction restore failure: %@", error);

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:@"error"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"notification_restore_failed" object:self userInfo:userInfo];
}

#pragma mark - Products

- (SKProduct *)productFor:(NSString *)productID {
    return [self.products objectForKey:productID];
}

#pragma mark - Subscriptions

- (BOOL)hasSubscriptions {
    return [FREE_SUBSCRIPTION_PRODUCT_ID length] > 0 || [AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS count] > 0;
}

#pragma mark - Memory management

-(void)dealloc {
    [products release];
    [_numberFormatter release];
    [_purchases release];

    [super dealloc];
}

@end
#endif
