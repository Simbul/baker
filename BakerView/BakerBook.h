//
//  BakerBook.h
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
