//
//  UIImage+TranquilModule.m
//  Tranquil
//
//  Created by Dana Buehre on 3/14/22.
//
//

#import "UIImage+TranquilModule.h"
#import "rootless.h"


@implementation UIImage (TranquilModule)

+ (UIImage *)tranquil_moduleImageNamed:(NSString *)imageName
{
    static NSBundle *moduleBundle;

    if (!moduleBundle) {

        moduleBundle = [NSBundle bundleWithPath:ROOT_PATH_NS(@"/Library/ControlCenter/Bundles/Tranquil.bundle")];
    }

    return [UIImage imageNamed:imageName inBundle:moduleBundle compatibleWithTraitCollection:nil];
}

+ (UIImage *)tranquil_imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return img;
}

@end