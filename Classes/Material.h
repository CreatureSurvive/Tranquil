//
//  Material.h
//  Tranquil
//
//  Created by Dana Buehre on 3/22/22.
//
//

#import <UIKit/UIView.h>

@interface MTMaterialView : UIView
+ (MTMaterialView *)materialViewWithRecipe:(NSInteger)recipe configuration:(NSInteger)configuration;
+ (MTMaterialView *)materialViewWithRecipe:(NSInteger)recipe options:(NSUInteger)options;
@end

@interface MTVisualStylingProvider : NSObject
+ (Class)_visualStylingClass;
+ (id)_visualStylingProviderForStyleSetNamed:(NSString *)styleSetName inBundle:(NSBundle *)bundle;
+ (id)_visualStylingProviderForRecipe:(NSInteger)recipe andCategory:(NSInteger)category;
+ (id)_visualStylingProviderForRecipeNamed:(NSString *)recipeName andCategory:(NSInteger)category;
+ (id)_visualStylingProviderForRecipe:(NSInteger)recipe category:(NSInteger)category andUserInterfaceStyle:(NSInteger)arg3;
@end

NS_INLINE __unused MTMaterialView *ControlCenterMaterialWithConfiguration(NSInteger configuration, NSUInteger legacyOptions)
{
    NSInteger controlCenterRecipe = 4;
    Class _MTMaterialView = NSClassFromString(@"MTMaterialView");

    if ([_MTMaterialView respondsToSelector:@selector(materialViewWithRecipe:configuration:)]) {

        return [_MTMaterialView materialViewWithRecipe:controlCenterRecipe configuration:configuration];
    }

    return [_MTMaterialView materialViewWithRecipe:controlCenterRecipe options:legacyOptions];
}

NS_INLINE __unused MTMaterialView *ControlCenterBackgroundMaterial()
{
    return ControlCenterMaterialWithConfiguration(2, 1);
}

NS_INLINE __unused MTMaterialView *ControlCenterForegroundMaterial()
{
    return ControlCenterMaterialWithConfiguration(1, 2);
}

NS_INLINE __unused MTMaterialView *ControlCenterVibrantLightMaterial()
{
    return ControlCenterMaterialWithConfiguration(3, 32);
}

NS_INLINE __unused MTVisualStylingProvider *ControlCenterStylingProvider()
{
    Class _MTVisualStylingProvider = NSClassFromString(@"MTVisualStylingProvider");
    return [_MTVisualStylingProvider _visualStylingProviderForStyleSetNamed:@"moduleStyle" inBundle:[NSBundle bundleForClass:_MTVisualStylingProvider]];
};
