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

#import "IssuesManager.h"
#import "BakerIssue.h"
#import "Utils.h"
#import "BakerAPI.h"
#import "NSObject+Extensions.h"

@implementation IssuesManager

- (id)init {
    self = [super init];

    if (self) {
        _issues            = nil;
        _shelfManifestPath = [self.cachePath stringByAppendingPathComponent:@"shelf.json"];
    }

    return self;
}

#pragma mark - Singleton

+ (IssuesManager*)sharedInstance {
    static dispatch_once_t once;
    static IssuesManager *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#ifdef BAKER_NEWSSTAND
- (void)refresh:(void (^)(BOOL))callback {
    [self getShelfJSON:^(NSData *json) {
        if (json) {
            NSError* error = nil;
            NSArray* jsonArr = [NSJSONSerialization JSONObjectWithData:json
                                                               options:0
                                                                 error:&error];
            
            [self updateNewsstandIssuesList:jsonArr];
            
            NSMutableArray *tmpIssues = [NSMutableArray array];
            [jsonArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                BakerIssue *issue = [[BakerIssue alloc] initWithIssueData:obj];
                [tmpIssues addObject:issue];
            }];
            
            self.issues = [tmpIssues sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
                NSDate *first = [Utils dateWithFormattedString:[(BakerIssue*)a date]];
                NSDate *second = [Utils dateWithFormattedString:[(BakerIssue*)b date]];
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
    
    #ifdef SET_NEWSSTAND_LATEST_ISSUE_COVER
        BakerIssue *latestIssue = nil;
        for (BakerIssue *issue in self.issues) {
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
    #else
        UIImage *image = [UIImage imageNamed:@"newsstand-app-icon"];
        [[UIApplication sharedApplication] setNewsstandIconImage:image];
    #endif
    
}

- (void)getShelfJSON:(void(^)(NSData*))callback {
    BakerAPI *api = [BakerAPI sharedInstance];
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
        NSDate *date = [Utils dateWithFormattedString:issue[@"date"]];
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
    for (BakerIssue *issue in self.issues) {
        if (issue.productID) {
            [set addObject:issue.productID];
        }
    }
    return set;
}

- (BOOL)hasProductIDs {
    return self.productIDs.count > 0;
}

- (BakerIssue*)latestIssue {
    return self.issues[0];
}
#endif

+ (NSArray*)localBooksList {
    NSMutableArray *booksList       = [NSMutableArray array];
    NSFileManager *localFileManager = [NSFileManager defaultManager];
    NSString *booksDir              = [[NSBundle mainBundle] pathForResource:@"books" ofType:nil];

    NSArray *dirContents = [localFileManager contentsOfDirectoryAtPath:booksDir error:nil];
    for (NSString *file in dirContents) {
        NSString *manifestFile = [booksDir stringByAppendingPathComponent:[file stringByAppendingPathComponent:@"book.json"]];
        if ([localFileManager fileExistsAtPath:manifestFile]) {
            BakerBook *book = [[BakerBook alloc] initWithBookPath:[booksDir stringByAppendingPathComponent:file] bundled:YES];
            if (book) {
                BakerIssue *issue = [[BakerIssue alloc] initWithBakerBook:book];
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
