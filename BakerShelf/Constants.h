//
//  Constants.h
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


#ifndef Baker_Constants_h
#define Baker_Constants_h

    // ----------------------------------------------------------------------------------------------------
    // NEWSSTAND SUPPORT
    // The following line, together with other settings, enables Newsstand mode.
    // Remove this, remove the NewsstandKit.framework and the Newsstand entries in Baker-Info.plist to disable it.
    // See: https://github.com/Simbul/baker/wiki/Newsstand-vs-Bundled-publications-support-in-Baker-4.0
    #define BAKER_NEWSSTAND

    #ifdef BAKER_NEWSSTAND

        // ----------------------------------------------------------------------------------------------------
        // Mandatory - This constant defines where the JSON file containing all the publications is located.
        // For more information on this file, see: https://github.com/Simbul/baker/wiki/Newsstand-shelf-JSON
        // E.g. @"http://example.com/shelf.json"
        #define NEWSSTAND_MANIFEST_URL @"http://bakerframework.com/demo/shelf.json"

        // ----------------------------------------------------------------------------------------------------
        // Optional - This constant specifies the URL to ping back when a user purchases an issue or a subscription.
        // For more information, see: https://github.com/Simbul/baker/wiki/Baker-Server-API
        // E.g. @"http://example.com/purchased"
        #define PURCHASE_CONFIRMATION_URL @""

        // ----------------------------------------------------------------------------------------------------
        // Optional - This constant specifies a URL that will be used to retrieve the list of purchased issues.
        // For more information, see: https://github.com/Simbul/baker/wiki/Baker-Server-API
        // E.g. @"http://example.com/purchases"
        #define PURCHASES_URL @""

        // ----------------------------------------------------------------------------------------------------
        // Optional - This constant specifies the URL to ping back when a user enables push notifications.
        // For more information, see: https://github.com/Simbul/baker/wiki/Baker-Server-API
        // E.g. @"http://example.com/post_apns_token"
        #define POST_APNS_TOKEN_URL @""

        // ----------------------------------------------------------------------------------------------------
        // Mandatory - The following two constants identify the subscriptions you set up in iTunesConnect.
        // See: iTunes Connect -> Manage Your Application -> (Your application) -> Manage In App Purchases
        // You *have* to set at least one among FREE_SUBSCRIPTION_PRODUCT_ID and AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS.

        // This constant identifies a free subscription.
        // E.g. @"com.example.MyBook.subscription.free"
        #define FREE_SUBSCRIPTION_PRODUCT_ID @""

        // This constant identifies one or more auto-renewable subscriptions.
        // E.g.:
        // #define AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS [NSArray arrayWithObjects: \
        //     @"com.example.MyBook.subscription.3months", \
        //     @"com.example.MyBook.subscription.6months", \
        //     nil]
        #define AUTO_RENEWABLE_SUBSCRIPTION_PRODUCT_IDS [NSArray arrayWithObjects: \
            nil]

    #endif

    // Timeout for most network requests (in seconds)
    #define REQUEST_TIMEOUT 15

#endif
