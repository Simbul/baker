//
//  BakerBook.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau, Pieter Claerhout
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

#import "BKRCore.h"
#import "BKRBook.h"
#import "NSString+BakerExtensions.h"

@implementation BKRBook

#pragma mark - Initialization

- (id)initWithBookPath:(NSString*)bookPath bundled:(BOOL)bundled {
    if (![[NSFileManager defaultManager] fileExistsAtPath:bookPath]) {
        return nil;
    }
    
    self = [self initWithBookJSONPath:[bookPath stringByAppendingPathComponent:@"book.json"]];
    if (self) {
        [self updateBookPath:bookPath bundled:bundled];
    }
    return self;

}

- (id)initWithBookJSONPath:(NSString*)bookJSONPath {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:bookJSONPath]) {
        return nil;
    }

    NSError* error = nil;
    NSData* bookJSON = [NSData dataWithContentsOfFile:bookJSONPath options:0 error:&error];
    if (error) {
        self.parseError = [NSString stringWithFormat:@"ERROR: reading 'book.json': %@", error.localizedDescription];
        NSLog(@"[BakerBook] ERROR reading 'book.json': %@", error.localizedDescription);
        return nil;
    }

    NSDictionary* bookData = [NSJSONSerialization JSONObjectWithData:bookJSON
                                                             options:0
                                                               error:&error];
    if (error) {
        self.parseError = [NSString stringWithFormat:@"ERROR: reading 'book.json': %@", error.localizedDescription];
        NSLog(@"[BakerBook] ERROR parsing 'book.json': %@", error.localizedDescription);
        return nil;
    }

    return [self initWithBookData:bookData];
    
}

- (id)initWithBookData:(NSDictionary*)bookData {
    self = [super init];
    if (self && [self loadBookData:bookData]) {
        NSString *baseID = [self.title stringByAppendingFormat:@" %@", [self.url bkrStringSHAEncoded]];
        self.ID = [self sanitizeForPath:baseID];
        NSLog(@"[BakerBook] 'book.json' parsed successfully. Book '%@' created with id '%@'.", self.title, self.ID);
        return self;
    }
    return nil;
}

- (NSString*)sanitizeForPath:(NSString*)string {
    
    NSError *error = nil;
    NSString *newString;
    NSRegularExpression *regex;

    // Strip everything except numbers, ASCII letters and spaces
    regex     = [NSRegularExpression regularExpressionWithPattern:@"[^1-9a-z ]" options:NSRegularExpressionCaseInsensitive error:&error];
    newString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];

    // Replace spaces with dashes
    regex     = [NSRegularExpression regularExpressionWithPattern:@" +" options:NSRegularExpressionCaseInsensitive error:&error];
    newString = [regex stringByReplacingMatchesInString:newString options:0 range:NSMakeRange(0, [newString length]) withTemplate:@"-"];

    return [newString lowercaseString];
    
}

- (BOOL)loadBookData:(NSDictionary*)bookData {
    if (![self validateBookJSON:bookData withRequirements:@[@"title", @"author", @"url", @"contents"]]) {
        return NO;
    }

    self.bookData = bookData;
    
    self.hpub       = bookData[@"hpub"];
    self.title      = bookData[@"title"];
    self.date       = bookData[@"date"];
    self.categories = bookData[@"categories"];

    if ([bookData[@"author"] isKindOfClass:[NSArray class]]) {
        self.author = bookData[@"author"];
    } else {
        self.author = @[bookData[@"author"]];
    }

    if ([bookData[@"creator"] isKindOfClass:[NSArray class]]) {
        self.creator = bookData[@"creator"];
    } else if([bookData[@"creator"] isKindOfClass:[NSString class]]) {
        self.creator = @[bookData[@"creator"]];
    }

    self.publisher = bookData[@"publisher"];

    self.url   = bookData[@"url"];
    self.cover = bookData[@"cover"];

    self.orientation = bookData[@"orientation"];
    self.zoomable    = bookData[@"zoomable"];

    // TODO: create an array of n BakerPage objects
    self.contents = bookData[@"contents"];

    self.bakerBackground               = bookData[@"-baker-background"];
    self.bakerBackgroundImagePortrait  = bookData[@"-baker-background-image-portrait"];
    self.bakerBackgroundImageLandscape = bookData[@"-baker-background-image-landscape"];
    self.bakerPageNumbersColor         = bookData[@"-baker-page-numbers-color"];
    self.bakerPageNumbersAlpha         = bookData[@"-baker-page-numbers-alpha"];
    self.bakerPageScreenshots          = bookData[@"-baker-page-screenshots"];

    self.bakerRendering          = bookData[@"-baker-rendering"];
    self.bakerVerticalBounce     = bookData[@"-baker-vertical-bounce"];
    self.bakerVerticalPagination = bookData[@"-baker-vertical-pagination"];
    self.bakerPageTurnTap        = bookData[@"-baker-page-turn-tap"];
    self.bakerPageTurnSwipe      = bookData[@"-baker-page-turn-swipe"];
    self.bakerMediaAutoplay      = bookData[@"-baker-media-autoplay"];

    self.bakerIndexWidth  = bookData[@"-baker-index-width"];
    self.bakerIndexHeight = bookData[@"-baker-index-height"];
    self.bakerIndexBounce = bookData[@"-baker-index-bounce"];
    self.bakerStartAtPage = bookData[@"-baker-start-at-page"];

    [self loadBookJSONDefault];

    return YES;
}

