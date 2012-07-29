//
//  BakerBook.m
//  Sample Book
//
//  Created by Marco Colombo on 17/04/12.
//  Copyright (c) 2012 Marco Natale Colombo. All rights reserved.
//

#import "BakerBook.h"
#import "JSONKit.h"

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
    
    NSString *bookJSON = [NSString stringWithContentsOfFile:bookJSONPath encoding:NSUTF8StringEncoding error:nil];
    return [self initWithBookData:[bookJSON objectFromJSONString]];
}
- (id)initWithBookData:(NSDictionary *)bookData
{
    self = [super init];
    if (self && [self loadBookData:bookData]) {
        // TODO: generate book unique identifier
        self.ID = @"ID";
        
        NSLog(@"JSON Parsed successfully, book \"%@ - %@\" created", self.ID, self.title);
        return self;
    }
    
    return nil;
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
    } else {
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
    self.bakerPageNumbersColor         = [bookData objectForKey:@"-baker-page-number-color"];
    self.bakerPageNumbersAlpha         = [bookData objectForKey:@"-baker-page-number-alpha"];
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
    if (self.bakerPageScreenshots == nil) {
        self.bakerPageScreenshots = @"baker-screenshots";
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
            NSLog(@"Error: param \"%@\" is required but it's missing", param);
            return NO;
        }
    }
    
    for (NSString *param in bookData) {
        NSLog(@"Validating book JSON param \"%@\"", param);
        
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
        return NO;
    }
    
    if (([param isEqualToString:@"author"] || [param isEqualToString:@"contents"]) && [array count] == 0) {
        NSLog(@"Error: param \"%@\" is required but it's empty", param);
        return NO;
    }
    
    for (id obj in array) {
        if ([param isEqualToString:@"author"] && (![obj isKindOfClass:[NSString class]] || [(NSString *)obj isEqualToString:@""])) {
            NSLog(@"Error: param \"author\" is required but it's empty");
            return NO;
        } else if ([param isEqualToString:@"contents"]) {
            if ([obj isKindOfClass:[NSDictionary class]] && ![self validateBookJSON:(NSDictionary *)obj withRequirements:[NSArray arrayWithObjects:@"url", nil]]) {
                NSLog(@"Error: param \"contents\" is required but it's content doesn't validate");
                return NO;
            }
        } else if (![obj isKindOfClass:[NSString class]]) {
            NSLog(@"Error: param \"%@\" type is wrong", param);
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
                                                        @"-baker-page-number-color",
                                                        @"-baker-page-screenshots",
                                                        @"-baker-rendering", nil];
    
    
    if (![self matchParam:param againstParamsArray:shouldBeString]) {
        return NO;
    }
    
    if (([param isEqualToString:@"title"] || [param isEqualToString:@"author"] || [param isEqualToString:@"url"]) && [string isEqualToString:@""]) {
        NSLog(@"Error: param \"%@\" is required but it's empty", param);
        return NO;
    }
    
    if (([param isEqualToString:@"-baker-background"] || [param isEqualToString:@"-baker-page-number-color"]) /*&& TODO: not a valid hex*/) {
        // return NO;
    }
    
    if ([param isEqualToString:@"-baker-rendering"] && (![param isEqualToString:@"screenshots"] || ![param isEqualToString:@"three-cards"])) {
        NSLog(@"Error: param \"-baker-rendering\" should be equal to \"screenshots\" or \"three-cards\" but it's not");
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
    
    NSLog(@"Error: param \"%@\" type is wrong", param);
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
