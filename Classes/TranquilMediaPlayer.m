//
//  TranquilMediaPlayer.m
//  Tranquil
//
//  Created by Dana Buehre on 3/8/22.
//
//

#import "TranquilMediaPlayer.h"
#import "TranquilModule.h"

#import <AVFoundation/AVFoundation.h>

@interface SBMediaController : NSObject

@property (assign, nonatomic) int nowPlayingProcessPID;

+ (id)sharedInstance;
- (BOOL)isPlaying;

@end

@interface TranquilMediaPlayer ()

@end

@implementation TranquilMediaPlayer {

    __strong AVAudioPlayer *_player;
    __weak TranquilModule *_module;
    NSString *_currentlyPlayingFile;
    float _volume;
    BOOL _interrupted;
    BOOL _otherAudioIsPlaying;
}

+ (TranquilMediaPlayer *)sharedInstance
{
    static dispatch_once_t once;
    static TranquilMediaPlayer *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [TranquilMediaPlayer new];

        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionMixWithOthers error:nil];
        [[NSClassFromString(@"SBMediaController") sharedInstance] addObserver:sharedInstance forKeyPath:NSStringFromSelector(@selector(nowPlayingProcessPID)) options:NSKeyValueObservingOptionNew context:NULL];
    });

    return sharedInstance;
}

+ (void)play:(NSString *)filePath volume:(float)volume
{
    [[TranquilMediaPlayer sharedInstance] play:filePath volume:volume];
}

+ (void)play:(NSString *)filePath volume:(float)volume withCompletion:(void (^_Nullable)(BOOL))completion
{
    [[TranquilMediaPlayer sharedInstance] play:filePath volume:volume withCompletion:completion];
}

+ (void)stop
{
    [[TranquilMediaPlayer sharedInstance] stop];
}

+ (BOOL)isPlaying
{
    return [[TranquilMediaPlayer sharedInstance] isPlaying];
}

+ (BOOL)isOtherAudioPlaying
{
    return [[TranquilMediaPlayer sharedInstance] isOtherAudioPlaying];
}

+ (void)setVolume:(float)volume
{
    [[TranquilMediaPlayer sharedInstance] setVolume:volume];
}

+ (void)setModule:(TranquilModule *)module
{
    [[TranquilMediaPlayer sharedInstance] setModule:module];
}

+ (void)pauseForSample
{
    [[TranquilMediaPlayer sharedInstance] pauseForSample];
}

- (void)setModule:(TranquilModule *)module
{
    _module = module;
}

- (void)play:(NSString *)filePath volume:(float)volume
{
    [self play:filePath volume:volume withCompletion:nil];
}

- (void)play:(NSString *)filePath volume:(float)volume withCompletion:(void(^_Nullable)(BOOL))completion
{
    _volume = volume;

    if (!filePath || ([self isPlaying] && [_currentlyPlayingFile isEqualToString:filePath])) {

        _player.volume = _volume;
        if (completion) completion([self isPlaying]);
        return;
    }

    if (_player && _player.isPlaying) {

        [_player stop];
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }

    if ([NSFileManager.defaultManager fileExistsAtPath:filePath]) {

        NSURL *fileURL = [NSURL fileURLWithPath:filePath];

        _currentlyPlayingFile = filePath;

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

            self->_player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
            [self->_player setNumberOfLoops:-1];
            [self->_player setVolume:_volume];

            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionMixWithOthers error:nil];
            [[AVAudioSession sharedInstance] setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

            [self->_player prepareToPlay];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_player play];
                if (completion) completion([self isPlaying]);
            });
        });

    } else if (completion) {

        completion([self isPlaying]);
    }
}

- (void)stop
{
    if (_player && _player.isPlaying) {

        [_player stop];
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    }

    _otherAudioIsPlaying = [[AVAudioSession sharedInstance] isOtherAudioPlaying];
}

- (BOOL)isPlaying
{
    return _player && _player.isPlaying;
}

- (BOOL)isOtherAudioPlaying
{
    return _otherAudioIsPlaying;
}

- (void)setVolume:(float)volume
{
    _volume = volume;

    if (_player) {

        _player.volume = volume;
    }
}

- (void)pauseForSample
{
    if (_player && _player.isPlaying) {

        [_player pause];
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
    }
}

// due to limitations of AVAudioSession categories, we can either offer mixed audio, or receive interruption notifications
// but not both, due to these limitations, we have to watch for now playing changes through private API inorder to replicate
// iOS 15 background sounds features, specifically changing the volume when other media is playing. There are various ways
// of accomplishing this, but all of which have other limitations they introduce such as respecting the physical silent switch
// witch is undesirable for our purposes. so here we observe SBMediaController to check for now playing state changes.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{    
    if ([object isKindOfClass:NSClassFromString(@"SBMediaController")] && [keyPath isEqualToString:NSStringFromSelector(@selector(nowPlayingProcessPID))]) {

        BOOL otherAudioWasPlaying = _otherAudioIsPlaying;
        BOOL mixWithOtherAudio = [_module.preferences boolForKey:@"kUseWhenMediaIsPlaying"];
        _otherAudioIsPlaying = [object isPlaying];

        if (_otherAudioIsPlaying) {

            if (mixWithOtherAudio) {

                float volume = [_module.preferences floatForKey:@"kPlaybackVolumeWithMedia"];

                [self setVolume:volume];

            } else if ([self isPlaying]) {

                _interrupted = YES;
                [self stop];
            }

            [_module refreshState];

        } else if (otherAudioWasPlaying) {

            float volume = [_module.preferences floatForKey:@"kPlaybackVolume"];

            [self setVolume:volume];

            if (_interrupted && _player) {

                [_player play];
                _interrupted = NO;
            }
            
            [_module refreshState];
        }

    } else {

        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];   
    }
}

- (void)dealloc
{
    [[NSClassFromString(@"SBMediaController") sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(nowPlayingProcessPID))];
}

@end