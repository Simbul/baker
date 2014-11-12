//
//  IssuesManager.m
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

#import "BKRIssuesManager.h"
#import "BKRIssue.h"
#import "BKRUtils.h"
#import "BKRBakerAPI.h"
#import "BKRSettings.h"
#import "NSObject+BakerExtensions.h"

@implementation BKRIssuesManager

- (id)init {
    self = [super init];

    if (self) {
        _issues            = nil;
        _shelfManifestPath = [self.bkrCachePath stringByAppendingPathComponent:@"shelf.json"];
    }

    return self;
}

#pragma mark - Singleton

+ (BKRIssuesManager*)sharedInstance {
    static dispatch_once_t once;
    static BKRIssuesManager *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)refresh:(void (^)(BOOL))callback {
    [self getShelfJSON:^(NSData *json) {
        if (json) {
            NSError* error = nil;
            NSArray* jsonArr = [NSJSONSerialization JSONObjectWithData:json
                                                               options:0
                                                                 error:&error];
            
            [self updateNewsstandIssuesList:jsonArr];
            
            NSMutableArray *tmpIssues = [NSMutableArray array];
            NSMutableArray *tmpCategories = [NSMutableArray array];
            [jsonArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                BKRIssue *issue = [[BKRIssue alloc] initWithIssueData:obj];
                
                // Append categories
                [issue.categories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if(![tmpCategories containsObject:obj]) {
                        [tmpCategories addObject:obj];
                    }
                }];
                
                // Add issue to temporary issue list
                [tmpIssues addObject:issue];
            }];
            
            // Sort categories
            [tmpCategories sortUsingSelector:@selector(compare:)];
            _categories = tmpCategories;
            
            // Sort issues
            self.issues = [tmpIssues sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                NSDate *first = [BKRUtils dateWithFormattedString:[(BKRIssue*)a date]];
                NSDate *second = [BKRUtils dateWithFormattedString:[(BKRIssue*)b date]];
                return [second compare:first];
            }];
            
            [self updateNewsstandIcon];
            
            if (callback) {
                callback(YES);
            }
        }
        else {
            if (callback) {
                callback(NO);
            }
        }
    }];
}

- (void)updateNewsstandIcon {
    
    if ([BKRSettings sharedSettings].newsstandLatestIssueCover) {
        BKRIssue *latestIssue = nil;
        for (BKRIssue *issue in self.issues) {
            if ([[issue getStatus] isEqualToString:@"downloaded"]) {
                return;
            }
            latestIssue = issue;
            break;
        }

        NSLog(@"Setting newsstand cover icon from latest issue: %@ at %@", latestIssue.title, latestIssue.date);
        [latestIssue getCoverWithCache:YES andBlock:^(UIImage *image) {
            if (image) {
                [[UIApplication sharedApplication] setNewsstandIconImage:image];
            }
        }];
    } else {
        UIImage *image = [UIImage imageNamed:@"newsstand-app-icon"];
        [[UIApplication sharedApplication] setNewsstandIconImage:image];
    }
    
}

- (void)getShelfJSON:(void(^)(NSData*))callback {
    BKRBakerAPI *api = [BKRBakerAPI sharedInstance];
    [api getShelfJSON:^(NSData *json) {
        NSError *cachedShelfError = nil;
        
        if (json) {
            // Cache the shelf manifest
            [[NSFileManager defaultManager] createFileAtPath:self.shelfManifestPath contents:nil attributes:nil];
            NSError *error = nil;
            [json writeToFile:self.shelfManifestPath
                      options:NSDataWritingAtomic
                        error:&error];
            if (cachedShelfError) {
                NSLog(@"[BakerShelf] ERROR: Unable to cache 'shelf.json' manifest: %@", cachedShelfError);
            }
        } else {
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.shelfManifestPath]) {
                NSLog(@"[BakerShelf] Loading cached Shelf manifest from %@", self.shelfManifestPath);
                json = [NSData dataWithContentsOfFile:self.shelfManifestPath options:NSDataReadingMappedIfSafe error:&cachedShelfError];
                if (cachedShelfError) {
                    NSLog(@"[BakerShelf] Error loading cached copy of 'shelf.json': %@", cachedShelfError);
                }
            } else {
                NSLog(@"[BakerShelf] No cached 'shelf.json' manifest found at %@", self.shelfManifestPath);
                json = nil;
            }
        }
        
        if (callback) {
            callback(json);
        };
    }];
}

- (void)updateNewsstandIssuesList:(NSArray*)issuesList {
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NSMutableArray *discardedIssues = [NSMutableArray arrayWithArray:[nkLib issues]];

    for (NSDictionary *issue in issuesList) {
        NSDate *date = [BKRUtils dateWithFormattedString:issue[@"date"]];
        NSString *name = issue[@"name"];

        NKIssue *nkIssue = [nkLib issueWithName:name];
        if(!nkIssue) {
            // Add issue to Newsstand Library
            @try {
                nkIssue = [nkLib addIssueWithName:name date:date];
                NSLog(@"[BakerShelf] Newsstand - Added %@ %@", name, date);
            } @catch (NSException *exception) {
                NSLog(@"[BakerShelf] ERROR: Exception %@", exception);
            }
        } else {
            // Issue already in Newsstand Library
            [discardedIssues removeObject:nkIssue];
        }
    }

    for (NKIssue *discardedIssue in discardedIssues) {
        [nkLib removeIssue:discardedIssue];
        NSLog(@"[BakerShelf] Newsstand - Removed %@", discardedIssue.name);
    }
}

- (NSSet*)productIDs {
    NSMutableSet *set = [NSMutableSet set];
    for (BKRIssue *issue in self.issues) {
        if (issue.productID) {
            [set addObject:issue.productID];
        }
    }
    return set;
}

- (BOOL)hasProductIDs {
    return self.productIDs.count > 0;
}

- (BKRIssue*)latestIssue {
    return self.issues[0];
}

+ (NSArray*)localBooksList {
    NSMutableArray *booksList       = [NSMutableArray array];
    NSFileManager *localFileManager = [NSFileManager defaultManager];
    NSString *booksDir              = [[NSBundle mainBundle] pathForResource:@"books" ofType:nil];

    NSArray *dirContents = [localFileManager contentsOfDirectoryAtPath:booksDir error:nil];
    for (NSString *file in dirContents) {
        NSString *manifestFile = [booksDir stringByAppendingPathComponent:[file stringByAppendingPathComponent:@"book.json"]];
        if ([localFileManager fileExistsAtPath:manifestFile]) {
            BKRBook *book = [[BKRBook alloc] initWithBookPath:[booksDir stringByAppendingPathComponent:file] bundled:YES];
            if (book) {
                BKRIssue *issue = [[BKRIssue alloc] initWithBakerBook:book];
                [booksList addObject:issue];
            } else {
                NSLog(@"[BakerShelf] ERROR: Book %@ could not be initialized. Is 'book.json' correct and valid?", file);
            }
        } else {
            NSLog(@"[BakerShelf] ERROR: Cannot find 'book.json'. Is it present? Should be here: %@", manifestFile);
        }
    }

    return [NSArray arrayWithArray:booksList];
}

@end
