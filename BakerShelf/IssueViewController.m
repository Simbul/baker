//
//  IssueViewController.m
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

#import "IssueViewController.h"

@interface IssueViewController ()

@end

@implementation IssueViewController

@synthesize issue;

- (id)initWithBakerIssue:(BakerIssue *)bakerIssue {
    self = [super init];
    
    if (self) {
        self.issue = bakerIssue;
    }
    
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 384, 192)] autorelease];
    
    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    spinner.backgroundColor = [UIColor clearColor];
    spinner.center = CGPointMake(71, 96);
    [self.view addSubview:spinner];
    [spinner startAnimating];
    
    UILabel *title = [[[UILabel alloc]initWithFrame:CGRectMake(142, 21, 221, 25)] autorelease];
    title.text = self.issue.title;
    [self.view addSubview:title];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(142, 50, 221, 30);
    NSString *status = [self.issue getStatus];
    if (status == @"remote") {
        [button setTitle:@"Download" forState:UIControlStateNormal];
    } else if (status == @"downloaded" || status == @"bundled") {
        [button setTitle:@"View" forState:UIControlStateNormal];
    } else if (status == @"downloading") {
        [button setTitle:@"Downloading" forState:UIControlStateNormal];
    }
    [self.view addSubview:button];
    
    [self.issue getCover:^(UIImage *img) {
        UIImageView *thumb = [[[UIImageView alloc] initWithImage:img] autorelease];
        thumb.frame = CGRectMake(21, 21, 100, 150);
        [self.view addSubview:thumb];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [issue release];
    
    [super dealloc];
}

@end
