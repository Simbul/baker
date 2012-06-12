//
//  PropertiesTest.m
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

#import "PropertiesTest.h"
#import "Properties.h"


@implementation PropertiesTest

- (void)testGetMultiArgs {
    
    Properties *properties = [[Properties alloc]init];
    id property = [properties get:@"one", @"two", @"three", nil];
    STAssertNil(property, @"Should not find non existing property");
    
}

- (void)testFallbackFrom {
    NSArray *objects = [NSArray arrayWithObjects:@"blah", nil];
    NSArray *keys = [NSArray arrayWithObjects:@"string", nil];
    NSDictionary *fbDict = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    NSDictionary *dict = [[NSDictionary alloc] init];
    
    Properties *properties = [[Properties alloc]init];
    id property = [properties getFrom:dict withFallback:fbDict withKeys:keys];
    STAssertEquals(property, @"blah", @"Should return the fallback item");
}

- (void)testGetSimpleTypesFrom {
    NSArray *objects = [NSArray arrayWithObjects:
                        @"blah",
                        [[NSNumber alloc] initWithInteger:1],
                        [NSNumber numberWithBool:YES],
                        [NSArray arrayWithObjects:@"one", @"two", nil],
                        nil];
    NSArray *keys = [NSArray arrayWithObjects:
                     @"string",
                     @"number",
                     @"boolean",
                     @"array",
                     nil];
    NSDictionary *dict = [[NSDictionary alloc] initWithObjects:objects forKeys:keys];
    
    Properties *properties = [[Properties alloc]init];
    id property;
    NSArray *queryKeys;
    
    queryKeys = [NSArray arrayWithObjects:@"string", nil];
    property = [properties getFrom:dict withKeys:queryKeys];
    STAssertEqualObjects(property, @"blah", @"Should return a string");
    
    queryKeys = [NSArray arrayWithObjects:@"number", nil];
    property = [properties getFrom:dict withKeys:queryKeys];
    STAssertEqualObjects(property, [[NSNumber alloc] initWithInteger:1], @"Should return a number");
    
    queryKeys = [NSArray arrayWithObjects:@"boolean", nil];
    property = [properties getFrom:dict withKeys:queryKeys];
    STAssertEquals([property boolValue], YES, @"Should return an int corresponding to a boolean");
    
    queryKeys = [NSArray arrayWithObjects:@"array", nil];
    property = [properties getFrom:dict withKeys:queryKeys];
    STAssertEquals(property, [objects objectAtIndex:3], @"Should return an int corresponding to an array");
}

- (void)testDefaults {
    Properties *properties = [[Properties alloc]init];
    id property;
    
    property = [properties get:@"orientation", nil];
    STAssertEqualObjects(property, @"both", @"Should return expected default value for orientation");
    
    property = [properties get:@"zoomable", nil];
    STAssertEquals([property boolValue], NO, @"Should return expected default value for zoomable");
    
    property = [properties get:@"-baker-background", nil];
    STAssertEqualObjects(property, @"#000000", @"Should return expected default value for -baker-background");
    
    property = [properties get:@"-baker-vertical-bounce", nil];
    STAssertEquals([property boolValue], YES, @"Should return expected default value for -baker-vertical-bounce");
    
    property = [properties get:@"-baker-page-numbers-color", nil];
    STAssertEqualObjects(property, @"#FFFFFF", @"Should return expected default value for -baker-page-numbers-color");
    
    property = [properties get:@"-baker-page-numbers-alpha", nil];
    STAssertEqualObjects(property, [NSDecimalNumber decimalNumberWithString:@"0.3"], @"Should return expected default value for -baker-page-numbers-alpha");
    
    property = [properties get:@"-baker-media-autoplay", nil];
    STAssertEquals([property boolValue], YES, @"Should return expected default value for -baker-media-autoplay");
    
    property = [properties get:@"-baker-index-height", nil];
    STAssertEquals(property, [NSNull null], @"Should return expected default value for -baker-index-height");
    
    property = [properties get:@"-baker-index-bounce", nil];
    STAssertEquals([property boolValue], NO, @"Should return expected default value for -baker-index-bounce");
    
    property = [properties get:@"-baker-vertical-pagination", nil];
    STAssertEquals([property boolValue], NO, @"Should return expected default value for -baker-vertical-pagination");
}

@end
