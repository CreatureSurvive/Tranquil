//
//  TranquilModuleContentViewController.m
//  Tranquil
//
//  Created by Dana Buehre on 3/8/22.
//
//

#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>
#import "TranquilModuleContentViewController.h"
#import "TranquilModule.h"
#import "TranquilRoutePickerView.h"
#import "TranquilRoutingViewController.h"
#import "UIImage+TranquilModule.h"
#import "Prefix.h"
#import "Material.h"
#import "AVRouting.h"
#import "Haptic.h"

@interface TranquilModuleContentViewController () <AVRoutePickerViewDelegate, MPAVRoutingViewControllerThemeDelegate>
{

    NSMutableDictionary *_checkmarksByID;
    BOOL _isExpanded;

    BOOL _isRoutingViewHidden;
    AVRouteDetector *_routeDetector;
    TranquilRoutePickerView *_routePicker;
    MTMaterialView *_routingViewContainerView;
    TranquilRoutingViewController *_routingViewController;
    NSLayoutConstraint *_routingViewHeightConstraint;
}

@end

@implementation TranquilModuleContentViewController

- (instancetype)initWithNibName:(NSString *)name bundle:(NSBundle *)bundle
{
	if (self = [super initWithNibName:name bundle:bundle]) {

        self.title = Localize(@"PROJECT_NAME");
        self.glyphImage = [UIImage tranquil_moduleImageNamed:@"Icon"];
        self.selectedGlyphColor = [UIColor systemBlueColor];
    }

	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self _configureRoutePicker];
}

#pragma mark - CCUIMenuModuleViewController

- (void)buttonTapped:(id)arg1 forEvent:(id)arg2
{
    // toggle playback on module button tap
	BOOL newState = ![self isSelected];

    if (newState) {

        [_module resumeTrack];

    } else {

        [_module stopTrack];
    }
    
    [self setSelected:[_module isPlaying]];
}

// handle item selection gestures
- (void)_handlePressGesture:(UIGestureRecognizer *)sender
{
    if (!_isRoutingViewHidden) {
        
        // prevent item selection when the route picker is blocking the item stack
        if (CGRectContainsPoint(_routingViewContainerView.frame, [sender locationInView:self.contentView])) {

            return;
        }
    }
    
    // prevent item selection on iOS <= 12 when outside the view bounds
    if (!CGRectContainsPoint(self.view.frame, [sender locationInView:self.view])) {
        
        return;
    }
    
    [super _handlePressGesture:sender];
}

// this will hide the chin when the picker is expanded
// currently unknown if iOS 11 has a chin, and this is only available on iOS >= 12
- (BOOL)_shouldShowFooterChin {

    return NO;
}

- (void)setSelected:(BOOL)selected
{
    // prevent highlighting the glyph when expanded
    [super setSelected:_isExpanded ? NO : selected];
    [_routePicker setHidden:!_isExpanded];
}

- (void)setExpanded:(BOOL)expanded
{
    // track our own expanded state, and update glyph highlighting
    // to ensure that the glyph is not highlighted while expanded
    _isExpanded = expanded;
    [self setSelected:[_module isPlaying]];
}

- (CGFloat)preferredExpandedContentHeight
{
    // ensure the height does not exceed the safe area bounds
    UIView *background = _module.backgroundViewController.view;
    UIEdgeInsets insets = UIEdgeInsetsMake(32, 32, 32, 32);
    CGFloat max = UIEdgeInsetsInsetRect(background.bounds, insets).size.height;
    return MIN(375, max);
}

- (BOOL)shouldBeginTransitionToExpandedContentModule 
{
    // this will return false after the first expansion,
    // so it's overridden to always allow expansion
    return YES;
}

