//
//  TranquilRoutePickerView.h
//  Tranquil
//
//  Created by Dana Buehre on 4/8/22.
//

#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TranquilRoutePickerView : AVRoutePickerView

@property (nonatomic, strong) UIView *backgroundView;

- (UIButton *)routePickerButton;

@end

NS_ASSUME_NONNULL_END
