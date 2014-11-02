//
//  MLBarDropdownItem.m
//  Baker
//
//  Created by Tobias Strebitzer on 24/10/14.
//
//

#import "MLBarDropdownItem.h"

@implementation MLBarDropdownItem {
    UIPickerView* _pickerView;
}

@synthesize textField;
@synthesize delegate;

-(id)initWithData:(NSArray *)data delegate:(NSObject *)aDelegate {
    
    // Set data
    [self setData:data];
    
    // Initialize dropdown
    if(self = [super initWithTitle:[self._dropdownData objectAtIndex:0] style:UIBarButtonItemStylePlain target:self action:@selector(barDropdownItemTouched:)]) {
        
        // Set delegate
        self.delegate = aDelegate;
    }
    return self;
}

-(id)initWithDelegate:(NSObject *)aDelegate {
    return [self initWithData:[NSArray array] delegate:aDelegate];
}

-(void)setData:(NSArray *)data {
    NSMutableArray *fullArray = [NSMutableArray arrayWithArray:data];
    // Prepend "All Categories" item
    [fullArray insertObject:NSLocalizedString(@"ALL_CATEGORIES_TITLE", nil) atIndex:0];
    self._dropdownData = fullArray;
}

- (IBAction)barDropdownItemTouched:(UIButton *)sender {
    
    if(!self.textField) {
        
        // Create picker view
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        _pickerView.showsSelectionIndicator = YES;
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        
        // Create accessory bar
        UIToolbar *accessoryToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,0, 320, 44)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(inputAccessoryViewDidFinish)];
        [accessoryToolbar setItems:[NSArray arrayWithObject: doneButton] animated:NO];
        
        // Create text input
        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        UIView *view = [self valueForKey:@"view"];
        [view addSubview:self.textField];
        self.textField.inputView = _pickerView;
        self.textField.inputAccessoryView = accessoryToolbar;
    }
    
    [self.textField becomeFirstResponder];
}

-(void) inputAccessoryViewDidFinish { [self.textField resignFirstResponder]; }

#pragma mark - Picker View delegates

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [self setTitle:[self._dropdownData objectAtIndex:row]];
    [[self delegate] barDropdownItem:self didSelectItem:[self._dropdownData objectAtIndex:row]];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self._dropdownData.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self._dropdownData objectAtIndex:row];
}

@end
