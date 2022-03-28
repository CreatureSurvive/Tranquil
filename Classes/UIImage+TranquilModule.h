//
//  UIImage+TranquilModule.h
//  Tranquil
//
//  Created by Dana Buehre on 3/14/22.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImage (TranquilModule)

+ (UIImage *)tranquil_moduleImageNamed:(NSString *)imageName;
+ (UIImage *)tranquil_imageWithColor:(UIColor *)color size:(CGSize)size;

@end