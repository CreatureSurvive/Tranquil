//
//  TranquilModuleBackgroundViewController.m
//  Tranquil
//
//  Created by Dana Buehre on 3/9/22.
//
//

#import <UIKit/UIKit.h>
#import "TranquilModuleBackgroundViewController.h"

#import "Prefix.h"
#import "Haptic.h"
#import "Material.h"
#import "TranquilModule.h"
#import "TranquilModuleSlider.h"
#import "TranquilModuleStepper.h"
#import "UIImage+TranquilModule.h"

#import <ControlCenterUIKit/CCUILabeledRoundButtonViewController.h>
#import <ControlCenterUIKit/CCUILabeledRoundButton.h>
#import <ControlCenterUIKit/CCUIRoundButton.h>

typedef NS_ENUM(NSUInteger, TMControlType) {
    TMControlTypeVolume = 0,
    TMControlTypePlayback = 1,
    TMControlTypeTimer = 2
};

typedef NS_ENUM(NSUInteger, TMLayoutDirection) {
    TMLayoutDirectionVertical = 0,
    TMLayoutDirectionHorizontal = 1
};

@interface CCUILabeledRoundButtonViewController (iOS12)
@property (assign, nonatomic) BOOL useAlternateBackground;
@end

@interface  CCUIRoundButton (iOS15)
@property (nonatomic,copy) UIColor * highlightTintColor;
@end

@interface TranquilModuleBackgroundViewController () {

    float _lastVolume;

    UIView *_controlContainer;

    TranquilModuleSlider *_volumeSlider;
    TranquilModuleStepper *_timerStepper;

    MTMaterialView *_timerControlContainer;
    MTMaterialView *_volumeControlContainer;

    CCUILabeledRoundButtonViewController *_volumeButtonViewController;
    CCUILabeledRoundButtonViewController *_playbackButtonViewController;
    CCUILabeledRoundButtonViewController *_timerButtonViewController;

    UITapGestureRecognizer *_controlDismissRecognizer;

    NSLayoutConstraint *_timerButtonWidthAnchor;
    NSLayoutConstraint *_volumeButtonWidthAnchor;
    NSLayoutConstraint *_timerControlTrailingAnchor;
    NSLayoutConstraint *_volumeControlLeadingAnchor;
    NSLayoutConstraint *_timerControlContainerLeadingAnchor;
    NSLayoutConstraint *_volumeControlContainerTrailingAnchor;
    NSLayoutConstraint *_timerControlBottomAnchor;
    NSLayoutConstraint *_volumeControlTopAnchor;
    NSLayoutConstraint *_timerControlContainerTopAnchor;
    NSLayoutConstraint *_volumeControlContainerBottomAnchor;
    NSArray <NSLayoutConstraint *> *_verticalConstraints;
    NSArray <NSLayoutConstraint *> *_horizontalConstraints;
}

@end

@implementation TranquilModuleBackgroundViewController

