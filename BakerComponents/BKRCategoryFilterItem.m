//
//  BKRCategoryFilterItem.m
//  Baker
//
//  ==========================================================================================
//
//  Copyright (c) 2010-2013, Davide Casali, Marco Colombo, Alessandro Morandi
//  Copyright (c) 2014, Andrew Krowczyk, Cédric Mériau, Pieter Claerhout, Tobias Strebitzer
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

#import "BKRCategoryFilterItem.h"

@implementation BKRCategoryFilterItem {

}

@synthesize delegate;

-(id)initWithCategories:(NSArray *)aCategories delegate:(NSObject *)aDelegate {
    
    // Initialize dropdown
    if(self = [super initWithTitle:NSLocalizedString(@"ALL_CATEGORIES_TITLE", nil) style:UIBarButtonItemStylePlain target:self action:@selector(categoryFilterItemTouched:)]) {
        
        // Set categories
        self.categories = aCategories;
        
        // Set delegate
        self.delegate = aDelegate;
    }
    return self;
}

-(id)initWithDelegate:(NSObject *)aDelegate {
    return [self initWithCategories:[NSArray array] delegate:aDelegate];
}

- (IBAction)categoryFilterItemTouched:(UIBarButtonItem *)sender {
    if (self.categoriesActionSheet.visible) {
        [self.categoriesActionSheet dismissWithClickedButtonIndex:(self.categoriesActionSheet.numberOfButtons - 1) animated:YES];
    } else {
        self.categoriesActionSheet = [self buildCategoriesActionSheet];
        [self.categoriesActionSheet showFromBarButtonItem:sender animated:YES];
    }
}

- (UIActionSheet *)buildCategoriesActionSheet {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    NSMutableArray *actions = [NSMutableArray array];

    // Prepend "All Categories" item
    [sheet addButtonWithTitle:NSLocalizedString(@"ALL_CATEGORIES_TITLE", nil)];
    [actions addObject:@"reset-filter"];
    
    // Add categories
    for (NSString *categoryName in self.categories) {
        [sheet addButtonWithTitle:categoryName];
        [actions addObject:categoryName];
    }
    
    self.categoriesActionSheetActions = actions;
    
    return sheet;
}


#pragma mark - Action Sheet Delegates

- (void) actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == self.categoriesActionSheet && buttonIndex > -1) {
        NSString *action = [self.categoriesActionSheetActions objectAtIndex:buttonIndex];
        if ([action isEqualToString:@"reset-filter"]) {
            [self setTitle:NSLocalizedString(@"ALL_CATEGORIES_TITLE", nil)];
        } else {
            [self setTitle:action];
        }
        [self.delegate categoryFilterItem:self clickedAction:action];
    }
}

@end
