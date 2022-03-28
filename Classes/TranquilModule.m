//
//  TranquilModule.m
//  Tranquil
//
//  Created by Dana Buehre on 3/9/22.
//
//

#import "TranquilModule.h"
#import "TranquilMediaPlayer.h"
#import "Prefix.h"

#import <AVFoundation/AVFoundation.h>
#import <ControlCenterUI/CCUIModuleInstance.h>
#import <ControlCenterUI/CCUIModuleInstanceManager.h>

@interface CCUIModuleInstanceManager (CCSupport)
- (CCUIModuleInstance*)instanceForModuleIdentifier:(NSString*)moduleIdentifier;
@end

@implementation TranquilModule {

    NSTimer *_disableTimer;
    NSTimer *_disableTimerUpdater;
}

- (instancetype)init
{
	if (self = [super init]) {

        _contentViewController = [TranquilModuleContentViewController new];
        _contentViewController.module = self;

        _backgroundViewController = [TranquilModuleBackgroundViewController new];
        _backgroundViewController.module = self;

        _preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.creaturecoding.tranquil"];

        // disable playback after respring / reload
        [_preferences setBool:NO forKey:@"kBackgroundSoundsActive"];

        [self updateDefaults];
        [self updatePreferences];

        [TranquilMediaPlayer setModule:self];

        __weak typeof(self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionRouteChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {

            if ([weakSelf.preferences boolForKey:@"kPauseOnRouteChange"]) {

                [weakSelf stopTrack];
            }
        }];
    }

	return self;
}

- (UIViewController <CCUIContentModuleContentViewController> *)contentViewController
{
	return _contentViewController;
}

- (UIViewController *)backgroundViewController
{
	return _backgroundViewController;
}

- (NSBundle *)moduleBundle 
{
	return [NSBundle bundleForClass:self.class];
}

- (NSArray <NSDictionary *> *)audioMetadata
{
    return AudioMetadata([self moduleBundle].bundlePath);
}

- (void)refreshState
{
    BOOL pauseForEvent = [_preferences boolForKey:@"kPauseForSample"] || [_preferences boolForKey:@"kPauseForDownload"];

    if (pauseForEvent) {

        [TranquilMediaPlayer pauseForSample];
        [_contentViewController setSelected:NO];
        [_backgroundViewController updateVolumeState];
        [_backgroundViewController updatePlaybackState];
        [_backgroundViewController updateTimerState];
        return;
    }

    _isPlaying = [_preferences boolForKey:@"kBackgroundSoundsActive"];
    float activeVolume = [self getVolume];

    [_contentViewController setSelected:_isPlaying];
    [_backgroundViewController updateVolumeState];
    [_backgroundViewController updatePlaybackState];
    [_backgroundViewController updateTimerState];
    [TranquilMediaPlayer setVolume:activeVolume];

    if (_isPlaying) {

        [TranquilMediaPlayer play:[_preferences stringForKey:@"kActiveSound"] volume:activeVolume withCompletion:^(BOOL isPlaying) {
            // in the event that the last active sound cannot be played, revert to the default sound
             if (!isPlaying)
             {
                 NSString *defaultSound = DefaultValueForKey(@"kActiveSound");
                 if (![defaultSound isEqualToString:[_preferences stringForKey:@"kActiveSound"]])
                 {
                     [_preferences setObject:defaultSound forKey:@"kActiveSound"];
                     [self updatePreferencesExternally];
                     [self refreshState];
                 }
             }

             [_contentViewController updateItemSelection];
        }];

    } else if ([TranquilMediaPlayer isPlaying]) {

        [TranquilMediaPlayer stop];
    }
}

- (void)updatePreferences 
{
    [self refreshState];
}

- (void)updatePreferencesExternally
{
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.creaturecoding.tranquil/preferences-changed-externally"), NULL, NULL, TRUE);
}

- (void)updateDefaults
{
    __block BOOL defaultsUpdated = NO;
    NSDictionary *defaults = Defaults();

    [defaults enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if (![self->_preferences objectForKey:key]) {

            [self->_preferences setObject:obj forKey:key];
            defaultsUpdated = YES;
        }
    }];

    if (defaultsUpdated) {

        [_preferences synchronize];
    }
}

- (void)updateDisableTimerWithTimeInterval:(NSTimeInterval)interval enable:(BOOL)enabled
{
    if (_disableTimer) {

        [_disableTimer invalidate];
        _disableTimer = nil;
    }

    if (_disableTimerUpdater) {

        [_disableTimerUpdater invalidate];
        _disableTimerUpdater = nil;
    }

    if (enabled) {

        _disableTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(disableTimerDidFire) userInfo:nil repeats:NO];
        _disableTimerUpdater = [NSTimer scheduledTimerWithTimeInterval:60 target:_backgroundViewController selector:@selector(subtractOneMinuteFromTimerControl) userInfo:nil repeats:YES];
    }
}

- (void)disableTimerDidFire
{
    [_disableTimer invalidate];
    _disableTimer = nil;
    [_disableTimerUpdater invalidate];
    _disableTimerUpdater = nil;
    [_backgroundViewController updateTimerControlWithTimeInterval:0];
    [self stopTrack];
    [self refreshState];
}

- (BOOL)isTimerRunning
{
    return _disableTimer != nil && _disableTimer.isValid && [_disableTimer.fireDate timeIntervalSinceNow] > 0;
}

- (void)playTrack:(NSString *)filePath
{
    [_preferences setBool:YES forKey:@"kBackgroundSoundsActive"];
    [_preferences setObject:filePath forKey:@"kActiveSound"];

    [self refreshState];
    [self updatePreferencesExternally];
}

- (void)stopTrack
{
    [_preferences setBool:NO forKey:@"kBackgroundSoundsActive"];

    [self updateDisableTimerWithTimeInterval:0 enable:NO];
    [self refreshState];
    [self updatePreferencesExternally];
}

- (void)resumeTrack
{
    [_preferences setBool:YES forKey:@"kBackgroundSoundsActive"];

    [self refreshState];
    [self updatePreferencesExternally];
}

- (float)getVolume
{
    return [_preferences floatForKey:[TranquilMediaPlayer isOtherAudioPlaying] ? @"kPlaybackVolumeWithMedia" : @"kPlaybackVolume"];
}

- (void)setVolume:(float)volume
{
    [_preferences setFloat:volume forKey:[TranquilMediaPlayer isOtherAudioPlaying] ? @"kPlaybackVolumeWithMedia" : @"kPlaybackVolume"];
    [self refreshState];
}

- (void)dealloc
{
    [TranquilMediaPlayer stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

@end

void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CCUIModuleInstance* moduleInstance = [[NSClassFromString(@"CCUIModuleInstanceManager") sharedInstance] instanceForModuleIdentifier:@"com.creaturecoding.tranquil"];
	[(TranquilModule*)moduleInstance.module updatePreferences];
}

__attribute__((constructor))
static void init(void)
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChanged, CFSTR("com.creaturecoding.tranquil/preferences-changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}