- (instancetype)init
{
	return [self initWithNibName:nil bundle:nil];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    float volume = [_module getVolume];

    _controlDismissRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_backgroundTapped:)];
    [self.view addGestureRecognizer:_controlDismissRecognizer];

    _controlContainer = [UIView new];
    [_controlContainer setTranslatesAutoresizingMaskIntoConstraints:NO];

    _timerControlContainer = ControlCenterBackgroundMaterial();
    [_timerControlContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_timerControlContainer setUserInteractionEnabled:YES];
    SetCornerRadiusLayer(_timerControlContainer.layer, 27);

    _volumeControlContainer = ControlCenterBackgroundMaterial();
    [_volumeControlContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_volumeControlContainer setUserInteractionEnabled:YES];
    SetCornerRadiusLayer(_volumeControlContainer.layer, 27);

    _volumeButtonViewController = [self _labeledRoundButtonControllerWithGlyph:@"VolumeMax" highlightColor:UIColor.systemBlueColor initialState:volume > 0 useLongPress:YES];
    _playbackButtonViewController = [self _labeledRoundButtonControllerWithGlyph:@"Play" highlightColor:UIColor.systemBlueColor initialState:YES useLongPress:NO];
    _timerButtonViewController = [self _labeledRoundButtonControllerWithGlyph:@"Timer" highlightColor:UIColor.systemOrangeColor initialState:NO useLongPress:YES];

    _volumeSlider = [TranquilModuleSlider new];
    [_volumeSlider setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_volumeSlider addTarget:self action:@selector(_sliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
    [_volumeSlider addTarget:self action:@selector(_sliderDidEndDrag:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel)];
    [_volumeSlider setContinuous:YES];
    [_volumeSlider setMinValue:0];
    [_volumeSlider setMaxValue:1];
    [_volumeSlider setValue:volume];

    _timerStepper = [TranquilModuleStepper new];
    [_timerStepper setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_timerStepper addTarget:self action:@selector(_stepperValueDidChange:) forControlEvents:UIControlEventValueChanged];
    [_timerStepper setMinValue:0]; // min 0 (disabled)
    [_timerStepper setMaxValue:12*60*60]; // max 12 hrs
    [_timerStepper setStepValue:1*60]; // step 1 min
    [_timerStepper setLabelTextColor:[UIColor lightTextColor]];
    [_timerStepper setDecrementButtonBackgroundColor:[UIColor systemBlueColor]];
    [_timerStepper setIncrementButtonBackgroundColor:[UIColor systemBlueColor]];

    [self.view addSubview:_controlContainer];
    [_controlContainer addSubview:_timerControlContainer];
    [_controlContainer addSubview:_volumeControlContainer];
    [_timerControlContainer addSubview:_timerStepper];
    [_volumeControlContainer addSubview:_volumeSlider];
    [_controlContainer addSubview:_volumeButtonViewController.view];
    [_controlContainer addSubview:_playbackButtonViewController.view];
    [_controlContainer addSubview:_timerButtonViewController.view];

    [self _configureConstraints];
    [self _configureVolumeControllerState];
    [self _configurePlaybackControllerState];
    [self _configureTimerControllerState];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // update layout for ControlCenter orientation
    TMLayoutDirection direction = [self _currentLayoutDirection];
    [self updateConstraintsForLayoutDirection:direction];

    // collapse controls
    [self _updateControlType:TMControlTypeVolume animated:NO opening:NO];
    [self _updateControlType:TMControlTypeTimer animated:NO opening:NO];

    // configure glyph states
    [self _configureVolumeControllerState];
    [self _configurePlaybackControllerState];
}

- (void)viewLayoutMarginsDidChange
{
    [super viewLayoutMarginsDidChange];

    TMLayoutDirection direction = [self _currentLayoutDirection];
    [self updateConstraintsForLayoutDirection:direction];
}

- (void)_backgroundTapped:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateRecognized) {

        CGPoint location = [sender locationInView:self.view];
        UIEdgeInsets sausageFingersInsets = UIEdgeInsetsMake(-16, -16, -16, -16); // add a dead-zone for large fingers

        if (CGRectContainsPoint(UIEdgeInsetsInsetRect(_controlContainer.frame, sausageFingersInsets), location)) {

            return;
        }

        if (_timerControlsShowing) {

            [self _updateTimerControls:YES];

        } else if (_volumeControlsShowing) {

            [self _updateVolumeControls:YES];
        }
    }
}

- (void)_buttonPressed:(UILongPressGestureRecognizer *)sender
{
    if ([sender isKindOfClass:UILongPressGestureRecognizer.class] && sender.state == UIGestureRecognizerStateBegan) {

        HapticImpactWithSound(UIImpactFeedbackStyleMedium, 1104);

        if (sender.view == _volumeButtonViewController.button) {

            [self _updateVolumeControls:YES];

        } else if (sender.view == _timerButtonViewController.button) {

            [self _updateTimerControls:YES];
        }
    }
}