- (void)willTransitionToExpandedContentMode:(BOOL)expand
{
    [super willTransitionToExpandedContentMode:expand];

    [self setExpanded:expand];
    [self _setRoutingViewHidden:YES animated:NO];

    if (!expand) return;

    // refresh the action items each time the module is expanded
    // this circumvents an issue where the module will automatically
    // remove actions after collapsing, as well as keeping the list
    // synchronized with any added or removed sounds.
    [self removeAllActions];

    __weak typeof(self) weakSelf = self;
    _checkmarksByID = [NSMutableDictionary new];
    NSArray *metadata = [self.module audioMetadata];
    UIStackView *menuItemsContainer = [self safeValueForKey:@"_menuItemsContainer"];

    for (NSDictionary *entry in metadata)
    {
        [self addActionWithTitle:Localize(entry[@"name"]) glyph:[UIImage tranquil_moduleImageNamed:@"Sound"] handler:^{
            [weakSelf.module playTrack:entry[@"path"]];
            [weakSelf updateItemSelection];
            return NO;
        }];

        // checkmarks are available for actions on iOS 13+, but for consistency lets use a custom implementation.
        // this will only work for later iOS versions, earlier versions will use _setupMenuItems
        if (menuItemsContainer) {

            UIView *itemView = menuItemsContainer.arrangedSubviews.lastObject;
            [self _configureCheckmarkWithKey:entry[@"path"] inItemView:itemView];
        }
    }

    if (DownloadableContentAvailable()) {

        [self addActionWithTitle:Localize(@"DOWNLOADS_AVAILABLE_TITLE") glyph:[UIImage tranquil_moduleImageNamed:@"Download"] handler:^{
            NSString *urlString;
            if (@available(iOS 13, *)) {
                urlString = [NSString stringWithFormat:@"prefs:root=ControlCenter&path=Tranquil/activeSoundSpecifier"];
            } else {
                urlString = [NSString stringWithFormat:@"prefs:root=ControlCenter&path=CUSTOMIZE_CONTROLS/Tranquil/activeSoundSpecifier"];
            }
            NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];

            OpenApplicationUrl(url);
            return NO;
        }];
    }

    [self _configureFooterButton:NO];

    [self updateItemSelection];
}

- (void)_setupMenuItems
{
    [super _setupMenuItems];

    // this will only work for earlier iOS versions, later versions will use willTransitionToExpandedContentMode:
    if (!_checkmarksByID || _checkmarksByID.count == 0) {

        _checkmarksByID = [NSMutableDictionary new];
        NSArray *metadata = [self.module audioMetadata];
        UIStackView *menuItemsContainer = [self safeValueForKey:@"_menuItemsContainer"];

        if (menuItemsContainer) {

            [metadata enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger index, BOOL *stop) {

                UIView *itemView = menuItemsContainer.arrangedSubviews[index];
                [self _configureCheckmarkWithKey:obj[@"path"] inItemView:itemView];
            }];
        }

        [self updateItemSelection];
    }
}

- (BOOL)canDismissPresentedContent
{
    // prevent background tap collapsing the module when controls are expanded
    if ([(TranquilModuleBackgroundViewController *)_module.backgroundViewController controlsAreShowing]) {

        return NO;
    }

    return YES;
}

-(BOOL)_canShowWhileLocked
{
	return YES;
}

#pragma mark - TranquilContentViewController

- (void)updateItemSelection
{
    // use layer opacity rather than view alpha/hidden to avoid itemView from overriding changes
    // makeObjectsPerformSelector:withObject: does not always work as expected, so use a loop instead
    for (CALayer *checkmark in _checkmarksByID.allValues) { [checkmark setOpacity:0]; }
    [_checkmarksByID[[_module.preferences stringForKey:@"kActiveSound"]] setOpacity:1];
}

- (BOOL)_isStackConfigured
{
    return _checkmarksByID && _checkmarksByID.count;
}

- (void)_configureFooterButton:(BOOL)hidden
{
    if (hidden) {
        
        [self removeFooterButton];
        return;
    }
    
    [self setFooterButtonTitle:Localize(@"PROJECT_SETTINGS_TITLE") handler:^{
        NSString *urlString;
        if (@available(iOS 13, *)) {
            urlString = [NSString stringWithFormat:@"prefs:root=ControlCenter&path=Tranquil"];
        } else {
            urlString = [NSString stringWithFormat:@"prefs:root=ControlCenter&path=CUSTOMIZE_CONTROLS/Tranquil"];
        }
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];

        OpenApplicationUrl(url);
        return NO;
    }];
}