- (void)loadBookJSONDefault {
    
    if (self.hpub == nil) {
        self.hpub = @1;
    }

    if (self.bakerBackground == nil) {
        self.bakerBackground = @"#000000";
    }
    if (self.bakerPageNumbersColor == nil) {
        self.bakerPageNumbersColor = @"#ffffff";
    }
    if (self.bakerPageNumbersAlpha == nil) {
        self.bakerPageNumbersAlpha = @0.3f;
    }

    if (self.bakerRendering == nil) {
        self.bakerRendering = @"screenshots";
    }
    if (self.bakerVerticalBounce == nil) {
        self.bakerVerticalBounce = @YES;
    }
    if (self.bakerVerticalPagination == nil) {
        self.bakerVerticalPagination = @NO;
    }

    if (self.bakerPageTurnTap == nil) {
        self.bakerPageTurnTap = @YES;
    }

    if (self.bakerPageTurnSwipe == nil) {
        self.bakerPageTurnSwipe = @YES;
    }
    if (self.bakerMediaAutoplay == nil) {
        self.bakerMediaAutoplay = @NO;
    }

    if (self.bakerIndexBounce == nil) {
        self.bakerIndexBounce = @NO;
    }
    if (self.bakerStartAtPage == nil) {
        self.bakerStartAtPage = @1;
    }
    
}


#pragma mark - HPub validation

- (BOOL)isValid {
    return BKR_IsEmpty(self.parseError);
}

- (BOOL)validateBookJSON:(NSDictionary*)bookData withRequirements:(NSArray*)requirements {
    for (NSString *param in requirements) {
        if (bookData[param] == nil) {
            NSLog(@"[BakerBook] ERROR: param '%@' is missing. Add it to 'book.json'.", param);
            return NO;
        }
    }

    NSArray *shouldBeArray  = @[@"author",
                               @"creator",
                               @"contents"];
    
    NSArray *shouldBeString = @[@"title",
                               @"date",
                               @"author",
                               @"creator",
                               @"publisher",
                               @"url",
                               @"cover",
                               @"orientation",
                               @"-baker-background",
                               @"-baker-background-image-portrait",
                               @"-baker-background-image-landscape",
                               @"-baker-page-numbers-color",
                               @"-baker-page-screenshots",
                               @"-baker-rendering"];
    
    NSArray *shouldBeNumber = @[@"hpub",
                               @"zoomable",
                               @"-baker-page-numbers-alpha",
                               @"-baker-vertical-bounce",
                               @"-baker-vertical-pagination",
                               @"-baker-page-turn-tap",
                               @"-baker-page-turn-swipe",
                               @"-baker-media-autoplay",
                               @"-baker-index-width",
                               @"-baker-index-height",
                               @"-baker-index-bounce",
                               @"-baker-start-at-page"];
    
    NSArray *knownParams = [[shouldBeArray arrayByAddingObjectsFromArray:shouldBeString] arrayByAddingObjectsFromArray:shouldBeNumber];
    
    for (NSString *param in bookData) {

        if (![self matchParam:param againstParamsArray:knownParams]) {
            continue;
        }

        id obj = bookData[param];
        if ([obj isKindOfClass:[NSArray class]] && ![self validateArray:(NSArray *)obj forParam:param withParamsArray:shouldBeArray]) {
            return NO;
        } else if ([obj isKindOfClass:[NSString class]] && ![self validateString:(NSString *)obj forParam:param withParamsArray:shouldBeString]) {
            return NO;
        } else if ([obj isKindOfClass:[NSNumber class]] && ![self validateNumber:(NSNumber *)obj forParam:param withParamsArray:shouldBeNumber]) {
            return NO;
        }
        
    }

    return YES;
}

