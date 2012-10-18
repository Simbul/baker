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

#import <QuartzCore/QuartzCore.h>

#import "IssueViewController.h"
#import "SSZipArchive.h"

#import "UIColor+Extensions.h"

#define ACTION_REMOTE_TEXT @"DOWNLOAD"
#define ACTION_DOWNLOADED_TEXT @"READ"
#define ARCHIVE_TEXT @"ARCHIVE"

#define DOWNLOADING_TEXT @"DOWNLOADING ..."
#define OPENING_TEXT @"Loading..."

@implementation IssueViewController

#pragma mark - Synthesis

@synthesize issue;
@synthesize actionButton;
@synthesize archiveButton;
@synthesize progressBar;
@synthesize spinner;
@synthesize loadingLabel;

#pragma mark - Init

- (id)initWithBakerIssue:(BakerIssue *)bakerIssue
{
    self = [super init];
    if (self) {
        self.issue = bakerIssue;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)loadView
{
    [super loadView];
    
    self.view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 384, 240)] autorelease];
    
    // SETUP COVER IMAGE
    [self.issue getCover:^(UIImage *image) {
        UIImageView *issueCover = [[[UIImageView alloc] initWithImage:image] autorelease];
        
        issueCover.frame = CGRectMake(30, 30, 135, 180);
        issueCover.layer.shadowOpacity = 0.5;
        issueCover.layer.shadowOffset = CGSizeMake(0, 2);
        issueCover.layer.shouldRasterize = YES;
        
        [self.view addSubview:issueCover];
    }];
    
    
    int heightOffset = 30;

    
    // SETUP USED FONTS
    UIFont *textFont = [UIFont fontWithName:@"Helvetica" size:15];
    uint textLineheight = [@"The brown fox jumps over the lazy dog" sizeWithFont:textFont constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT)].height;
    
    UIFont *actionFont = [UIFont fontWithName:@"Helvetica-Bold" size:11];
        
    
    // SETUP TITLE LABEL
    CGSize titleSize = [self.issue.title sizeWithFont:textFont constrainedToSize:CGSizeMake(170, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    uint titleLines = MIN(4, titleSize.height / textLineheight);
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(184, heightOffset, 170, textLineheight * titleLines)];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    titleLabel.textAlignment = UITextAlignmentLeft;
    titleLabel.numberOfLines = titleLines;
    titleLabel.text = self.issue.title;
    titleLabel.font = textFont;
    
    [self.view addSubview:titleLabel];
    [titleLabel release];
    
    heightOffset = heightOffset + titleLabel.frame.size.height + 5;

    
    // SETUP INFO LABEL
    CGSize infoSize = [self.issue.info sizeWithFont:textFont constrainedToSize:CGSizeMake(170, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    uint infoLines = MIN(4, infoSize.height / textLineheight);
    
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(184, heightOffset, 170, textLineheight * infoLines)];
    infoLabel.textColor = [UIColor colorWithHexString:@"#929292"];
    infoLabel.lineBreakMode = UILineBreakModeTailTruncation;
    infoLabel.textAlignment = UITextAlignmentLeft;
    infoLabel.numberOfLines = infoLines;
    infoLabel.text = self.issue.info;
    infoLabel.font = textFont;
    
    [self.view addSubview:infoLabel];
    [infoLabel release];

    heightOffset = heightOffset + infoLabel.frame.size.height + 10;
    
    
    // SETUP ACTION BUTTON
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(184, heightOffset, 80, 30);
    actionButton.backgroundColor = [UIColor colorWithHexString:@"#b72529"];
    actionButton.titleLabel.font = actionFont;
    
    [actionButton setTitle:ACTION_DOWNLOADED_TEXT forState:UIControlStateNormal];
    [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:actionButton];
    
        
    // SETUP ARCHIVE BUTTON
    self.archiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    archiveButton.frame = CGRectMake(274, heightOffset, 80, 30);
    archiveButton.backgroundColor = [UIColor clearColor];
    archiveButton.titleLabel.font = actionFont;
    
    [archiveButton setTitle:ARCHIVE_TEXT forState:UIControlStateNormal];
    [archiveButton setTitleColor:[UIColor colorWithHexString:@"#b72529"] forState:UIControlStateNormal];
    [archiveButton addTarget:self action:@selector(archiveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    #ifdef BAKER_NEWSSTAND
    [self.view addSubview:archiveButton];
    #endif
    
    
    // SETUP DOWN/LOADING SPINNER AND LABEL
    self.spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    spinner.frame = CGRectMake(180, heightOffset, 30, 30);
    spinner.hidesWhenStopped = YES;
    
    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(215, heightOffset, 135, 30)];
    loadingLabel.textColor = [UIColor colorWithHexString:@"#b72529"];
    loadingLabel.textAlignment = UITextAlignmentLeft;
    loadingLabel.text = DOWNLOADING_TEXT;
    loadingLabel.font = actionFont;
    
    [self.view addSubview:spinner];
    [self.view addSubview:loadingLabel];
    
    heightOffset = heightOffset + self.loadingLabel.frame.size.height + 5;
    
    
    // SETUP PROGRESS BAR
    self.progressBar = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar] autorelease];
    self.progressBar.frame = CGRectMake(184, heightOffset, 170, 30);
    
    [self.view addSubview:progressBar];
}
- (void)refresh
{
    [self refresh:[self.issue getStatus]];
}
- (void)refresh:(NSString *)status
{
    NSLog(@"Refreshing %@ view with status %@", self.issue.ID, status);
    if ([status isEqualToString:@"remote"]) {
        [self.actionButton setTitle:ACTION_REMOTE_TEXT forState:UIControlStateNormal];
        [self.spinner stopAnimating];
        self.actionButton.frame = CGRectMake(184, self.actionButton.frame.origin.y, 110, 30);
        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.progressBar.hidden = YES;
        self.loadingLabel.hidden = YES;
    } else if ([status isEqualToString:@"downloading"]) {
        [self.spinner startAnimating];
        self.progressBar.hidden = NO;
        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.progressBar.progress = 0;
        self.loadingLabel.text = DOWNLOADING_TEXT;
        self.loadingLabel.hidden = NO;
        self.progressBar.hidden = NO;
    } else if ([status isEqualToString:@"downloaded"]) {
        [self.actionButton setTitle:ACTION_DOWNLOADED_TEXT forState:UIControlStateNormal];
        [self.spinner stopAnimating];
        self.actionButton.frame = CGRectMake(184, self.actionButton.frame.origin.y, 80, 30);
        self.actionButton.hidden = NO;
        self.archiveButton.hidden = NO;
        self.progressBar.hidden = YES;
        self.loadingLabel.hidden = YES;
    } else if ([status isEqualToString:@"bundled"]) {
        [self.actionButton setTitle:ACTION_DOWNLOADED_TEXT forState:UIControlStateNormal];
        [self.spinner stopAnimating];
        self.actionButton.frame = CGRectMake(184, self.actionButton.frame.origin.y, 80, 30);
        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.loadingLabel.hidden = YES;
        self.progressBar.hidden = YES;
    } else if ([status isEqualToString:@"opening"]) {
        [self.spinner startAnimating];
        self.actionButton.hidden = NO;
        self.archiveButton.hidden = NO;
        self.loadingLabel.text = OPENING_TEXT;
        self.loadingLabel.hidden = NO;
        self.progressBar.hidden = YES;
    }
}

