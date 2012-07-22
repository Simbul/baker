//
//  ShelfViewController.m
//  Baker
//
//  Created by Marco Colombo on 16/07/12.
//  Copyright (c) 2012 Marco Natale Colombo. All rights reserved.
//

#import "ShelfViewController.h"
#import "ShelfManager.h"


@implementation ShelfViewController

@synthesize books;

#pragma mark - Init

- (id)init {

    self = [super init];
    if (self) {
        self.books = [ShelfManager localBooksList];
    }
    return self;
}

#pragma mark - Memory management

- (void)dealloc
{
    [books release];

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Baker Shelf";

    self.gridView.backgroundColor  = [UIColor scrollViewTexturedBackgroundColor];
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
	self.gridView.autoresizesSubviews = YES;

    [self.gridView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Shelf data source

- (NSUInteger)numberOfItemsInGridView:(AQGridView *)aGridView
{
    return [books count];
}

- (AQGridViewCell *)gridView:(AQGridView *)aGridView cellForItemAtIndex:(NSUInteger)index
{
    static NSString *cellIdentifier = @"cellIdentifier";

    AQGridViewCell *cell = (AQGridViewCell *)[self.gridView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil)
	{
		cell = [[[AQGridViewCell alloc] initWithFrame:CGRectMake(0, 0, 100, 150) reuseIdentifier:cellIdentifier] autorelease];
		cell.selectionGlowColor = [UIColor clearColor];
	}

    return cell;
}

- (CGSize)portraitGridCellSizeForGridView:(AQGridView *)aGridView
{
    return CGSizeMake(153.6, 240);
}

@end
