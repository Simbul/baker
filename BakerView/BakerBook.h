//
//  BakerBook.h
//  Sample Book
//
//  Created by Marco Colombo on 17/04/12.
//  Copyright (c) 2012 Marco Natale Colombo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BakerBook : NSObject

#pragma mark - HPub Parameters Properties

@property (copy, nonatomic) NSNumber *hpub;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *date;

@property (copy, nonatomic) NSArray *author;
@property (copy, nonatomic) NSArray *creator;
@property (copy, nonatomic) NSString *publisher;

@property (copy, nonatomic) NSString *url;
@property (copy, nonatomic) NSString *cover;

@property (copy, nonatomic) NSString *orientation;
@property (copy, nonatomic) NSNumber *zoomable;

@property (strong, nonatomic) NSMutableArray *contents;

#pragma mark - Baker HPub Extensions Properties

@property (copy, nonatomic) NSString *bakerBackground;
@property (copy, nonatomic) NSString *bakerBackgroundImagePortrait;
@property (copy, nonatomic) NSString *bakerBackgroundImageLandscape;
@property (copy, nonatomic) NSString *bakerPageNumbersColor;
@property (copy, nonatomic) NSNumber *bakerPageNumbersAlpha;
@property (copy, nonatomic) NSString *bakerPageScreenshots;

@property (copy, nonatomic) NSString *bakerRendering;
@property (copy, nonatomic) NSNumber *bakerVerticalBounce;
@property (copy, nonatomic) NSNumber *bakerVerticalPagination;
@property (copy, nonatomic) NSNumber *bakerPageTurnTap;
@property (copy, nonatomic) NSNumber *bakerPageTurnSwipe;
@property (copy, nonatomic) NSNumber *bakerMediaAutoplay;

@property (copy, nonatomic) NSNumber *bakerIndexWidth;
@property (copy, nonatomic) NSNumber *bakerIndexHeight;
@property (copy, nonatomic) NSNumber *bakerIndexBounce;
@property (copy, nonatomic) NSNumber *bakerStartAtPage;

#pragma mark - Book Status Properties

@property (copy, nonatomic) NSString *ID;
@property (copy, nonatomic) NSString *path;
@property (copy, nonatomic) NSNumber *isBundled;
@property (copy, nonatomic) NSString *screenshotsPath;
@property (copy, nonatomic) NSNumber *screenshotsWritable;
@property (copy, nonatomic) NSNumber *currentPage;
@property (copy, nonatomic) NSNumber *lastScrollIndex;
@property (copy, nonatomic) NSDate *lastOpenedDate;

#pragma mark - Init

- (id)initWithBookPath:(NSString *)bookPath bundled:(BOOL)bundled;
- (id)initWithBookJSONPath:(NSString *)bookJSONPath;
- (id)initWithBookData:(NSDictionary *)bookData;
- (BOOL)loadBookData:(NSDictionary *)bookData;

#pragma mark - HPub validation

- (BOOL)validateBookJSON:(NSDictionary *)bookData withRequirements:(NSArray *)requirements;
- (BOOL)validateArray:(NSArray *)array forParam:(NSString *)param;
- (BOOL)validateString:(NSString *)string forParam:(NSString *)param;
- (BOOL)validateNumber:(NSNumber *)number forParam:(NSString *)param;
- (BOOL)matchParam:(NSString *)param againstParamsArray:(NSArray *)paramsArray;

#pragma mark - Book status management

- (BOOL)updateBookPath:(NSString *)bookPath bundled:(BOOL)bundled;
- (void)openBook;
- (void)closeBook;

@end
