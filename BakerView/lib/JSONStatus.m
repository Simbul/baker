//
//  JSONStatus.m
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

#import "JSONStatus.h"
#import "Utils.h"

@implementation JSONStatus

@synthesize path;

- (id)initWithJSONPath:(NSString *)JSONPath
{
    self = [super init];

    if (self) {
        path = [JSONPath retain];
        [self createFileIfMissing];
        [self load];
    }

    return self;
}

- (NSDictionary *)load {
    NSError *error = nil;
    NSData* json = [NSData dataWithContentsOfFile:self.path options:0 error:&error];
    if (error) {
        NSLog(@"[JSONStatus] Error when loading JSON status: %@", error);
    }
    NSDictionary* retv = [NSJSONSerialization JSONObjectWithData:json
                                                         options:0
                                                           error:&error];
    // TODO: deal with error
    return retv;
}

- (void)save:(NSDictionary *)status {
    NSError* error = nil;
    NSData* json = [NSJSONSerialization dataWithJSONObject:status
                                                   options:0
                                                     error:&error];
    // TODO: deal with error

    [json writeToFile:path options:NSDataWritingAtomic error:&error];

    if (error) {
        NSLog(@"[JSONStatus] Error when saving JSON status: %@", error);
    }
}

- (void)createFileIfMissing {
    NSError *error = nil;

    NSString *dirPath = [path stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"[JSONStatus] Error when creating JSON status folder: %@", error);
        }
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        if (![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil]) {
            NSLog(@"[JSONStatus] JSON status file could not be created at %@", path);
        }

    }
}

- (void)dealloc {
    [path release];

    [super dealloc];
}

@end
