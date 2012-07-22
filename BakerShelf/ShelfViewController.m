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
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
