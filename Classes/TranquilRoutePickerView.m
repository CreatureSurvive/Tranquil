//
//  TranquilRoutePickerView.m
//  Tranquil
//
//  Created by Dana Buehre on 4/8/22.
//

#import "TranquilRoutePickerView.h"
#import "Material.h"
#import "Prefix.h"

@interface AVRoutePickerView (private)
- (void)updateButtonAppearance;
- (void)_createOrUpdateRoutePickerButton;
@end

@implementation TranquilRoutePickerView

- (instancetype)init
{
    if (self = [super init]) {
        
        [self _createOrUpdateRoutePickerButton];
        
        _backgroundView = ControlCenterVibrantLightMaterial();
        [_backgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_backgroundView.layer setMasksToBounds:YES];
        [_backgroundView.layer setCornerRadius:18];
        
        [self addSubview:_backgroundView];
        [self sendSubviewToBack:_backgroundView];
        
        UIButton *routePickerButton = [self routePickerButton];
        
        [NSLayoutConstraint activateConstraints:@[
                [_backgroundView.widthAnchor constraintEqualToConstant:36],
                [_backgroundView.heightAnchor constraintEqualToConstant:36],
                [_backgroundView.centerYAnchor constraintEqualToAnchor:routePickerButton.centerYAnchor],
                [_backgroundView.centerXAnchor constraintEqualToAnchor:routePickerButton.centerXAnchor]
        ]];
    }
    
    return self;
}

- (void)_createOrUpdateRoutePickerButton
{
    [super _createOrUpdateRoutePickerButton];
        
    [self.routePickerButton setImageEdgeInsets:UIEdgeInsetsZero];
    [self.routePickerButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    [self.routePickerButton addTarget:self action:@selector(_highlightButton) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [self.routePickerButton addTarget:self action:@selector(_unhighlightButton) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchDragOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
}

- (UIButton *)routePickerButton
{
    return [self safeValueForKey:@"_routePickerButton"];
}

- (void)_highlightButton
{
    [self.routePickerButton setHighlighted:YES];
    [self setTintColor:[self.tintColor colorWithAlphaComponent:0.5]];
}

- (void)_unhighlightButton
{
    [self.routePickerButton setHighlighted:NO];
    [self setTintColor:[self.tintColor colorWithAlphaComponent:1]];
}

@end
