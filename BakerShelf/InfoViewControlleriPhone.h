//
//  InfoViewControlleriPhone.h
//  Baker
//
//  Created by Andrew on 11/23/12.
//
//

#import <UIKit/UIKit.h>

@interface InfoViewControlleriPhone : UIViewController{

UIButton *dismissViewButton;
}

@property (nonatomic, retain) IBOutlet UIButton *dismissViewButton;

- (IBAction)dismissView:(id)sender;


@end