- (void)_buttonTapped:(CCUIRoundButton *)sender
{
    if (sender == _volumeButtonViewController.button) {

        if (_volumeControlsShowing) {

            [self _updateVolumeControls:YES];

        } else {

            float volume = [_module getVolume];
            float newVolume = volume > 0 ? 0 : (_lastVolume ? : 0.6f);
            [_module setVolume:newVolume];
            [self updateVolumeState];
            _lastVolume = volume;
        }

    } else if (sender == _playbackButtonViewController.button) {

        if ([_module isPlaying]) {

            [_module stopTrack];

        } else {

            [_module resumeTrack];
        }

        [self _configurePlaybackControllerState];

    } else if (sender == _timerButtonViewController.button) {

        if (_module.isTimerRunning) {

            [_module updateDisableTimerWithTimeInterval:0 enable:NO];

        } else if (_timerStepper.value > 0 && [_module isPlaying]) {

            [_module updateDisableTimerWithTimeInterval:_timerStepper.value enable:YES];
        }

        [self _configureTimerControllerState];

        if (_timerControlsShowing) {

            [self _updateTimerControls:YES];
        }
    }
}

- (void)_stepperValueDidChange:(TranquilModuleStepper *)sender
{
    if (_timerButtonViewController.enabled) {

        BOOL enabled = sender.value > 0;
        [_module updateDisableTimerWithTimeInterval:sender.value enable:enabled];
        [self _configureTimerControllerState];
    }
}

- (void)_sliderValueDidChange:(UISlider *)sender
{
    _lastVolume = 0;
    [_module setVolume:sender.value];
    [self _configureVolumeControllerState];
}

- (void)_sliderDidEndDrag:(UISlider *)sender
{
    [_module setVolume:sender.value];
    [_module updatePreferencesExternally];
}

- (BOOL)controlsAreShowing
{
    return _timerControlsShowing || _volumeControlsShowing;
}

- (void)subtractOneMinuteFromTimerControl
{
    [_timerStepper setValue:_timerStepper.value = 60];
}

- (void)updateTimerControlWithTimeInterval:(NSTimeInterval)interval
{
    [_timerStepper setValue:(NSInteger) interval];
}

- (void)updateVolumeState
{
    [_volumeSlider setValue:[_module getVolume] animated:YES];
    [self _configureVolumeControllerState];
}

- (void)updatePlaybackState
{
    [self _configurePlaybackControllerState];
}

- (void)updateTimerState
{
    [self _configureTimerControllerState];
}

- (void)_setButton:(CCUIRoundButton *)button tintColor:(UIColor *)tintColor {
    if ([button respondsToSelector:@selector(highlightTintColor)]) {
        button.highlightTintColor = tintColor;
    } else {
        button.glyphImageView.tintColor = tintColor;
    }
}

- (void)_configureVolumeControllerState
{
    float split = 1.f / 3;
    float value = _volumeSlider.value;
    BOOL enabled = value > 0;
    NSString *glyphName = (value <= 0) ? @"VolumeMute"
            : (value > 0 && value < split) ? @"VolumeLow"
            : (value >= split && value < (split * 2)) ? @"VolumeHigh"
            : (value >= (split * 2)) ? @"VolumeMax"
            : @"VolumeMute";

    [_volumeButtonViewController setGlyphImage:[UIImage tranquil_moduleImageNamed:glyphName]];
    [_volumeButtonViewController setEnabled:enabled];
    [_volumeButtonViewController.button setNeedsLayout];
    [_volumeButtonViewController setTitle:[NSString stringWithFormat:Localize(@"VOLUME_STATUS_LABEL"), (int)(value * 100)]];
    [self _setButton:(CCUIRoundButton *)_volumeButtonViewController.button tintColor:enabled ? UIColor.whiteColor : UIColor.blackColor];
}

- (void)_configurePlaybackControllerState
{
    NSString *glyphName = [_module isPlaying] ? @"Stop" : @"Play";
    [_playbackButtonViewController setGlyphImage:[UIImage tranquil_moduleImageNamed:glyphName]];
    [_playbackButtonViewController.button setNeedsLayout];
}

