//
//  TranquilModuleStepper.h
//  Tranquil
//
//  Created by Dana Buehre on 3/14/22.
//
//

#import <UIKit/UIControl.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TMStepperLayoutDirection)
{
    TMStepperLayoutDirectionVertical = 0,
    TMStepperLayoutDirectionHorizontal = 1
};

@interface TranquilModuleStepper : UIControl

@property (nonatomic) NSInteger value;
@property (nonatomic) NSInteger stepValue;
@property (nonatomic) NSInteger minValue;
@property (nonatomic) NSInteger maxValue;
@property (nonatomic) BOOL continuous;
@property (nonatomic) TMStepperLayoutDirection direction;

- (void)setLabelTextColor:(UIColor *)color;
- (void)setIncrementButtonBackgroundColor:(UIColor *)color;
- (void)setDecrementButtonBackgroundColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
