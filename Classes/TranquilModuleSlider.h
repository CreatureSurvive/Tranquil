//
//  TranquilModuleSlider.h
//  Tranquil
//
//  Created by Dana Buehre on 3/20/22.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TMSSliderDirection)
{
    TMSSliderDirectionLeftToRight = 0,
    TMSSliderDirectionRightToLeft = 1,
    TMSSliderDirectionBottomToTop = 2,
    TMSSliderDirectionTopToBottom = 3
};

@interface TranquilModuleSlider : UIControl

@property (nonatomic) float value;
@property (nonatomic) NSInteger minValue;
@property (nonatomic) NSInteger maxValue;
@property (nonatomic) BOOL continuous;
@property (nonatomic) TMSSliderDirection direction;

- (void)setValue:(float)value animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
