//
//  TapHandler.m
//  Baker
//
//  Created by Xmas on 10/20/09.
//  Copyright 2010 Xmas. All rights reserved.
//

#import "TapHandler.h"


@implementation TapHandler


- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	NSLog(@"TAP"); 
	NSSet *allTouches = [event allTouches];
	
	// Number of touches on the screen
	switch ([allTouches count]) {
		// One touch
		case 1: {
			// Get the first touch.
			UITouch *touch = [[allTouches allObjects] objectAtIndex:0];
			switch([touch tapCount]) {
				// Single tap
				case 1: {
					[[NSNotificationCenter defaultCenter] postNotificationName:@"singleTap" object:touch];
					break;
				}
				// More taps;
				default: {
					[super touchesEnded:touches withEvent:event];
					break;
				}
			}
			break;
		}
		// More touches
		default: {
			[super touchesEnded:touches withEvent:event];
			break;
		}
	}	
}

- (void)dealloc {
	
    [super dealloc];
}


@end
