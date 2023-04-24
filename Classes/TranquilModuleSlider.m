//
//  TranquilModuleSlider.m
//  Tranquil
//
//  Created by Dana Buehre on 3/20/22.
//
//

#import "TranquilModuleSlider.h"
#import "Material.h"
#import "Prefix.h"
#import "Haptic.h"

@implementation TranquilModuleSlider {

    MTMaterialView *_trackView;
    MTMaterialView *_progressView;
    BOOL _feedbackOccurred;
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
    _trackView = ControlCenterForegroundMaterial();
    _progressView = ControlCenterVibrantLightMaterial();
    [_trackView.layer setMasksToBounds:YES];
    [_trackView addSubview:_progressView];

    [self addSubview:_trackView];
    [self sendSubviewToBack:_trackView];

    _direction = RTLLayout(self) ? TMSSliderDirectionRightToLeft : TMSSliderDirectionLeftToRight;
    _value = 0.5f;
    _minValue = 0;
    _maxValue = 1;
    _continuous = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1) {

        [self sendActionsForControlEvents:UIControlEventTouchDown];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (touches.count == 1) {

        UITouch *touch = touches.anyObject;
        CGSize size = self.bounds.size;
        CGPoint currentLocation = [touch locationInView:self];
        CGPoint previousLocation = [touch previousLocationInView:self];
        CGFloat normalizedDelta = 0;

        switch (_direction) {
            case TMSSliderDirectionLeftToRight:
                normalizedDelta = (currentLocation.x - previousLocation.x) / size.width;
                break;
            case TMSSliderDirectionRightToLeft:
                normalizedDelta = (previousLocation.x - currentLocation.x) / size.width;
                break;
            case TMSSliderDirectionBottomToTop:
                normalizedDelta = (previousLocation.y - currentLocation.y) / size.height;
                break;
            case TMSSliderDirectionTopToBottom:
                normalizedDelta = (currentLocation.y - previousLocation.y) / size.height;
                break;
        }

        [self _setValue:_value + (float) normalizedDelta sendEvents:_continuous];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    BOOL inside = CGRectContainsPoint(self.bounds, [touches.anyObject locationInView:self]);
    [self sendActionsForControlEvents:inside ? UIControlEventTouchUpInside : UIControlEventTouchUpOutside];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self sendActionsForControlEvents:UIControlEventTouchCancel];
}

- (void)_setValue:(float)value sendEvents:(BOOL)sendEvents
{
    float newValue = CLAMP(value, _minValue, _maxValue);
    BOOL valueChanged = _value != newValue;
    _value = newValue;

    [self setNeedsLayout];

    if (valueChanged) {

        if (sendEvents) {

            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }

        if (_value >= _maxValue || _value <= _minValue) {

            if (!_feedbackOccurred) {

                _feedbackOccurred = YES;
                HapticImpact(UIImpactFeedbackStyleLight);
            }

        } else {

            _feedbackOccurred = NO;
        }
    }
}

- (void)setValue:(float)value
{
    _value = CLAMP(value, _minValue, _maxValue);
    [self setNeedsLayout];
}

- (void)setValue:(float)value animated:(BOOL)animated
{
    _value = CLAMP(value, _minValue, _maxValue);

    if (animated) {

        UIViewAnimationOptions options = UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:0.2 delay:0 options:options animations:^{
            [self setNeedsLayout];
        } completion:nil];

    } else {

        [self setNeedsLayout];
    }
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    CGSize size = self.bounds.size;
    _trackView.frame = self.bounds;

    switch (_direction) {
        case TMSSliderDirectionLeftToRight: {
            _progressView.frame = CGRectMake(0, 0, size.width * _value, size.height);
            [_trackView.layer setCornerRadius:size.height / 2];
        }   break;
        case TMSSliderDirectionRightToLeft: {
            CGFloat width = size.width * _value;
            _progressView.frame = CGRectMake(size.width - width, 0, width, size.height);
            [_trackView.layer setCornerRadius:size.height / 2];
        }   break;
        case TMSSliderDirectionBottomToTop: {
            CGFloat height = size.height * _value;
            _progressView.frame = CGRectMake(0, size.height - height, size.width, height);
            [_trackView.layer setCornerRadius:size.width / 2];
        }   break;
        case TMSSliderDirectionTopToBottom: {
            _progressView.frame = CGRectMake(0, 0, size.width, size.height * _value);
            [_trackView.layer setCornerRadius:size.width / 2];
        }   break;
    }
}

@end
