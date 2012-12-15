//
//  IssuesManager.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2012, Davide Casali, Marco Colombo, Alessandro Morandi
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

#import "JSONKit.h"

@implementation IssuesManager

@synthesize url;
@synthesize issues;
@synthesize shelfManifestPath;

-(id)initWithURL:(NSString *)urlString {
    self = [super init];

    if (self) {
        self.url = [NSURL URLWithString:urlString];
        self.issues = nil;

        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.shelfManifestPath = [cachePath stringByAppendingPathComponent:@"shelf.json"];
    }

    return self;
}

#ifdef BAKER_NEWSSTAND
-(BOOL)refresh {
    NSString *json = [self getShelfJSON];

    if (json) {
        NSArray *jsonArr = [json objectFromJSONString];

        [self updateNewsstandIssuesList:jsonArr];

        NSMutableArray *tmpIssues = [NSMutableArray array];
        [jsonArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            BakerIssue *issue = [[[BakerIssue alloc] initWithIssueData:obj] autorelease];
            [tmpIssues addObject:issue];
        }];

        // Issues are sorted from the most recent to the least recent
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        self.issues = [tmpIssues sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSDate *first = [dateFormat dateFromString:[(BakerIssue*)a date]];
            NSDate *second = [dateFormat dateFromString:[(BakerIssue*)b date]];
            return [second compare:first];
        }];
        return YES;
    } else {
        return NO;
    }
}

-(NSString *)getShelfJSON {
    NSError *error = nil;
    NSString *json = nil;

    json = [NSString stringWithContentsOfURL:self.url encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error loading Shelf manifest: %@", error);
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.shelfManifestPath]) {
            NSLog(@"Loading cached Shelf manifest from %@", self.shelfManifestPath);
            json = [NSString stringWithContentsOfFile:self.shelfManifestPath encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                NSLog(@"Error loading cached Shelf manifest: %@", error);
            }
        } else {
            NSLog(@"No cached Shelf manifest found at %@", self.shelfManifestPath);
            json = nil;
        }
    } else {
        // Cache the shelf manifest
        [[NSFileManager defaultManager] createFileAtPath:self.shelfManifestPath contents:nil attributes:nil];
        [json writeToFile:self.shelfManifestPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            NSLog(@"Error caching Shelf manifest: %@", error);
        } else {
            [Utils addSkipBackupAttributeToItemAtPath:self.shelfManifestPath];
        }
    }

    return json;
}

-(void)updateNewsstandIssuesList:(NSArray *)issuesList {
    NKLibrary *nkLib = [NKLibrary sharedLibrary];

    for (NSDictionary *issue in issuesList) {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date = [dateFormat dateFromString:[issue objectForKey:@"date"]];
        NSString *name = [issue objectForKey:@"name"];

        NKIssue *nkIssue = [nkLib issueWithName:name];
        if(!nkIssue) {
            @try {
                nkIssue = [nkLib addIssueWithName:name date:date];
                NSLog(@"added %@ %@", name, date);
            } @catch (NSException *exception) {
                NSLog(@"EXCEPTION %@", exception);
            }

        }
        [dateFormat release];
    }
}
#endif

-(void)dealloc {
    [issues release];
    [url release];

    [super dealloc];
}

@end
