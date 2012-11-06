//
//  BakerDefines.h
//  Baker
//
//  Created by James Campbell on 05/11/2012.
//
//

#ifndef Baker_BakerDefines_h
#define Baker_BakerDefines_h

// IOS VERSION COMPARISON MACROS
#define SYSTEM_VERSION_EQUAL_TO(version)                  ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(version)              ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(version)  ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(version)                 ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(version)     ([[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedDescending)

// ALERT LABELS
#define OPEN_BOOK_MESSAGE       @"Do you want to download %@?"
#define OPEN_BOOK_CONFIRM       @"Open book"

#define CLOSE_BOOK_MESSAGE      @"Do you want to close this book?"
#define CLOSE_BOOK_CONFIRM      @"Close book"

#define ZERO_PAGES_TITLE        @"Whoops!"
#define ZERO_PAGES_MESSAGE      @"Sorry, that book had no pages."

#define ERROR_FEEDBACK_TITLE    @"Whoops!"
#define ERROR_FEEDBACK_MESSAGE  @"There was a problem downloading the book."
#define ERROR_FEEDBACK_CONFIRM  @"Retry"

#define EXTRACT_FEEDBACK_TITLE  @"Extracting..."

#define ALERT_FEEDBACK_CANCEL   @"Cancel"

#define INDEX_FILE_NAME         @"index.html"

#define URL_OPEN_MODALLY        @"referrer=Baker"
#define URL_OPEN_EXTERNAL       @"referrer=Safari"

// SCREENSHOT
#define MAX_SCREENSHOT_AFTER_CP  10
#define MAX_SCREENSHOT_BEFORE_CP 10

#endif

