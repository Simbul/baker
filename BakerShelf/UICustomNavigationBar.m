//
//  UICustomNavigationBar.m
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

#import "UICustomNavigationBar.h"

@implementation UICustomNavigationBar

- (void)dealloc
{
    [backgroundImages release];
    [backgroundImageView release];

    [super dealloc];
}

- (NSMutableDictionary *)backgroundImages
{
    if (!backgroundImages) {
        backgroundImages = [[NSMutableDictionary alloc] init];
    }
    return backgroundImages;
}
- (UIImageView *)backgroundImageView
{
    if (!backgroundImageView) {
        backgroundImageView = [[UIImageView alloc] initWithFrame:[self bounds]];
        [backgroundImageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self insertSubview:backgroundImageView atIndex:0];
    }
    return backgroundImageView;
}
- (void)setBackgroundImage:(UIImage *)backgroundImage forBarMetrics:(UIBarMetrics)barMetrics
{
    if ([UINavigationBar instancesRespondToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [super setBackgroundImage:backgroundImage forBarMetrics:barMetrics];
    } else {
        [[self backgroundImages] setObject:backgroundImage forKey:[NSNumber numberWithInt:barMetrics]];
        [self updateBackgroundImage];
    }
}
- (void)updateBackgroundImage
{
    UIBarMetrics metrics = UIBarMetricsLandscapePhone;
    if ([self bounds].size.height > 40) {
        metrics = UIBarMetricsDefault;
    }

    UIImage *image = [[self backgroundImages] objectForKey:[NSNumber numberWithInt:metrics]];
    if (!image && metrics != UIBarMetricsDefault) {
        image = [[self backgroundImages] objectForKey:[NSNumber numberWithInt:UIBarMetricsDefault]];
    }

    if (image) {
        [[self backgroundImageView] setImage:image];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (backgroundImageView) {
        [self updateBackgroundImage];
        [self sendSubviewToBack:backgroundImageView];
    }
}

@end