- (BOOL)validateArray:(NSArray*)array forParam:(NSString*)param withParamsArray:(NSArray*)paramsArray {
    
    if (![self matchParam:param againstParamsArray:paramsArray]) {
        NSLog(@"[BakerBook] ERROR: param '%@' should not be an Array. Check it in 'book.json'.", param);
        return NO;
    }

    if (([param isEqualToString:@"author"] || [param isEqualToString:@"contents"]) && [array count] == 0) {
        NSLog(@"[BakerBook] ERROR: param '%@' is empty. Fill it in 'book.json'.", param);
        return NO;
    }

    for (id obj in array) {
        if ([param isEqualToString:@"author"] && (![obj isKindOfClass:[NSString class]] || [(NSString *)obj isEqualToString:@""])) {
            NSLog(@"[BakerBook] ERROR: param 'author' is empty. Fill it in 'book.json'.");
            return NO;
        } else if ([param isEqualToString:@"contents"]) {
            if ([obj isKindOfClass:[NSDictionary class]] && ![self validateBookJSON:(NSDictionary *)obj withRequirements:@[@"url"]]) {
                NSLog(@"[BakerBook] ERROR: param 'contents' is not validating. Check it in 'book.json'.");
                return NO;
            }
        } else if (![obj isKindOfClass:[NSString class]]) {
            NSLog(@"[BakerBook] ERROR: param '%@' type is wrong. Check it in 'book.json'.", param);
            return NO;
        }
    }

    return YES;
    
}

- (BOOL)validateString:(NSString*)string forParam:(NSString *)param withParamsArray:(NSArray*)paramsArray {
    
    if (![self matchParam:param againstParamsArray:paramsArray]) {
        NSLog(@"[BakerBook] ERROR: param '%@' should not be a String. Check it in 'book.json'.", param);
        return NO;
    }

    if (([param isEqualToString:@"title"] || [param isEqualToString:@"author"] || [param isEqualToString:@"url"]) && [string isEqualToString:@""]) {
        NSLog(@"[BakerBook] ERROR: param '%@' is empty. Fill it in 'book.json'.", param);
        return NO;
    }

    if ([param isEqualToString:@"-baker-rendering"] && (![string isEqualToString:@"screenshots"] && ![string isEqualToString:@"three-cards"])) {
        NSLog(@"Error: param \"-baker-rendering\" should be equal to \"screenshots\" or \"three-cards\" but it's not");
        NSLog(@"[BakerBook] ERROR: param '-baker-rendering' must be equal to 'screenshots' or 'three-cards'. Check it in 'book.json'.");
        return NO;
    }

    return YES;
    
}

- (BOOL)validateNumber:(NSNumber*)number forParam:(NSString*)param withParamsArray:(NSArray*)paramsArray {
    if (![self matchParam:param againstParamsArray:paramsArray]) {
        NSLog(@"[BakerBook] ERROR: param '%@' should not be a Number. Check it in 'book.json'.", param);
        return NO;
    }
    return YES;
}

- (BOOL)matchParam:(NSString*)param againstParamsArray:(NSArray*)paramsArray {
    for (NSString *match in paramsArray) {
        if ([param isEqualToString:match]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Book status management

- (BOOL)updateBookPath:(NSString*)bookPath bundled:(BOOL)bundled {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:bookPath]) {
        return NO;
    }

    self.path      = bookPath;
    self.isBundled = @(bundled);

    self.screenshotsPath     = [bookPath stringByAppendingPathComponent:self.bakerPageScreenshots];
    self.screenshotsWritable = @YES;

    if (bundled) {
        if (![fileManager fileExistsAtPath:self.screenshotsPath]) {
            // TODO: generate writableBookPath in app private documents/books/self.ID;
            NSString *writableBookPath = @"writableBookPath";
            self.screenshotsPath = [writableBookPath stringByAppendingPathComponent:self.bakerPageScreenshots];
        } else {
            self.screenshotsWritable = @NO;
        }
    }

    if (![fileManager fileExistsAtPath:self.screenshotsPath]) {
        return [fileManager createDirectoryAtPath:self.screenshotsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return YES;
}

@end
