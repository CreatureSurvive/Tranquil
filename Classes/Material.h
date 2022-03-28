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