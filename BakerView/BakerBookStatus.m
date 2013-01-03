//
//  BakerBookStatus.m
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

#import "BakerBookStatus.h"
#import "Utils.h"
#import "JSONKit.h"

@implementation BakerBookStatus

@synthesize page;
@synthesize scrollIndex;
@synthesize path;

- (id)initWithJSONPath:(NSString *)JSONPath
{
    self = [super init];

    if (self) {
        path = JSONPath;
        [self load];
    }

    return self;
}

- (void)load {
    NSError *error = nil;
    NSString *json = [NSString stringWithContentsOfFile:self.path encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error when loading book status: %@", error);
    }
    NSDictionary *jsonDict = [json objectFromJSONString];

    self.page        = [jsonDict objectForKey:@"page"];
    self.scrollIndex = [jsonDict objectForKey:@"scroll-index"];
}

- (void)save {
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObjectsAndKeys:page, @"page", scrollIndex, @"scroll-index", nil];
    NSString *json = [jsonDict JSONString];
    NSError *error = nil;

    NSString *dirPath = [path stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error when creating statuses folder: %@", error);
        }
        [Utils addSkipBackupAttributeToItemAtPath:dirPath];
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        [Utils addSkipBackupAttributeToItemAtPath:path];
    }

    [json writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error when saving book status: %@", error);
    }
}

- (void)dealloc {
    [path release];
    [page release];
    [scrollIndex release];

    [super dealloc];
}

@end
