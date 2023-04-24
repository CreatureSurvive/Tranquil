//
//  TranquilModuleStepper.m
//  Tranquil
//
//  Created by Dana Buehre on 3/14/22.
//
//

#import <UIKit/UIKit.h>
#import "TranquilModuleStepper.h"
#import "UIImage+TranquilModule.h"
#import "Prefix.h"
#import "Haptic.h"

@implementation TranquilModuleStepper {

    UIButton *_incrementButton;
    UIButton *_decrementButton;
    UILabel *_valueLabel;
    NSTimer *_longPressTimer;
}

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {

        [self _baseInit];
    }

    return self;
}

- (void)_baseInit
{
    _minValue = 0;
    _maxValue = 1;
    _stepValue = 1;
    _direction = TMStepperLayoutDirectionHorizontal;

    _incrementButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_incrementButton setImage:[UIImage tranquil_moduleImageNamed:@"Increment"] forState:UIControlStateNormal];
    [_incrementButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleLongPress:)]];
    [_incrementButton addTarget:self action:@selector(_handleIncrement) forControlEvents:UIControlEventTouchUpInside];
    [_incrementButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [_incrementButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    _decrementButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_decrementButton setImage:[UIImage tranquil_moduleImageNamed:@"Decrement"] forState:UIControlStateNormal];
    [_decrementButton addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleLongPress:)]];
    [_decrementButton addTarget:self action:@selector(_handleDecrement) forControlEvents:UIControlEventTouchUpInside];
    [_decrementButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [_decrementButton setTranslatesAutoresizingMaskIntoConstraints:NO];

    _valueLabel = [UILabel new];
    [_valueLabel setNumberOfLines:0];
    [_valueLabel setTextAlignment:NSTextAlignmentCenter];
    [_valueLabel setTranslatesAutoresizingMaskIntoConstraints:NO];

    [self addSubview:_valueLabel];
    [self addSubview:_decrementButton];
    [self addSubview:_incrementButton];

    [self setClipsToBounds:YES];

    [self _updateLabel];
}

- (void)_handleLongPress:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            if (_longPressTimer) return;

            void (^handler)(NSTimer *) = sender.view == _incrementButton
                    ? ^(NSTimer *t) { [self _handleIncrement:self->_continuous]; }
                    : ^(NSTimer *t) { [self _handleDecrement:self->_continuous]; };
            _longPressTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:handler];
        } break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            if (!_longPressTimer) return;
            if (!_continuous) {

                [self sendActionsForControlEvents:UIControlEventValueChanged];
            }

            [_longPressTimer invalidate];
            _longPressTimer = nil;
        } break;
        default: break;
    }
}

- (void)_handleIncrement
{
    [self _handleIncrement:YES];
}

- (void)_handleIncrement:(BOOL)sendEvents
{
    NSInteger newValue = CLAMP(_value + _stepValue, _minValue, _maxValue);

    if (_value != newValue) {

        _value = newValue;

        if (_value == _maxValue) {

            HapticImpact(UIImpactFeedbackStyleMedium);

        } else if (_value % 3600 == 0) {

            HapticImpact(UIImpactFeedbackStyleLight);
        }

        if (sendEvents) {

            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }

    [self _updateLabel];
}

- (void)_handleDecrement
{
    [self _handleDecrement:YES];
}

- (void)_handleDecrement:(BOOL)sendEvents
{
    NSInteger newValue = CLAMP(_value - _stepValue, _minValue, _maxValue);

    if (_value != newValue) {

        _value = newValue;

        if (_value == _minValue) {

            HapticImpact(UIImpactFeedbackStyleMedium);

        } else if (_value % 3600 == 0) {

            HapticImpact(UIImpactFeedbackStyleLight);
        }

        if (sendEvents) {

            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
    }

    [self _updateLabel];
}

- (void)_updateLabel
{
    NSInteger interval = (NSInteger) _value;
    long minutes = (interval / 60) % 60;
    long hours = (interval / 3600);

    switch (_direction) {
        case TMStepperLayoutDirectionVertical:
            [_valueLabel setText:[NSString stringWithFormat:@"%0.2ldh\n%0.2ldm", hours, minutes]];
            break;
        case TMStepperLayoutDirectionHorizontal:
            [_valueLabel setText:[NSString stringWithFormat:@"%0.2ld:%0.2ld", hours, minutes]];
            break;
    }
}

- (void)setValue:(NSInteger)value
{
    _value = CLAMP(value, _minValue, _maxValue);
    [self _updateLabel];
}

- (void)setMinValue:(NSInteger)minValue
{
    _minValue = minValue;

    if (_value < minValue) {

        _value = minValue;
        [self _updateLabel];
    }
}

- (void)setMaxValue:(NSInteger)maxValue
{
    _maxValue = maxValue;

    if (_value > maxValue) {

        _value = maxValue;
        [self _updateLabel];
    }
}

- (void)setDirection:(TMStepperLayoutDirection)direction
{
    _direction = direction;
    [self _updateLabel];
    [self setNeedsLayout];
}

- (void)setLabelTextColor:(UIColor *)color
{
    [_valueLabel setTextColor:color];
}

- (void)setIncrementButtonBackgroundColor:(UIColor *)color
{
    [_incrementButton setBackgroundColor:color];
}

- (void)setDecrementButtonBackgroundColor:(UIColor *)color
{
    [_decrementButton setBackgroundColor:color];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize size = self.bounds.size;

    _valueLabel.frame = self.bounds;

    switch (_direction) {
        case TMStepperLayoutDirectionVertical: {
            _incrementButton.frame = CGRectMake(0, 0, size.width, size.width);
            _decrementButton.frame = CGRectMake(0, size.height - size.width, size.width, size.width);
            [_incrementButton.layer setCornerRadius:size.width / 2];
            [_decrementButton.layer setCornerRadius:size.width / 2];
        }   break;
        case TMStepperLayoutDirectionHorizontal: {
            _decrementButton.frame = CGRectMake(0, 0, size.height, size.height);
            _incrementButton.frame = CGRectMake(size.width - size.height, 0, size.height, size.height);
            [_incrementButton.layer setCornerRadius:size.height / 2];
            [_decrementButton.layer setCornerRadius:size.height / 2];
        }   break;
    }
}

@end
