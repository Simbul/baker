//
//  BakerBook.h
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

#import <Foundation/Foundation.h>

@interface BKRBook : NSObject

#pragma mark - HPub Parameters Properties

@property (nonatomic, strong) NSDictionary *bookData;
@property (copy, nonatomic) NSString *parseError;

@property (nonatomic, copy) NSNumber *hpub;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *date;

@property (nonatomic, copy) NSArray *author;
@property (nonatomic, copy) NSArray *creator;
@property (nonatomic, copy) NSArray *categories;
@property (nonatomic, copy) NSString *publisher;

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *cover;

@property (nonatomic, copy) NSString *orientation;
@property (nonatomic, copy) NSNumber *zoomable;

@property (nonatomic, strong) NSMutableArray *contents;

#pragma mark - Baker HPub Extensions Properties

@property (nonatomic, copy) NSString *bakerBackground;
@property (nonatomic, copy) NSString *bakerBackgroundImagePortrait;
@property (nonatomic, copy) NSString *bakerBackgroundImageLandscape;
@property (nonatomic, copy) NSString *bakerPageNumbersColor;
@property (nonatomic, copy) NSNumber *bakerPageNumbersAlpha;
@property (nonatomic, copy) NSString *bakerPageScreenshots;

@property (nonatomic, copy) NSString *bakerRendering;
@property (nonatomic, copy) NSNumber *bakerVerticalBounce;
@property (nonatomic, copy) NSNumber *bakerVerticalPagination;
@property (nonatomic, copy) NSNumber *bakerPageTurnTap;
@property (nonatomic, copy) NSNumber *bakerPageTurnSwipe;
@property (nonatomic, copy) NSNumber *bakerMediaAutoplay;

@property (nonatomic, copy) NSNumber *bakerIndexWidth;
@property (nonatomic, copy) NSNumber *bakerIndexHeight;
@property (nonatomic, copy) NSNumber *bakerIndexBounce;
@property (nonatomic, copy) NSNumber *bakerStartAtPage;

#pragma mark - Book Status Properties

@property (nonatomic, copy) NSString *ID;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSNumber *isBundled;
@property (nonatomic, copy) NSString *screenshotsPath;
@property (nonatomic, copy) NSNumber *screenshotsWritable;
@property (nonatomic, copy) NSNumber *currentPage;
@property (nonatomic, copy) NSNumber *lastScrollIndex;
@property (nonatomic, copy) NSDate *lastOpenedDate;

#pragma mark - Init

- (id)initWithBookPath:(NSString *)bookPath bundled:(BOOL)bundled;
- (id)initWithBookJSONPath:(NSString *)bookJSONPath;
- (id)initWithBookData:(NSDictionary *)bookData;
- (BOOL)loadBookData:(NSDictionary *)bookData;

#pragma mark - HPub validation

- (BOOL)isValid;
- (BOOL)validateBookJSON:(NSDictionary *)bookData withRequirements:(NSArray *)requirements;
- (BOOL)validateArray:(NSArray *)array forParam:(NSString *)param withParamsArray:(NSArray*)paramsArray;
- (BOOL)validateString:(NSString *)string forParam:(NSString *)param withParamsArray:(NSArray*)paramsArray;
- (BOOL)validateNumber:(NSNumber *)number forParam:(NSString *)param withParamsArray:(NSArray*)paramsArray;
- (BOOL)matchParam:(NSString *)param againstParamsArray:(NSArray *)paramsArray;

#pragma mark - Book status management

- (BOOL)updateBookPath:(NSString *)bookPath bundled:(BOOL)bundled;

@end
