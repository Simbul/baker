//
//  BakerBook.m
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

#import "BakerBook.h"
#import "NSString+Extensions.h"

@implementation BakerBook

#pragma mark - HPub parameters synthesis

@synthesize hpub;
@synthesize title;
@synthesize date;

@synthesize author;
@synthesize creator;
@synthesize publisher;

@synthesize url;
@synthesize cover;

@synthesize orientation;
@synthesize zoomable;

@synthesize contents;

#pragma mark - Baker HPub extensions synthesis

@synthesize bakerBackground;
@synthesize bakerBackgroundImagePortrait;
@synthesize bakerBackgroundImageLandscape;
@synthesize bakerPageNumbersColor;
@synthesize bakerPageNumbersAlpha;
@synthesize bakerPageScreenshots;

@synthesize bakerRendering;
@synthesize bakerVerticalBounce;
@synthesize bakerVerticalPagination;
@synthesize bakerPageTurnTap;
@synthesize bakerPageTurnSwipe;
@synthesize bakerMediaAutoplay;

@synthesize bakerIndexWidth;
@synthesize bakerIndexHeight;
@synthesize bakerIndexBounce;
@synthesize bakerStartAtPage;

#pragma mark - Book status synthesis

@synthesize ID;
@synthesize path;
@synthesize isBundled;
@synthesize screenshotsPath;
@synthesize screenshotsWritable;
@synthesize currentPage;
@synthesize lastScrollIndex;
@synthesize lastOpenedDate;

#pragma mark - Init

