//
//  IssuesManager.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
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

@implementation IssuesManager

@synthesize issues;
@synthesize shelfManifestPath;

-(id)init {
    self = [super init];

    if (self) {
        self.issues = nil;

        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.shelfManifestPath = [cachePath stringByAppendingPathComponent:@"shelf.json"];
    }

    return self;
}

#pragma mark - Singleton

+ (IssuesManager *)sharedInstance {
    static dispatch_once_t once;
    static IssuesManager *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#ifdef BAKER_NEWSSTAND
-(BOOL)refresh {
    NSData *json = [self getShelfJSON];

    if (json) {
        NSError* error = nil;
        NSArray* jsonArr = [NSJSONSerialization JSONObjectWithData:json
                                                           options:0
                                                             error:&error];

        [self updateNewsstandIssuesList:jsonArr];

        NSMutableArray *tmpIssues = [NSMutableArray array];
        [jsonArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            BakerIssue *issue = [[[BakerIssue alloc] initWithIssueData:obj] autorelease];
            NSDate *issueDate = [Utils dateWithFormattedString[issue date]];
            if ([issueDate compare:[NSDate date]] == NSOrderedAscending)    // Don't add issues with future release date
                [tmpIssues addObject:issue];
        }];

        self.issues = [tmpIssues sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [Utils dateWithFormattedString:[(BakerIssue*)a date]];
            NSDate *second = [Utils dateWithFormattedString:[(BakerIssue*)b date]];
            return [second compare:first];
        }];

        return YES;
    } else {
        NSLog(@"[BakerShelf] ERROR: 'shelf.json' is missing. Add URL to 'NEWSSTAND_MANIFEST_URL' in Constants.h");
        return NO;
    }
}

-(NSData *)getShelfJSON {
    BakerAPI *api = [BakerAPI sharedInstance];
    NSData *json = [api getShelfJSON];

    NSError *cachedShelfError = nil;

    if (json) {
        // Cache the shelf manifest
        [[NSFileManager defaultManager] createFileAtPath:self.shelfManifestPath contents:nil attributes:nil];
        [json writeToFile:self.shelfManifestPath
                  options:NSDataWritingAtomic
                    error:&cachedShelfError];
        if (cachedShelfError) {
            NSLog(@"[BakerShelf] ERROR: Unable to cache 'shelf.json' manifest: %@", cachedShelfError);
        }
    } else {
        // Can't download it... Let's try to load it from previously cached version...
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.shelfManifestPath]) {
            NSLog(@"[BakerShelf] Loading cached Shelf manifest from %@", self.shelfManifestPath);
            json = [NSData dataWithContentsOfFile:self.shelfManifestPath options:NSDataReadingMappedIfSafe error:&cachedShelfError];
            if (cachedShelfError) {
                NSLog(@"[BakerShelf] Error loading cached copy of 'shelf.json': %@", cachedShelfError);
            }
        } else {
            // Not even in cache. Bad luck.
            NSLog(@"[BakerShelf] No cached 'shelf.json' manifest found at %@", self.shelfManifestPath);
            json = nil;
        }
    }

    return json;
}

-(void)updateNewsstandIssuesList:(NSArray *)issuesList {
    NKLibrary *nkLib = [NKLibrary sharedLibrary];

    for (NSDictionary *issue in issuesList) {
        NSDate *date = [Utils dateWithFormattedString:[issue objectForKey:@"date"]];
        NSString *name = [issue objectForKey:@"name"];

        // Only add issue if the publish date has already passed (ignore issues from the future)
        if ([date compare:[NSDate date]] == NSOrderedAscending) {
            NKIssue *nkIssue = [nkLib issueWithName:name];
            if(!nkIssue) {
                @try {
                    nkIssue = [nkLib addIssueWithName:name date:date];
                    NSLog(@"[BakerShelf] Newsstand - Added %@ %@", name, date);
                } @catch (NSException *exception) {
                    NSLog(@"[BakerShelf] ERROR: Exception %@", exception);
                }
            }
        }
    }
}

-(NSSet *)productIDs {
    NSMutableSet *set = [NSMutableSet set];
    for (BakerIssue *issue in self.issues) {
        if (issue.productID) {
            [set addObject:issue.productID];
        }
    }
    return set;
}

- (BOOL)hasProductIDs {
    return [[self productIDs] count] > 0;
}

- (BakerIssue *)latestIssue {
    return [issues objectAtIndex:0];
}
#endif

+ (NSArray *)localBooksList {
    NSMutableArray *booksList = [NSMutableArray array];
    NSFileManager *localFileManager = [NSFileManager defaultManager];
    NSString *booksDir = [[NSBundle mainBundle] pathForResource:@"books" ofType:nil];

    NSArray *dirContents = [localFileManager contentsOfDirectoryAtPath:booksDir error:nil];
    for (NSString *file in dirContents) {
        NSString *manifestFile = [booksDir stringByAppendingPathComponent:[file stringByAppendingPathComponent:@"book.json"]];
        if ([localFileManager fileExistsAtPath:manifestFile]) {
            BakerBook *book = [[[BakerBook alloc] initWithBookPath:[booksDir stringByAppendingPathComponent:file] bundled:YES] autorelease];
            if (book) {
                BakerIssue *issue = [[[BakerIssue alloc] initWithBakerBook:book] autorelease];
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

-(void)dealloc {
    [issues release];
    [shelfManifestPath release];

    [super dealloc];
}

@end
