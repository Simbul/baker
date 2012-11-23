//
//  Constants.h
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


#ifndef Baker_Constants_h
#define Baker_Constants_h

    // ----------------------------------------------------------------------------------------------------
    // NEWSSTAND SUPPORT
    // The following line, together with other settings, enables Newsstand code.
    // Remove this, remove the NewsstandKit.framework and the Newsstand entries in Baker-Info.plist to disable it.
    // See: https://github.com/Simbul/baker/wiki/Newsstand-vs-Bundled-publications-support-in-Baker-4.0
    #define BAKER_NEWSSTAND

    #ifdef BAKER_NEWSSTAND

        // Change the Shelf Navigation Title at the top of the main Issues List
        #define SHELF_NAVIGATION_TITLE @"Baker Shelf"

        // Change the colors of individual elements on the Issue display.
        // You can change the Issue Title label color, Info Label Color, Button Colors, Loading Label Color and Spinner Color
        #define ISSUES_TITLE_LABEL_COLOR @"#000000"
        #define ISSUES_INFO_LABEL_COLOR @"#929292"
        #define ISSUES_BUTTON_COLOR @"#b72529"
        #define ISSUES_BUTTON_TEXT_COLOR @"#FFFFFF"
        #define ISSUES_ARCHIVE_TEXT_COLOR @"#b72529"
        #define ISSUES_LOADING_LABEL_COLOR @"#b72529"
        #define ISSUES_LOADING_SPINNER_COLOR @"#929292"

        // Remove the following line once you complete the Newsstand setup below.
        #warning Newsstand: Remember to set the AppStore/Newsstand constants and delete this line once you did it.

        // ----------------------------------------------------------------------------------------------------
        // Mandatory - This constant defines where the JSON file containing all the publications is located.
        // For more information on this file, see: https://github.com/Simbul/baker/wiki/Newsstand-shelf-JSON
        // E.g. @"http://example.com/books.json"
        #define NEWSSTAND_MANIFEST_URL @""

        // ----------------------------------------------------------------------------------------------------
        // Mandatory - This constant identifies the subscription you set up in iTunesConnect.
        // See: iTunes Connect -> Manage Your Application -> (Your application) -> Manage In App Purchases
        // E.g. @"com.example.MyBook.subscription.free"
        #define PRODUCT_ID_FREE_SUBSCRIPTION @""

        // ----------------------------------------------------------------------------------------------------
        // Optional - This constant specifies the URL to ping back when a user subscribes.
        // E.g. @"http://example.com/subscribe"
        #define PURCHASE_CONFIRMATION_URL @""

    #endif

#endif
