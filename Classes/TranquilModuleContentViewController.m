//
//  TranquilModuleContentViewController.m
//  Tranquil
//
//  Created by Dana Buehre on 3/8/22.
//
//

#import "TranquilModuleContentViewController.h"
#import "TranquilModule.h"
#import "UIImage+TranquilModule.h"
#import "Prefix.h"

@interface NSObject ()
- (id)safeValueForKey:(NSString *)key;
@end

@interface TranquilModuleContentViewController () {

    NSMutableDictionary *_checkmarksByID;
    BOOL _isExpanded;
}

@end

@implementation TranquilModuleContentViewController

- (instancetype)initWithNibName:(NSString *)name bundle:(NSBundle *)bundle
{
	if (self = [super initWithNibName:name bundle:bundle]) {

        self.title = Localize(@"PROJECT_NAME");
        self.glyphImage = [UIImage tranquil_moduleImageNamed:@"Icon"];
        self.selectedGlyphColor = [UIColor systemGrayColor];
    }

	return self;
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

- (void)setSelected:(BOOL)selected
{
    // prevent highlighting the glyph when expanded
    [super setSelected:_isExpanded ? NO : selected];
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

@end
