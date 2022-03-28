//
//  TranquilModule.h
//  Tranquil
//
//  Created by Dana Buehre on 3/9/22.
//
//

#import "TranquilModuleContentViewController.h"
#import "TranquilModuleBackgroundViewController.h"

#import <ControlCenterUIKit/CCUIContentModule.h>

@interface TranquilModule : NSObject <CCUIContentModule> {

	TranquilModuleContentViewController* _contentViewController;
    TranquilModuleBackgroundViewController* _backgroundViewController;
}

@property (nonatomic, strong) NSUserDefaults *preferences;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) BOOL isTimerRunning;

- (NSBundle *)moduleBundle;
- (NSArray <NSDictionary *> *)audioMetadata;
- (void)refreshState;
- (void)updatePreferences;
- (void)updatePreferencesExternally;

- (void)updateDisableTimerWithTimeInterval:(NSTimeInterval)interval enable:(BOOL)enabled;

- (void)playTrack:(NSString *)filePath;
- (void)stopTrack;
- (void)resumeTrack;
- (float)getVolume;
- (void)setVolume:(float)volume;

@end