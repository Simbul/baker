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
#import "UIConstants.h"

#import "UIColor+Extensions.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    CGSize cellSize = [IssueViewController getIssueCellSize];

    self.view.frame = CGRectMake(0, 0, cellSize.width, cellSize.height);
    self.view.backgroundColor = [UIColor clearColor];
    self.view.tag = 42;

    UI ui = [IssueViewController getIssueContentMeasures];

    // SETUP COVER IMAGE
    [self.issue getCover:^(UIImage *image) {
        UIButton *issueCover = [UIButton buttonWithType:UIButtonTypeCustom];
        issueCover.frame = CGRectMake(ui.cellPadding, ui.cellPadding, ui.thumbWidth, ui.thumbHeight);
        
        issueCover.backgroundColor = [UIColor clearColor];
        issueCover.adjustsImageWhenHighlighted = NO;
        issueCover.adjustsImageWhenDisabled = NO;
        
        [issueCover setBackgroundImage:image forState:UIControlStateNormal];
        
        issueCover.layer.shadowOpacity = 0.5;
        issueCover.layer.shadowOffset = CGSizeMake(0, 2);
        issueCover.layer.shouldRasterize = YES;
        issueCover.layer.rasterizationScale = [UIScreen mainScreen].scale;

        [issueCover addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:issueCover];
    }];

    int heightOffset = ui.cellPadding;

    // SETUP USED FONTS
    UIFont *titleFont = [UIFont fontWithName:ISSUES_TITLE_FONT size:ISSUES_TITLE_FONT_SIZE];
    UIFont *infoFont = [UIFont fontWithName:ISSUES_INFO_FONT size:ISSUES_INFO_FONT_SIZE];
    uint textLineheight = [@"The brown fox jumps over the lazy dog" sizeWithFont:infoFont constrainedToSize:CGSizeMake(MAXFLOAT, MAXFLOAT)].height;
    UIFont *actionFont = [UIFont fontWithName:ISSUES_ACTION_BUTTON_FONT size:ISSUES_ACTION_BUTTON_FONT_SIZE];
    UIFont *archiveFont = [UIFont fontWithName:ISSUES_ARCHIVE_BUTTON_FONT size:ISSUES_ARCHIVE_BUTTON_FONT_SIZE];


    // SETUP TITLE LABEL
    CGSize titleSize = [self.issue.title sizeWithFont:titleFont constrainedToSize:CGSizeMake(170, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    uint titleLines = MIN(4, titleSize.height / textLineheight);

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(ui.contentOffset, heightOffset, 170, textLineheight * titleLines)];
    titleLabel.textColor = [UIColor colorWithHexString:ISSUES_TITLE_COLOR];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    titleLabel.textAlignment = UITextAlignmentLeft;
    titleLabel.numberOfLines = titleLines;
    titleLabel.text = self.issue.title;
    titleLabel.font = titleFont;

    [self.view addSubview:titleLabel];
    [titleLabel release];

    heightOffset = heightOffset + titleLabel.frame.size.height + 5;


    // SETUP INFO LABEL
    CGSize infoSize = [self.issue.info sizeWithFont:infoFont constrainedToSize:CGSizeMake(170, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    uint infoLines = MIN(4, infoSize.height / textLineheight);

    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(ui.contentOffset, heightOffset, 170, textLineheight * infoLines)];
    infoLabel.textColor = [UIColor colorWithHexString:ISSUES_INFO_COLOR];
    infoLabel.backgroundColor = [UIColor clearColor];
    infoLabel.lineBreakMode = UILineBreakModeTailTruncation;
    infoLabel.textAlignment = UITextAlignmentLeft;
    infoLabel.numberOfLines = infoLines;
    infoLabel.text = self.issue.info;
    infoLabel.font = infoFont;

    [self.view addSubview:infoLabel];
    [infoLabel release];

    heightOffset = heightOffset + infoLabel.frame.size.height + 10;


    // SETUP ACTION BUTTON
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    actionButton.frame = CGRectMake(ui.contentOffset, heightOffset, 80, 30);
    actionButton.backgroundColor = [UIColor colorWithHexString:ISSUES_ACTION_BUTTON_BACKGROUND_COLOR];
    actionButton.titleLabel.font = actionFont;

    [actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];
    [actionButton setTitleColor:[UIColor colorWithHexString:ISSUES_ACTION_BUTTON_COLOR] forState:UIControlStateNormal];
    [actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:actionButton];


    // SETUP ARCHIVE BUTTON
    self.archiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    archiveButton.frame = CGRectMake(ui.contentOffset + self.actionButton.frame.size.width + 10, heightOffset, 80, 30);
    archiveButton.backgroundColor = [UIColor colorWithHexString:ISSUES_ARCHIVE_BUTTON_BACKGROUND_COLOR];
    archiveButton.titleLabel.font = archiveFont;

    [archiveButton setTitle:NSLocalizedString(@"ARCHIVE_TEXT", nil) forState:UIControlStateNormal];
    [archiveButton setTitleColor:[UIColor colorWithHexString:ISSUES_ARCHIVE_BUTTON_COLOR] forState:UIControlStateNormal];
    [archiveButton addTarget:self action:@selector(archiveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    #ifdef BAKER_NEWSSTAND
    [self.view addSubview:archiveButton];
    #endif


    // SETUP DOWN/LOADING SPINNER AND LABEL
    self.spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    spinner.color = [UIColor colorWithHexString:ISSUES_LOADING_SPINNER_COLOR];
    spinner.frame = CGRectMake(ui.contentOffset, heightOffset, 30, 30);
    spinner.backgroundColor = [UIColor clearColor];
    spinner.hidesWhenStopped = YES;

    self.loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(ui.contentOffset + self.spinner.frame.size.width + 10, heightOffset, 135, 30)];
    loadingLabel.textColor = [UIColor colorWithHexString:ISSUES_LOADING_LABEL_COLOR];
    loadingLabel.backgroundColor = [UIColor clearColor];
    loadingLabel.textAlignment = UITextAlignmentLeft;
    loadingLabel.text = NSLocalizedString(@"DOWNLOADING_TEXT", nil);
    loadingLabel.font = actionFont;

    [self.view addSubview:spinner];
    [self.view addSubview:loadingLabel];

    heightOffset = heightOffset + self.loadingLabel.frame.size.height + 5;


    // SETUP PROGRESS BAR
    self.progressBar = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
    self.progressBar.frame = CGRectMake(ui.contentOffset, heightOffset, 170, 30);
    self.progressBar.progressTintColor = [UIColor colorWithHexString:ISSUES_PROGRESSBAR_TINT_COLOR];

    [self.view addSubview:progressBar];

    #ifdef BAKER_NEWSSTAND
    // RESUME PENDING NEWSSTAND DOWNLOAD
    NKLibrary *nkLib = [NKLibrary sharedLibrary];
    for (NKAssetDownload *asset in [nkLib downloadingAssets]) {
        if ([asset.issue.name isEqualToString:self.issue.ID]) {
            NSLog(@"Resuming abandoned Newsstand download: %@", asset.issue.name);
            [asset downloadWithDelegate:self];
        }
    }
    #endif
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}
- (void)refresh
{
    [self refresh:[self.issue getStatus]];
}
- (void)refresh:(NSString *)status
{
    UI ui = [IssueViewController getIssueContentMeasures];

    NSLog(@"Refreshing %@ view with status %@", self.issue.ID, status);
    if ([status isEqualToString:@"remote"])
    {
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_REMOTE_TEXT", nil) forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.frame = CGRectMake(ui.contentOffset, self.actionButton.frame.origin.y, 110, 30);
        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.progressBar.hidden = YES;
        self.loadingLabel.hidden = YES;
    }
    else if ([status isEqualToString:@"connecting"])
    {
        [self.spinner startAnimating];

        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.progressBar.progress = 0;
        self.loadingLabel.text = NSLocalizedString(@"CONNECTING_TEXT", nil);
        self.loadingLabel.hidden = NO;
        self.progressBar.hidden = YES;
    }
    else if ([status isEqualToString:@"downloading"])
    {
        [self.spinner startAnimating];

        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.progressBar.progress = 0;
        self.loadingLabel.text = NSLocalizedString(@"DOWNLOADING_TEXT", nil);
        self.loadingLabel.hidden = NO;
        self.progressBar.hidden = NO;
    }
    else if ([status isEqualToString:@"downloaded"])
    {
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.frame = CGRectMake(ui.contentOffset, self.actionButton.frame.origin.y, 80, 30);
        self.actionButton.hidden = NO;
        self.archiveButton.hidden = NO;
        self.loadingLabel.hidden = YES;
        self.progressBar.hidden = YES;
    }
    else if ([status isEqualToString:@"bundled"])
    {
        [self.actionButton setTitle:NSLocalizedString(@"ACTION_DOWNLOADED_TEXT", nil) forState:UIControlStateNormal];
        [self.spinner stopAnimating];

        self.actionButton.frame = CGRectMake(ui.contentOffset, self.actionButton.frame.origin.y, 80, 30);
        self.actionButton.hidden = NO;
        self.archiveButton.hidden = YES;
        self.loadingLabel.hidden = YES;
        self.progressBar.hidden = YES;
    }
    else if ([status isEqualToString:@"opening"])
     {
        [self.spinner startAnimating];

        self.actionButton.hidden = YES;
        self.archiveButton.hidden = YES;
        self.loadingLabel.text = NSLocalizedString(@"OPENING_TEXT", nil);
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
    #ifdef BAKER_NEWSSTAND
        [self download];
    #endif
    } else if ([status isEqualToString:@"downloaded"] || [status isEqualToString:@"bundled"]) {
        [self read];
    } else if ([status isEqualToString:@"downloading"]) {
        // TODO: assuming it is supported by NewsstandKit, implement a "Cancel" operation
    }
}
#ifdef BAKER_NEWSSTAND
- (void)download
{
    [self refresh:@"connecting"];
    [self.issue downloadWithDelegate:self];
}
#endif
- (void)read
{
    [self refresh:@"opening"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"read_issue_request" object:self];
}

#pragma mark - Newsstand download management

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{
    // TODO: use a better check (ideally check that status is "connecting" instead of relying on a UI property)
    if (self.progressBar.hidden) {
        [self refresh:@"downloading"];
    }
    [self.progressBar setProgress:((float)totalBytesWritten/(float)expectedTotalBytes) animated:YES];
}
- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL
{
    #ifdef BAKER_NEWSSTAND
    NSLog(@"Connection did finish downloading %@", destinationURL);

    NKAssetDownload *dnl = connection.newsstandAssetDownload;
    NKIssue *nkIssue = dnl.issue;
    NSString *destinationPath = [[nkIssue contentURL] path];

    NSLog(@"File is being unzipped to %@", destinationPath);
    [SSZipArchive unzipFileAtPath:[destinationURL path] toDestination:destinationPath];

    NSLog(@"Removing temporary downloaded file %@", [destinationURL path]);
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error;
    if ([fileMgr removeItemAtPath:[destinationURL path] error:&error] != YES){
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
    }
    
    [self refresh];

    // TODO: notify of new content with setApplicationIconBadgeNumber

    BakerBook *book = [[BakerBook alloc]initWithBookPath:destinationPath bundled:NO];
    UIImage *coverImage = [UIImage imageWithContentsOfFile:[destinationPath stringByAppendingPathComponent:book.cover]];
    if (coverImage) {
        [[UIApplication sharedApplication] setNewsstandIconImage:coverImage];
    }
    #endif
}
- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long)expectedTotalBytes
{
    NSLog(@"Connection did resume downloading %lld %lld", totalBytesWritten, expectedTotalBytes);
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection error when trying to download %@: %@", [connection currentRequest].URL, [error localizedDescription]);
    [connection cancel];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DOWNLOAD_FAILED_TITLE", nil)
                                                    message:NSLocalizedString(@"DOWNLOAD_FAILED_MESSAGE", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"DOWNLOAD_FAILED_CLOSE", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];

    [self refresh];
}

#pragma mark - Newsstand archive management

#ifdef BAKER_NEWSSTAND
- (void)archiveButtonPressed:(UIButton *)sender
{
    UIAlertView *updateAlert = [[UIAlertView alloc]
                                initWithTitle: NSLocalizedString(@"ARCHIVE_ALERT_TITLE", nil)
                                message: NSLocalizedString(@"ARCHIVE_ALERT_MESSAGE", nil)
                                delegate: self
                                cancelButtonTitle: NSLocalizedString(@"ARCHIVE_ALERT_BUTTON_CANCEL", nil)
                                otherButtonTitles: NSLocalizedString(@"ARCHIVE_ALERT_BUTTON_OK", nil), nil];
    [updateAlert show];
    [updateAlert release];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1){
        NKLibrary *nkLib = [NKLibrary sharedLibrary];
        NKIssue *nkIssue = [nkLib issueWithName:self.issue.ID];
        NSString *name = nkIssue.name;
        NSDate *date = nkIssue.date;
        
        [nkLib removeIssue:nkIssue];
        
        nkIssue = [nkLib addIssueWithName:name date:date];
        self.issue.path = [[nkIssue contentURL] path];
        
        [self refresh];
    }
}
#endif

#pragma mark - Helper methods

+ (UI)getIssueContentMeasures
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UI iPad = {
            .cellPadding   = 30,
            .thumbWidth    = 135,
            .thumbHeight   = 180,
            .contentOffset = 184
        };
        return iPad;
    } else {
        UI iPhone = {
            .cellPadding   = 22,
            .thumbWidth    = 87,
            .thumbHeight   = 116,
            .contentOffset = 128
        };
        return iPhone;
    }
}

+ (int)getIssueCellHeight
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 240;
    } else {
        return 156;
    }
}
+ (CGSize)getIssueCellSize
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return CGSizeMake((screenRect.size.width - 2) / 2, [IssueViewController getIssueCellHeight]);
    } else {
        return CGSizeMake(screenRect.size.width - 2, [IssueViewController getIssueCellHeight]);
    }
}

@end
