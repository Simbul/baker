//
//  BKRSettings.h
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2014, Pieter Claerhout
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

//
//  !! IMPORTANT !!
//  DO NOT ALTER THIS FILE. SETTINGS ARE DEFINED IN SETTINGS.PLIST INSTEAD!
//  !! IMPORTANT !!
//

#import "BKRSettings.h"

#pragma mark - Private

@interface BKRSettings ()

@property (nonatomic, readonly) NSDictionary *settings;

@end

@implementation BKRSettings

#pragma mark - Shared Instance

+ (BKRSettings*)sharedSettings {
    static BKRSettings *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

#pragma mark - Instance Methods

- (id)init {
    self = [super init];
    if (self) {
        
        NSString *settingsPath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:settingsPath]) {
            _settings = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
        } else {
            _settings = @{};
        }
        
        NSLog(@"Settings: %@", _settings);

        _requestTimeout                      = [self doubleSettingForKey:@"requestTimeout" withDefault:15];
        _isNewsstand                         = [self boolSettingForKey:@"isNewsstand" withDefault:YES];
        _newsstandLatestIssueCover           = [self boolSettingForKey:@"newsstandLatestIssueCover" withDefault:YES];
        
        _newsstandManifestUrl                = [self stringSettingForKey:@"newsstandManifestUrl" withDefault:@"http://bakerframework.com/demo/shelf.json"];
        _purchaseConfirmationUrl             = [self stringSettingForKey:@"purchaseConfirmationUrl" withDefault:@""];
        _purchasesUrl                        = [self stringSettingForKey:@"purchasesUrl" withDefault:@""];
        _postApnsTokenUrl                    = [self stringSettingForKey:@"postApnsTokenUrl" withDefault:@""];
        _freeSubscriptionProductId           = [self stringSettingForKey:@"freeSubscriptionProductId" withDefault:@""];
        _autoRenewableSubscriptionProductIds = [self arraySettingForKey:@"autoRenewableSubscriptionProductIds" withDefault:@[]];

        _issuesCoverBackgroundColor          = [self stringSettingForKey:@"issuesCoverBackgroundColor" withDefault:@"#ffffff"];

        _issuesTitleFont                     = [self stringSettingForKey:@"issuesTitleFont" withDefault:@"Helvetica"];
        _issuesTitleFontSize                 = [self intSettingForKey:@"issuesTitleFontSize" withDefault:15];
        _issuesTitleColor                    = [self stringSettingForKey:@"issuesTitleColor" withDefault:@"#000000"];

        _issuesInfoFont                      = [self stringSettingForKey:@"issuesInfoFont" withDefault:@"Helvetica"];
        _issuesInfoFontSize                  = [self intSettingForKey:@"issuesInfoFontSize" withDefault:15];
        _issuesInfoColor                     = [self stringSettingForKey:@"issuesInfoColor" withDefault:@"#929292"];
        
        _issuesPriceColor                    = [self stringSettingForKey:@"issuesPriceColor" withDefault:@"#bc242a"];

        _issuesActionFont                    = [self stringSettingForKey:@"issuesActionFont" withDefault:@"Helvetica-Bold"];
        _issuesActionFontSize                = [self intSettingForKey:@"issuesActionFontSize" withDefault:11];
        _issuesActionBackgroundColor         = [self stringSettingForKey:@"issuesActionBackgroundColor" withDefault:@"#bc242a"];
        _issuesActionButtonColor             = [self stringSettingForKey:@"issuesActionButtonColor" withDefault:@"#ffffff"];

        _issuesArchiveFont                   = [self stringSettingForKey:@"issuesArchiveFont" withDefault:@"Helvetica-Bold"];
        _issuesArchiveFontSize               = [self intSettingForKey:@"issuesArchiveFontSize" withDefault:11];
        _issuesArchiveBackgroundColor        = [self stringSettingForKey:@"issuesArchiveBackgroundColor" withDefault:@"#bc242a"];
        _issuesArchiveButtonColor            = [self stringSettingForKey:@"issuesArchiveButtonColor" withDefault:@"#ffffff"];

        _issuesLoadingLabelColor             = [self stringSettingForKey:@"issuesLoadingLabelColor" withDefault:@"#bc242a"];
        _issuesLoadingSpinnerColor           = [self stringSettingForKey:@"issuesLoadingSpinnerColor" withDefault:@"#929292"];

        _issuesProgressbarTintColor          = [self stringSettingForKey:@"issuesProgressbarTintColor" withDefault:@"#bc242a"];
        
        _issuesShelfOptions                  = [self dictionarySettingForKey:@"issuesShelfOptions" withDefault:@{}];
    
    }
    return self;
}

#pragma mark - Helpers

- (NSString*)stringSettingForKey:(NSString*)setting withDefault:(NSString*)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [self.settings objectForKey:setting];
    } else {
        return defaultValue;
    }
}

- (NSDictionary*)dictionarySettingForKey:(NSString*)setting withDefault:(NSDictionary*)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [self.settings objectForKey:setting];
    } else {
        return defaultValue;
    }
}

- (NSArray*)arraySettingForKey:(NSString*)setting withDefault:(NSArray*)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [self.settings objectForKey:setting];
    } else {
        return defaultValue;
    }
}

- (NSDate*)dateSettingForKey:(NSString*)setting withDefault:(NSDate*)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [self.settings objectForKey:setting];
    } else {
        return defaultValue;
    }
}

- (NSNumber*)numberSettingForKey:(NSString*)setting withDefault:(NSNumber*)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [self.settings objectForKey:setting];
    } else {
        return defaultValue;
    }
}

- (BOOL)boolSettingForKey:(NSString*)setting withDefault:(BOOL)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [[self.settings objectForKey:setting] boolValue];
    } else {
        return defaultValue;
    }
}

- (int)intSettingForKey:(NSString*)setting withDefault:(int)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [[self.settings objectForKey:setting] intValue];
    } else {
        return defaultValue;
    }
}

- (double)doubleSettingForKey:(NSString*)setting withDefault:(double)defaultValue {
    if (self.settings && [self.settings objectForKey:setting]) {
        return [[self.settings objectForKey:setting] doubleValue];
    } else {
        return defaultValue;
    }
}

@end
