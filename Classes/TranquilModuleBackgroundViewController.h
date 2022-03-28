//
//  TranquilModuleBackgroundViewController.h
//  Tranquil
//
//  Created by Dana Buehre on 3/9/22.
//
//

#import <ControlCenterUIKit/CCUISliderModuleBackgroundViewController.h>

@class TranquilModule, CCUISliderModuleBackgroundViewController;

@interface TranquilModuleBackgroundViewController : CCUISliderModuleBackgroundViewController

@property (nonatomic, weak) TranquilModule* module;

@property (nonatomic) BOOL volumeControlsShowing;
@property (nonatomic) BOOL timerControlsShowing;

- (BOOL)controlsAreShowing;

- (void)subtractOneMinuteFromTimerControl;
- (void)updateTimerControlWithTimeInterval:(NSTimeInterval)interval;
- (void)updateVolumeState;
- (void)updatePlaybackState;
- (void)updateTimerState;

@end