- (void)_configureTimerControllerState
{
    BOOL timerRunning = _module.isTimerRunning;
    [_timerButtonViewController setEnabled:timerRunning];
    [_timerButtonViewController setTitle:[NSString stringWithFormat:Localize(@"TIMER_STATUS_LABEL"), Localize(timerRunning ? @"STATUS_ON" : @"STATUS_OFF")]];
}

- (void)_updateVolumeControls:(BOOL)animated
{
    [self _updateControlType:TMControlTypeVolume animated:animated opening:!_volumeControlsShowing];
}

- (void)_updateTimerControls:(BOOL)animated
{
    [self _updateControlType:TMControlTypeTimer animated:animated opening:!_timerControlsShowing];
}

// some ugly multi-element animation, works great, looks like hell though
- (void)_updateControlType:(TMControlType)type animated:(BOOL)animated opening:(BOOL)opening
{
    if (type == TMControlTypePlayback) return;

    TMLayoutDirection direction = [self _currentLayoutDirection];
    BOOL isVolume = type == TMControlTypeVolume;
    CGAffineTransform buttonTransform = opening
            ? CGAffineTransformScale(CGAffineTransformIdentity, 0.8519, 0.8519)
            : CGAffineTransformIdentity;

    void (^updateAlpha)(void) = ^{
        self->_playbackButtonViewController.view.alpha = !opening;
        (isVolume ? (UIControl*)self->_volumeSlider : (UIControl*)self->_timerStepper).enabled = opening;
        (isVolume ? self->_volumeControlContainer : self->_timerControlContainer).alpha = opening;
        (isVolume ? self->_timerButtonViewController : self->_volumeButtonViewController).view.alpha = !opening;
    };

    void (^updateLayout)(void) = ^{
        switch (direction) {
            case TMLayoutDirectionVertical: {
                CGFloat controlWidth = (UIEdgeInsetsInsetRect(self.view.bounds, self.view.layoutMargins).size.width - 76);
                (isVolume ? self->_volumeControlContainerTrailingAnchor : self->_timerControlContainerLeadingAnchor).constant = opening ? 0 : NEGATE_IF(controlWidth, isVolume);
                (isVolume ? self->_volumeControlLeadingAnchor : self->_timerControlTrailingAnchor).constant = opening ? NEGATE_IF(65, !isVolume) : NEGATE_IF(3, !isVolume);
                (isVolume ? self->_volumeButtonWidthAnchor : self->_timerButtonWidthAnchor).constant = opening ? 54 : 108;
            }   break;
            case TMLayoutDirectionHorizontal: {
                CGFloat controlHeight = (UIEdgeInsetsInsetRect(self.view.bounds, self.view.layoutMargins).size.height - 76);
                (isVolume ? self->_volumeControlContainerBottomAnchor : self->_timerControlContainerTopAnchor).constant = opening ? 0 : NEGATE_IF(controlHeight, isVolume);
                (isVolume ? self->_volumeControlTopAnchor : self->_timerControlBottomAnchor).constant = opening ? NEGATE_IF(65, !isVolume) : NEGATE_IF(3, !isVolume);
                (isVolume ? self->_volumeButtonWidthAnchor : self->_timerButtonWidthAnchor).constant = 108;
            }   break;
        }

        CCUILabeledRoundButtonViewController *controller = (isVolume ? self->_volumeButtonViewController : self->_timerButtonViewController);

        controller.view.transform = buttonTransform;
        controller.useAlternateBackground = opening;

        UIColor *tintColor =  controller.button.selected || !opening ? UIColor.whiteColor : UIColor.blackColor;
        [self _setButton:(CCUIRoundButton *)controller.button tintColor:tintColor];

        [self.view layoutIfNeeded];
    };

    _controlDismissRecognizer.enabled = opening;
    if (isVolume) _volumeControlsShowing = opening;
    else _timerControlsShowing = opening;

    [_volumeButtonViewController setLabelsVisible:!opening];
    [_playbackButtonViewController setLabelsVisible:!opening];
    [_timerButtonViewController setLabelsVisible:!opening];

    if (animated) {

        UIViewAnimationOptions options = UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction;
        [UIView animateWithDuration:opening ? 0.16 : 0.3 delay:opening ? 0 : 0.2 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:options animations:updateAlpha completion:nil];
        [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:options animations:updateLayout completion:nil];

    } else {

        updateAlpha();
        updateLayout();
    }
}

