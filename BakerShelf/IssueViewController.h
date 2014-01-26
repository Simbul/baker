//
//  IssueViewController.h
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

#import <UIKit/UIKit.h>
#import "BakerIssue.h"
#ifdef BAKER_NEWSSTAND
#import "PurchasesManager.h"
#endif

@interface IssueViewController : UIViewController {
    NSString *currentAction;
    BOOL purchaseDelayed;
    #ifdef BAKER_NEWSSTAND
    PurchasesManager *purchasesManager;
    #endif
}

@property (strong, nonatomic) BakerIssue *issue;
@property (strong, nonatomic) UIButton *actionButton;
@property (strong, nonatomic) UIButton *archiveButton;
@property (strong, nonatomic) UIProgressView *progressBar;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) UILabel *loadingLabel;
@property (strong, nonatomic) UILabel *priceLabel;

@property (strong, nonatomic) UIButton *issueCover;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *infoLabel;

@property (copy, nonatomic) NSString *currentStatus;

#pragma mark - Structs
typedef struct {
    int cellPadding;
    int thumbWidth;
    int thumbHeight;
    int contentOffset;
} UI;

#pragma mark - Init
- (id)initWithBakerIssue:(BakerIssue *)bakerIssue;

#pragma mark - View Lifecycle
- (void)refresh;
- (void)refresh:(NSString *)status;
- (void)refreshContentWithCache:(bool)cache;
- (void)preferredContentSizeChanged:(NSNotification *)notification;

#pragma mark - Issue management
- (void)actionButtonPressed:(UIButton *)sender;
#ifdef BAKER_NEWSSTAND
- (void)download;
- (void)setPrice:(NSString *)price;
- (void)buy;
#endif
- (void)read;

#pragma mark - Newsstand archive management
#ifdef BAKER_NEWSSTAND
- (void)archiveButtonPressed:(UIButton *)sender;
#endif

#pragma mark - Helper methods
+ (UI)getIssueContentMeasures;
+ (int)getIssueCellHeight;
+ (CGSize)getIssueCellSize;

@end

#ifdef BAKER_NEWSSTAND
@interface alertView: UIAlertView <UIActionSheetDelegate> {

}
@end
#endif
