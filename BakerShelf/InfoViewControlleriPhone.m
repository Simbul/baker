//
//  InfoViewControlleriPhone.m
//  Baker
//
//  Created by Andrew on 11/23/12.
//
//

#import "InfoViewControlleriPhone.h"
#import "ShelfViewController.h"
#import "Constants.h"
#import "UIColor+Extensions.h"

@interface InfoViewControlleriPhone ()

@end

@implementation InfoViewControlleriPhone

@synthesize dismissViewButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)dismissView:(id)sender {
	 NSLog(@"Closing Modal Info View");
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [dismissViewButton setBackgroundColor:[UIColor colorWithHexString:INFO_VIEW_BUTTON_COLOR]];
    [dismissViewButton setTitleColor:[UIColor colorWithHexString:INFO_VIEW_BUTTON_TEXT_COLOR] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
	[dismissViewButton release];
    [super dealloc];
}

@end