- (TMLayoutDirection)_currentLayoutDirection
{
    return [self _layoutDirectionForSize:self.view.bounds.size];
}

- (TMLayoutDirection)_layoutDirectionForSize:(CGSize)size
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {

        return TMLayoutDirectionVertical;
    }

    return (size.height > size.width) ? TMLayoutDirectionVertical : TMLayoutDirectionHorizontal;
}

- (void)updateConstraintsForLayoutDirection:(TMLayoutDirection)direction
{
    switch (direction) {
        case TMLayoutDirectionVertical: {

            [_volumeSlider setDirection:RTLLayout(self.view) ? TMSSliderDirectionRightToLeft : TMSSliderDirectionLeftToRight];
            [_timerStepper setDirection:TMStepperLayoutDirectionHorizontal];
            [NSLayoutConstraint deactivateConstraints:_horizontalConstraints];
            [self.view removeConstraints:_horizontalConstraints];
            [NSLayoutConstraint activateConstraints:_verticalConstraints];

        }   break;
        case TMLayoutDirectionHorizontal: {

            [_volumeSlider setDirection:TMSSliderDirectionBottomToTop];
            [_timerStepper setDirection:TMStepperLayoutDirectionVertical];
            [NSLayoutConstraint deactivateConstraints:_verticalConstraints];
            [self.view removeConstraints:_verticalConstraints];
            [NSLayoutConstraint activateConstraints:_horizontalConstraints];

        }   break;
    }

    // ensure controls are collapsed, and layout is ready for presentation
    [self _updateControlType:TMControlTypeTimer animated:NO opening:NO];
    [self _updateControlType:TMControlTypeVolume animated:NO opening:NO];

    [self.view setNeedsLayout];
}