- (id)initWithBookPath:(NSString *)bookPath bundled:(BOOL)bundled
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:bookPath]) {
        return nil;
    }

    self = [self initWithBookJSONPath:[bookPath stringByAppendingPathComponent:@"book.json"]];
    if (self) {
        [self updateBookPath:bookPath bundled:bundled];
    }

    return self;
}
- (id)initWithBookJSONPath:(NSString *)bookJSONPath
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:bookJSONPath]) {
        return nil;
    }

    NSError* error = nil;
    NSData* bookJSON = [NSData dataWithContentsOfFile:bookJSONPath options:0 error:&error];
    if (error) {
        NSLog(@"[BakerBook] ERROR reading 'book.json': %@", error.localizedDescription);
        return nil;
    }

    NSDictionary* bookData = [NSJSONSerialization JSONObjectWithData:bookJSON
                                                             options:0
                                                               error:&error];
    if (error) {
        NSLog(@"[BakerBook] ERROR parsing 'book.json': %@", error.localizedDescription);
        return nil;
    }

    return [self initWithBookData:bookData];
}
- (id)initWithBookData:(NSDictionary *)bookData
{
    self = [super init];
    if (self && [self loadBookData:bookData]) {
        NSString *baseID = [self.title stringByAppendingFormat:@" %@", [self.url stringSHAEncoded]];
        self.ID = [self sanitizeForPath:baseID];

        NSLog(@"[BakerBook] 'book.json' parsed successfully. Book '%@' created with id '%@'.", self.title, self.ID);
        return self;
    }

    return nil;
}
- (NSString *)sanitizeForPath:(NSString *)string
{
    NSError *error = nil;
    NSString *newString;
    NSRegularExpression *regex;

    // Strip everything except numbers, ASCII letters and spaces
    regex = [NSRegularExpression regularExpressionWithPattern:@"[^1-9a-z ]" options:NSRegularExpressionCaseInsensitive error:&error];
    newString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];

    // Replace spaces with dashes
    regex = [NSRegularExpression regularExpressionWithPattern:@" +" options:NSRegularExpressionCaseInsensitive error:&error];
    newString = [regex stringByReplacingMatchesInString:newString options:0 range:NSMakeRange(0, [newString length]) withTemplate:@"-"];

    return [newString lowercaseString];
}
- (BOOL)loadBookData:(NSDictionary *)bookData
{
    if (![self validateBookJSON:bookData withRequirements:[NSArray arrayWithObjects:@"title", @"author", @"url", @"contents", nil]]) {
        return NO;
    }

    self.hpub  = [bookData objectForKey:@"hpub"];
    self.title = [bookData objectForKey:@"title"];
    self.date  = [bookData objectForKey:@"date"];

    if ([[bookData objectForKey:@"author"] isKindOfClass:[NSArray class]]) {
        self.author = [bookData objectForKey:@"author"];
    } else {
        self.author = [NSArray arrayWithObject:[bookData objectForKey:@"author"]];
    }

    if ([[bookData objectForKey:@"creator"] isKindOfClass:[NSArray class]]) {
        self.creator = [bookData objectForKey:@"creator"];
    } else if([[bookData objectForKey:@"creator"] isKindOfClass:[NSString class]]) {
        self.creator = [NSArray arrayWithObject:[bookData objectForKey:@"creator"]];
    }

    self.publisher = [bookData objectForKey:@"publisher"];

    self.url   = [bookData objectForKey:@"url"];
    self.cover = [bookData objectForKey:@"cover"];

    self.orientation = [bookData objectForKey:@"orientation"];
    self.zoomable    = [bookData objectForKey:@"zoomable"];

    // TODO: create an array of n BakerPage objects
    self.contents = [bookData objectForKey:@"contents"];

    self.bakerBackground               = [bookData objectForKey:@"-baker-background"];
    self.bakerBackgroundImagePortrait  = [bookData objectForKey:@"-baker-background-image-portrait"];
    self.bakerBackgroundImageLandscape = [bookData objectForKey:@"-baker-background-image-landscape"];
    self.bakerPageNumbersColor         = [bookData objectForKey:@"-baker-page-numbers-color"];
    self.bakerPageNumbersAlpha         = [bookData objectForKey:@"-baker-page-numbers-alpha"];
    self.bakerPageScreenshots          = [bookData objectForKey:@"-baker-page-screenshots"];

    self.bakerRendering          = [bookData objectForKey:@"-baker-rendering"];
    self.bakerVerticalBounce     = [bookData objectForKey:@"-baker-vertical-bounce"];
    self.bakerVerticalPagination = [bookData objectForKey:@"-baker-vertical-pagination"];
    self.bakerPageTurnTap        = [bookData objectForKey:@"-baker-page-turn-tap"];
    self.bakerPageTurnSwipe      = [bookData objectForKey:@"-baker-page-turn-swipe"];
    self.bakerMediaAutoplay      = [bookData objectForKey:@"-baker-media-autoplay"];

    self.bakerIndexWidth  = [bookData objectForKey:@"-baker-index-width"];
    self.bakerIndexHeight = [bookData objectForKey:@"-baker-index-height"];
    self.bakerIndexBounce = [bookData objectForKey:@"-baker-index-bounce"];
    self.bakerStartAtPage = [bookData objectForKey:@"-baker-start-at-page"];

    [self loadBookJSONDefault];

    return YES;
}
- (void)loadBookJSONDefault
{
    if (self.hpub == nil) {
        self.hpub = [NSNumber numberWithInt:1];
    }

    if (self.bakerBackground == nil) {
        self.bakerBackground = @"#000000";
    }
    if (self.bakerPageNumbersColor == nil) {
        self.bakerPageNumbersColor = @"#ffffff";
    }
    if (self.bakerPageNumbersAlpha == nil) {
        self.bakerPageNumbersAlpha = [NSNumber numberWithFloat:0.3];
    }

    if (self.bakerRendering == nil) {
        self.bakerRendering = @"screenshots";
    }
    if (self.bakerVerticalBounce == nil) {
        self.bakerVerticalBounce = [NSNumber numberWithBool:YES];
    }
    if (self.bakerVerticalPagination == nil) {
        self.bakerVerticalPagination = [NSNumber numberWithBool:NO];
    }

    if (self.bakerPageTurnTap == nil) {
        self.bakerPageTurnTap = [NSNumber numberWithBool:YES];
    }

    if (self.bakerPageTurnSwipe == nil) {
        self.bakerPageTurnSwipe = [NSNumber numberWithBool:YES];
    }
    if (self.bakerMediaAutoplay == nil) {
        self.bakerMediaAutoplay = [NSNumber numberWithBool:NO];
    }

    if (self.bakerIndexBounce == nil) {
        self.bakerIndexBounce = [NSNumber numberWithBool:NO];
    }
    if (self.bakerStartAtPage == nil) {
        self.bakerStartAtPage = [NSNumber numberWithInt:1];
    }
}


#pragma mark - HPub validation

