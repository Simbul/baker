//
//  Properties.m
//  Baker
//
//  ==========================================================================================
//  
//  Copyright (c) 2011, Davide Casali, Marco Colombo, Alessandro Morandi
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

#import "Properties.h"
#import "JSONKit.h"


@implementation Properties

@synthesize manifest;
@synthesize defaults;

- (id)init {
    return [self initWithManifest:nil];
}

- (id)initWithManifest:(NSString *)fileName {
    self = [super init];
    if (self) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
        [self loadManifest:filePath];
        self.defaults = [self doInitDefaults];
    }
    return self;
}

- (id)get:(NSString *)rootName, ... {
    
    /****************************************************************************************************
     * Get the value for the specified property.
     * E.g. with a JSON like this:
     *   {
     *      "prop1": "value1",
     *      "nest":{
     *          "prop2": "value2"
     *      }
     *   }
     * 
     * Some calls could be:
     *   [get @"prop1", nil] // returns "value1"
     *   [get @"nest", "prop2", nil] // returns "value2"
     *
     * Remember to end the list of parameters with nil.
     */
    
    NSMutableArray *keys = [NSMutableArray array];
    va_list args;
    va_start(args, rootName);
    for (NSString *arg = rootName; arg != nil; arg = va_arg(args, NSString*)) {
        if ([arg isKindOfClass:[NSString class]]) {
            [keys addObject:arg];
        }
    }
    va_end(args);
    
    return [self getFrom:manifest withFallback:defaults withKeys:keys];
}

- (id)getFrom:(NSDictionary *)dictionary withFallback:(NSDictionary *)fallbackDictionary withKeys:(NSArray *)keys {
    id rootObj = [dictionary objectForKey:[keys objectAtIndex:0]];
    if (rootObj == nil) {
        return [self getFrom:fallbackDictionary withKeys:keys];
    } else {
        if ([rootObj isKindOfClass:[NSDictionary class]] ) {
            NSRange range = NSMakeRange(1, [keys count] - 1);
            id subDefaults = [defaults objectForKey:[keys objectAtIndex:0]];
            return [self getFrom:rootObj withFallback:subDefaults withKeys:[keys subarrayWithRange:range]];
        } else {
            return rootObj;
        }
    }
}

- (id)getFrom:(NSDictionary *)dictionary withKeys:(NSArray *)keys {
    id rootObj = [dictionary objectForKey:[keys objectAtIndex:0]];
    if ([rootObj isKindOfClass:[NSDictionary class]] ) {
        NSRange range = NSMakeRange(1, [keys count] - 1);
        return [self getFrom:rootObj withKeys:[keys subarrayWithRange:range]];
    } else {
        return rootObj;
    }
}

- (BOOL)loadManifest:(NSString *)filePath {
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        self.manifest = [self dictionaryFromManifestFile:filePath];
        return YES;
    } else {
        self.manifest = [NSDictionary dictionary];
        return NO;
    }
}

- (NSDictionary *)doInitDefaults {
    NSString *json = @"{"
    "\"orientation\": \"both\","
    "\"zoomable\": false,"
    "\"-baker-background\": \"#000000\","
    "\"-baker-vertical-bounce\": true,"
    "\"-baker-media-autoplay\": true,"
    "\"-baker-page-numbers-color\": \"#FFFFFF\","
    "\"-baker-page-numbers-alpha\": 0.3,"
    "\"-baker-index-width\": null,"
    "\"-baker-index-height\": null,"
    "\"-baker-index-bounce\": false,"
    "\"-baker-vertical-pagination\": false,"
    "\"-baker-rendering\": \"screenshots\","
    "\"-baker-page-turn-swipe\": true,"
    "\"-baker-page-turn-tap\": true"
    "}";
    NSError *e;
    return [[json objectFromJSONStringWithParseOptions:JKParseOptionNone error:&e] retain];
}

- (NSDictionary*)dictionaryFromManifestFile:(NSString*)filePath {
    
    /****************************************************************************************************
     * Reads a JSON file from Application Bundle to a NSDictionary.
     *
     * Requires TouchJSON with the inclusion of: #import "NSDictionary_JSONExtensions.h"
     *
     * Use normal NSDictionary and NSArray lookups to find elements.
     *   [json objectForKey:@"name"]
     *   [[json objectForKey:@"items"] objectAtIndex:1]
     */
    
    NSDictionary *ret = nil;
    
    if (filePath) {  
        NSString *fileJSON = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        
        NSError *e = nil;
        ret = [fileJSON objectFromJSONStringWithParseOptions:JKParseOptionNone error:&e];
        if ([e userInfo] != nil) {
            NSLog(@"Error loading JSON: %@", [e userInfo]);
        }
    }
    
    return ret;
}

#pragma mark - SINGLETON METHODS
static Properties *sharedProperties = nil;

+ (Properties *)properties
{
    if (sharedProperties == nil) {
        // Init singleton at most once per application
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedProperties = [[super allocWithZone:nil] init];
        });
    }
    return sharedProperties;
}
+ (id)allocWithZone:(NSZone *)zone
{
    return [[self properties] retain];
}
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}
- (id)retain
{
    return self;
}
- (NSUInteger)retainCount
{
    // Denotes an object that cannot be released
    return NSUIntegerMax;
}
- (oneway void)release
{
    // Do nothing
}
- (id)autorelease
{
    return self;
}

@end