- (void)_configureCheckmarkWithKey:(NSString *)key inItemView:(UIView *)view
{
    if (!view) return;

    UIImage *checkmarkImage = [UIImage tranquil_moduleImageNamed:@"Checkmark"];
    UIImageView *checkmark = [[UIImageView alloc] initWithImage:checkmarkImage];
    [checkmark setTranslatesAutoresizingMaskIntoConstraints:NO];
    [checkmark setContentMode:UIViewContentModeScaleAspectFill];
    [checkmark.layer setOpacity:0];
    _checkmarksByID[key] = checkmark.layer;

    [view addSubview:checkmark];

    [NSLayoutConstraint activateConstraints:@[
            [checkmark.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-8],
            [checkmark.centerYAnchor constraintEqualToAnchor:view.centerYAnchor],
            // actual size is closer to 17x17, but the itemView forces some strange upscaling
            [checkmark.heightAnchor constraintEqualToConstant:13],
            [checkmark.widthAnchor constraintEqualToConstant:13]
    ]];
}

- (void)_configureRoutePicker
{
    // routing view background blur
    _routingViewContainerView = ControlCenterForegroundMaterial();
    [_routingViewContainerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    _routingViewController = [TranquilRoutingViewController new];
    [_routingViewController setParentController:self];
    [_routingViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // route detector for detecting route changes
    _routeDetector = [AVRouteDetector new];
    [_routeDetector setRouteDetectionEnabled:YES];
    
    // route picker button for animated route state
    // action is overridden to show MPAVRoutingViewController
    _routePicker = [TranquilRoutePickerView new];
    [_routePicker setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_routePicker setDelegate:self];
    
    [self addChildViewController:_routingViewController];
    [_routingViewController didMoveToParentViewController:self];
    
    [self.view addSubview:_routePicker];
    [self.contentView addSubview:_routingViewContainerView];
    [_routingViewContainerView addSubview:_routingViewController.view];
    
    // set custom action for route picker button to show MPAVRoutingViewController
    [_routePicker.routePickerButton addTarget:self action:@selector(_toggleRoutingView:) forControlEvents:UIControlEventTouchUpInside];
    
    _routingViewHeightConstraint = [_routingViewContainerView.heightAnchor constraintEqualToConstant:0];
    
    [NSLayoutConstraint activateConstraints:@[
        [_routePicker.widthAnchor constraintEqualToConstant:36],
        [_routePicker.heightAnchor constraintEqualToConstant:36],
        [_routePicker.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:16],
        [_routePicker.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [_routingViewController.view.bottomAnchor constraintEqualToAnchor:_routingViewContainerView.bottomAnchor],
        [_routingViewController.view.topAnchor constraintLessThanOrEqualToAnchor:_routingViewContainerView.topAnchor],
        [_routingViewController.view.leadingAnchor constraintEqualToAnchor:_routingViewContainerView.leadingAnchor],
        [_routingViewController.view.trailingAnchor constraintEqualToAnchor:_routingViewContainerView.trailingAnchor],
        [_routingViewContainerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
        [_routingViewContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [_routingViewContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        _routingViewHeightConstraint
    ]];

    [self _setRoutingViewHidden:YES animated:NO];
}


- (void)_toggleRoutingView:(UIButton *)sender
{
    BOOL newState = !_isRoutingViewHidden;
    HapticSelection();

    [self _setRoutingViewHidden:newState animated:YES];
}

- (void)_setRoutingViewHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (_isExpanded) {
        
        // causes layout issues on iOS <= 12 if the stack is not configured first
        if ([self _isStackConfigured]) {
            
            [self _configureFooterButton:!hidden];
        }
        
        [_routingViewContainerView setHidden:NO];
        [_routingViewContainerView setUserInteractionEnabled:!hidden];
    }
        
    [self.contentView bringSubviewToFront:_routingViewContainerView];

    NSTimeInterval duration = animated ? 0.333 : 0;
    UIColor *pickerTint = hidden ? UIColor.whiteColor : UIColor.blackColor;
    // TODO check if layout height is correct on iOS 11, footer chin may be shown?
    CGFloat pickerHeight = hidden ? 0 : CGRectGetHeight(self.view.bounds) - self.headerHeight;

    _isRoutingViewHidden = hidden;
    _routingViewHeightConstraint.constant = pickerHeight;

    [_routingViewController beginAppearanceTransition:!hidden animated:animated];

    [UIView animateWithDuration:duration animations:^{
        [self->_routePicker setTintColor:pickerTint];
        [self->_routePicker.backgroundView setAlpha:!hidden];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self->_routingViewContainerView setHidden:hidden];
        [self->_routingViewController endAppearanceTransition];
    }];
}

@end