- (BOOL)validateBookJSON:(NSDictionary *)bookData withRequirements:(NSArray *)requirements
{
    for (NSString *param in requirements) {
        if ([bookData objectForKey:param] == nil) {
            NSLog(@"[BakerBook] ERROR: param '%@' is missing. Add it to 'book.json'.", param);
            return NO;
        }
    }

    for (NSString *param in bookData) {
        //NSLog(@"[BakerBook] Validating 'book.json' param: '%@'.", param);

        id obj = [bookData objectForKey:param];
        if ([obj isKindOfClass:[NSArray class]] && ![self validateArray:(NSArray *)obj forParam:param]) {
            return NO;
        } else if ([obj isKindOfClass:[NSString class]] && ![self validateString:(NSString *)obj forParam:param]) {
            return NO;
        } else if ([obj isKindOfClass:[NSNumber class]] && ![self validateNumber:(NSNumber *)obj forParam:param]) {
            return NO;
        }
    }

    return YES;
}
- (BOOL)validateArray:(NSArray *)array forParam:(NSString *)param
{
    NSArray *shouldBeArray  = [NSArray arrayWithObjects:@"author",
                                                        @"creator",
                                                        @"contents", nil];


    if (![self matchParam:param againstParamsArray:shouldBeArray]) {
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
            if ([obj isKindOfClass:[NSDictionary class]] && ![self validateBookJSON:(NSDictionary *)obj withRequirements:[NSArray arrayWithObjects:@"url", nil]]) {
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
- (BOOL)validateString:(NSString *)string forParam:(NSString *)param
{
    NSArray *shouldBeString = [NSArray arrayWithObjects:@"title",
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
                                                        @"-baker-rendering", nil];


    if (![self matchParam:param againstParamsArray:shouldBeString]) {
        NSLog(@"[BakerBook] ERROR: param '%@' should not be a String. Check it in 'book.json'.", param);
        return NO;
    }

    if (([param isEqualToString:@"title"] || [param isEqualToString:@"author"] || [param isEqualToString:@"url"]) && [string isEqualToString:@""]) {
        NSLog(@"[BakerBook] ERROR: param '%@' is empty. Fill it in 'book.json'.", param);
        return NO;
    }

    if (([param isEqualToString:@"-baker-background"] || [param isEqualToString:@"-baker-page-numbers-color"]) /*&& TODO: not a valid hex*/) {
        // return NO;
    }

    if ([param isEqualToString:@"-baker-rendering"] && (![string isEqualToString:@"screenshots"] && ![string isEqualToString:@"three-cards"])) {
        NSLog(@"Error: param \"-baker-rendering\" should be equal to \"screenshots\" or \"three-cards\" but it's not");
        NSLog(@"[BakerBook] ERROR: param '-baker-rendering' must be equal to 'screenshots' or 'three-cards'. Check it in 'book.json'.");
        return NO;
    }

    return YES;
}
- (BOOL)validateNumber:(NSNumber *)number forParam:(NSString *)param
{
    NSArray *shouldBeNumber = [NSArray arrayWithObjects:@"hpub",
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
                                                        @"-baker-start-at-page", nil];


    if (![self matchParam:param againstParamsArray:shouldBeNumber]) {
        NSLog(@"[BakerBook] ERROR: param '%@' should not be a Number. Check it in 'book.json'.", param);
        return NO;
    }

    return YES;
}
- (BOOL)matchParam:(NSString *)param againstParamsArray:(NSArray *)paramsArray
{
    for (NSString *match in paramsArray) {
        if ([param isEqualToString:match]) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - Book status management

- (BOOL)updateBookPath:(NSString *)bookPath bundled:(BOOL)bundled
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:bookPath]) {
        return NO;
    }

    self.path = bookPath;
    self.isBundled = [NSNumber numberWithBool:bundled];

    self.screenshotsPath = [bookPath stringByAppendingPathComponent:self.bakerPageScreenshots];
    self.screenshotsWritable = [NSNumber numberWithBool:YES];

    if (bundled) {
        if (![fileManager fileExistsAtPath:self.screenshotsPath]) {
            // TODO: generate writableBookPath in app private documents/books/self.ID;
            NSString *writableBookPath = @"writableBookPath";
            self.screenshotsPath = [writableBookPath stringByAppendingPathComponent:self.bakerPageScreenshots];
        } else {
            self.screenshotsWritable = [NSNumber numberWithBool:NO];
        }
    }

    if (![fileManager fileExistsAtPath:self.screenshotsPath]) {
        return [fileManager createDirectoryAtPath:self.screenshotsPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return YES;
}
- (void)openBook
{
    // TODO: restore book status from app private documents/statuses/self.ID.json
}
- (void)closeBook
{
    // TODO: serialize with JSONKit and save in app private documents/statuses/self.ID.json
}

#pragma mark - Memory management

- (void)dealloc
{
    [hpub release];
    [title release];
    [date release];

    [author release];
    [creator release];
    [publisher release];

    [url release];
    [cover release];

    [orientation release];
    [zoomable release];

    [contents release];

    [bakerBackground release];
    [bakerBackgroundImagePortrait release];
    [bakerBackgroundImageLandscape release];
    [bakerPageNumbersColor release];
    [bakerPageNumbersAlpha release];
    [bakerPageScreenshots release];

    [bakerRendering release];
    [bakerVerticalBounce release];
    [bakerVerticalPagination release];
    [bakerPageTurnTap release];
    [bakerPageTurnSwipe release];
    [bakerMediaAutoplay release];

    [bakerIndexWidth release];
    [bakerIndexHeight release];
    [bakerIndexBounce release];
    [bakerStartAtPage release];

    [ID release];
    [path release];
    [isBundled release];
    [screenshotsPath release];
    [screenshotsWritable release];
    [currentPage release];
    [lastScrollIndex release];
    [lastOpenedDate release];

    [super dealloc];
}

@end