- (void)_configureConstraints
{
    // perform a layout pass on the playback button so we can fetch its height
    [_playbackButtonViewController.view layoutIfNeeded];

    CGFloat buttonViewWidth = 108;
    CGFloat bottomMargin = -88;
    CGFloat fixedHeight = _playbackButtonViewController.button.bounds.size.height;
    CGFloat openHeight = fixedHeight - 8;
    CGFloat margin = 38;
    UILayoutGuide *marginsGuide = self.view.layoutMarginsGuide;

    _timerButtonWidthAnchor = [_timerButtonViewController.view.widthAnchor constraintEqualToConstant:buttonViewWidth];
    _volumeButtonWidthAnchor = [_volumeButtonViewController.view.widthAnchor constraintEqualToConstant:buttonViewWidth];

    _timerControlTrailingAnchor = [_timerStepper.trailingAnchor constraintEqualToAnchor:_timerControlContainer.trailingAnchor constant:-65];
    _volumeControlLeadingAnchor = [_volumeSlider.leadingAnchor constraintEqualToAnchor:_volumeControlContainer.leadingAnchor constant:65];
    _timerControlContainerLeadingAnchor = [_timerControlContainer.leadingAnchor constraintEqualToAnchor:_controlContainer.leadingAnchor];
    _volumeControlContainerTrailingAnchor = [_volumeControlContainer.trailingAnchor constraintEqualToAnchor:_controlContainer.trailingAnchor];

    _verticalConstraints = @[
            _timerControlTrailingAnchor,
            _volumeControlLeadingAnchor,
            _timerButtonWidthAnchor,
            _volumeButtonWidthAnchor,
            _timerControlContainerLeadingAnchor,
            _volumeControlContainerTrailingAnchor,
            [_controlContainer.heightAnchor constraintEqualToConstant:fixedHeight],
            [_controlContainer.centerYAnchor constraintEqualToAnchor:marginsGuide.bottomAnchor constant:bottomMargin],
            [_controlContainer.leadingAnchor constraintEqualToAnchor:marginsGuide.leadingAnchor constant:margin],
            [_controlContainer.trailingAnchor constraintEqualToAnchor:marginsGuide.trailingAnchor constant:-margin],
            [_timerControlContainer.trailingAnchor constraintEqualToAnchor:_controlContainer.trailingAnchor],
            [_timerControlContainer.centerYAnchor constraintEqualToAnchor:_controlContainer.centerYAnchor],
            [_timerControlContainer.heightAnchor constraintEqualToConstant:fixedHeight],
            [_volumeControlContainer.leadingAnchor constraintEqualToAnchor:_controlContainer.leadingAnchor],
            [_volumeControlContainer.centerYAnchor constraintEqualToAnchor:_controlContainer.centerYAnchor],
            [_volumeControlContainer.heightAnchor constraintEqualToConstant:fixedHeight],
            [_volumeSlider.heightAnchor constraintEqualToConstant:openHeight],
            [_volumeSlider.trailingAnchor constraintEqualToAnchor:_volumeControlContainer.trailingAnchor constant:-4],
            [_volumeSlider.centerYAnchor constraintEqualToAnchor:_volumeControlContainer.centerYAnchor],
            [_timerStepper.leadingAnchor constraintEqualToAnchor:_timerControlContainer.leadingAnchor constant:4],
            [_timerStepper.topAnchor constraintEqualToAnchor:_timerControlContainer.topAnchor constant:4],
            [_timerStepper.bottomAnchor constraintEqualToAnchor:_timerControlContainer.bottomAnchor constant:-4],
            [_volumeButtonViewController.view.heightAnchor constraintEqualToConstant:fixedHeight],
            [_volumeButtonViewController.view.centerXAnchor constraintEqualToAnchor:_controlContainer.leadingAnchor constant:(fixedHeight * 0.5f)],
            [_volumeButtonViewController.view.topAnchor constraintEqualToAnchor:_controlContainer.topAnchor],
            [_playbackButtonViewController.view.heightAnchor constraintEqualToConstant:fixedHeight],
            [_playbackButtonViewController.view.widthAnchor constraintEqualToConstant:buttonViewWidth],
            [_playbackButtonViewController.view.centerXAnchor constraintEqualToAnchor:_controlContainer.centerXAnchor],
            [_playbackButtonViewController.view.topAnchor constraintEqualToAnchor:_controlContainer.topAnchor],
            [_timerButtonViewController.view.heightAnchor constraintEqualToConstant:fixedHeight],
            [_timerButtonViewController.view.centerXAnchor constraintEqualToAnchor:_controlContainer.trailingAnchor constant:-(fixedHeight * 0.5f)],
            [_timerButtonViewController.view.topAnchor constraintEqualToAnchor:_controlContainer.topAnchor],
    ];

    _timerControlBottomAnchor = [_timerStepper.bottomAnchor constraintEqualToAnchor:_timerControlContainer.bottomAnchor constant:-65];
    _volumeControlTopAnchor = [_volumeSlider.topAnchor constraintEqualToAnchor:_volumeControlContainer.topAnchor constant:65];
    _timerControlContainerTopAnchor = [_timerControlContainer.topAnchor constraintEqualToAnchor:_controlContainer.topAnchor];
    _volumeControlContainerBottomAnchor = [_volumeControlContainer.bottomAnchor constraintEqualToAnchor:_controlContainer.bottomAnchor];

    _horizontalConstraints = @[
            _timerControlBottomAnchor,
            _volumeControlTopAnchor,
            _timerButtonWidthAnchor,
            _volumeButtonWidthAnchor,
            _timerControlContainerTopAnchor,
            _volumeControlContainerBottomAnchor,
            [_controlContainer.widthAnchor constraintEqualToConstant:fixedHeight],
            [_controlContainer.centerXAnchor constraintEqualToAnchor:marginsGuide.trailingAnchor constant:bottomMargin],
            [_controlContainer.topAnchor constraintEqualToAnchor:marginsGuide.topAnchor constant:margin],
            [_controlContainer.bottomAnchor constraintEqualToAnchor:marginsGuide.bottomAnchor constant:-margin],
            [_timerControlContainer.bottomAnchor constraintEqualToAnchor:_controlContainer.bottomAnchor],
            [_timerControlContainer.centerXAnchor constraintEqualToAnchor:_controlContainer.centerXAnchor],
            [_timerControlContainer.widthAnchor constraintEqualToConstant:fixedHeight],
            [_volumeControlContainer.topAnchor constraintEqualToAnchor:_controlContainer.topAnchor],
            [_volumeControlContainer.centerXAnchor constraintEqualToAnchor:_controlContainer.centerXAnchor],
            [_volumeControlContainer.widthAnchor constraintEqualToConstant:fixedHeight],
            [_volumeSlider.widthAnchor constraintEqualToConstant:openHeight],
            [_volumeSlider.bottomAnchor constraintEqualToAnchor:_volumeControlContainer.bottomAnchor constant:-4],
            [_volumeSlider.centerXAnchor constraintEqualToAnchor:_volumeControlContainer.centerXAnchor],
            [_timerStepper.topAnchor constraintEqualToAnchor:_timerControlContainer.topAnchor constant:4],
            [_timerStepper.leadingAnchor constraintEqualToAnchor:_timerControlContainer.leadingAnchor constant:4],
            [_timerStepper.trailingAnchor constraintEqualToAnchor:_timerControlContainer.trailingAnchor constant:-4],
            [_volumeButtonViewController.view.heightAnchor constraintEqualToConstant:fixedHeight],
            [_volumeButtonViewController.view.topAnchor constraintEqualToAnchor:_controlContainer.topAnchor],
            [_volumeButtonViewController.view.centerXAnchor constraintEqualToAnchor:_controlContainer.centerXAnchor],
            [_playbackButtonViewController.view.widthAnchor constraintEqualToConstant:buttonViewWidth],
            [_playbackButtonViewController.view.heightAnchor constraintEqualToConstant:fixedHeight],
            [_playbackButtonViewController.view.centerXAnchor constraintEqualToAnchor:_controlContainer.centerXAnchor],
            [_playbackButtonViewController.view.centerYAnchor constraintEqualToAnchor:_controlContainer.centerYAnchor],
            [_timerButtonViewController.view.heightAnchor constraintEqualToConstant:fixedHeight],
            [_timerButtonViewController.view.bottomAnchor constraintEqualToAnchor:_controlContainer.bottomAnchor],
            [_timerButtonViewController.view.centerXAnchor constraintEqualToAnchor:_controlContainer.centerXAnchor]
    ];

    SetCornerRadiusLayer(_timerControlContainer.layer, fixedHeight / 2);
    SetCornerRadiusLayer(_volumeControlContainer.layer, fixedHeight / 2);
}

- (CCUILabeledRoundButtonViewController *)_labeledRoundButtonControllerWithGlyph:(NSString *)glyphName highlightColor:(UIColor *)color initialState:(BOOL)state useLongPress:(BOOL)useLongPress
{
    CCUILabeledRoundButtonViewController *controller = [[CCUILabeledRoundButtonViewController alloc] initWithGlyphImage:[UIImage tranquil_moduleImageNamed:glyphName] highlightColor:color];
    [controller.button addTarget:self action:@selector(_buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [controller.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [controller.buttonContainer setLabelsVisible:YES];
    [controller setToggleStateOnTap:NO];
    [controller setEnabled:state];

    if (useLongPress) {

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_buttonPressed:)];
        [longPress setMinimumPressDuration:0.2];
        [longPress setCancelsTouchesInView:YES];
        [controller.button addGestureRecognizer:longPress];
    }

    if ([controller respondsToSelector:@selector(useAlternateBackground)]) {

        [controller setUseAlternateBackground:NO];
    }

    [self addChildViewController:controller];

    return controller;
}

- (BOOL)_canShowWhileLocked
{
    return YES;
}

@end