#pragma mark - Memory management

- (void)dealloc
{
    [issue release];
    [actionButton release];
    [archiveButton release];
    [progressBar release];
    [spinner release];
    [loadingLabel release];
    
    [super dealloc];
}

#pragma mark - Issue management

- (void)actionButtonPressed:(UIButton *)sender
{    
    NSString *status = [self.issue getStatus];
    if ([status isEqualToString:@"remote"]) {
        [self download];
    } else if ([status isEqualToString:@"downloaded"] || [status isEqualToString:@"bundled"]) {
        [self read];
    } else if ([status isEqualToString:@"downloading"]) {
        // TODO: assuming it is supported by NewsstandKit, implement a "Cancel" operation
    }
}
- (void)download
{
    [self refresh:@"downloading"];
    [self.issue downloadWithDelegate:self];
}
- (void)read
{
    [self refresh:@"opening"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"read_issue_request" object:self];
}

#ifdef BAKER_NEWSSTAND

#pragma mark - Newsstand download management

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{    
    [self.progressBar setProgress:((float)totalBytesWritten/(float)expectedTotalBytes) animated:YES];
}
- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL
{
    NSLog(@"Connection did finish downloading %@", destinationURL);
    
    NKAssetDownload *dnl = connection.newsstandAssetDownload;
    NKIssue *nkIssue = dnl.issue;
    NSString *destinationPath = [[nkIssue contentURL] path];
    
    NSLog(@"File is being unzipped to %@", destinationPath);
    [SSZipArchive unzipFileAtPath:[destinationURL path] toDestination:destinationPath];
    
    [self refresh];
    
    // TODO: update Newsstand icon and add badge
}
- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{
    NSLog(@"Connection did resume downloading %lld %lld", totalBytesWritten, expectedTotalBytes);
    
    [self.progressBar setProgress:((float)totalBytesWritten/(float)expectedTotalBytes) animated:YES];
}

#pragma mark - Newsstand archive management

- (void)archiveButtonPressed:(UIButton *)sender
{
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    NKIssue *nkIssue = [nkLib issueWithName:self.issue.ID];
    NSString *name = nkIssue.name;
    NSDate *date = nkIssue.date;
    
    [nkLib removeIssue:nkIssue];
    
    nkIssue = [nkLib addIssueWithName:name date:date];
    self.issue.path = [[nkIssue contentURL] path];
    
    [self refresh];
}

#endif

@end
