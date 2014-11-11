//
//  MLBarDropdownItem.h
//  Baker
//
//  Created by Tobias Strebitzer on 24/10/14.
//
//

#import <UIKit/UIKit.h>

@protocol MLBarDropdownItemDelegate <NSObject>
@required
-(void)barDropdownItem:(id)barDropdownItem didSelectItem:(NSString *)item;
@end

@interface MLBarDropdownItem : UIBarButtonItem <UIPickerViewDataSource, UIPickerViewDelegate> {
    id <MLBarDropdownItemDelegate> delegate;
}

@property (retain) id delegate;
@property (nonatomic, retain) UITextField *textField;
@property (nonatomic, copy) id<UIPickerViewDelegate> pickerDelegate;
@property (nonatomic, copy) id<UIPickerViewDataSource> pickerDataSource;
@property (nonatomic, copy) NSArray *_dropdownData;

-(id)initWithData:(NSArray *)data delegate:(NSObject *)aDelegate;
-(id)initWithDelegate:(NSObject *)aDelegate;
-(void)setData:(NSArray *)data;

@end