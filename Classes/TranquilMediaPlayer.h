//
//  TranquilMediaPlayer.h
//  Tranquil
//
//  Created by Dana Buehre on 3/8/22.
//
//

#import <Foundation/Foundation.h>

@class TranquilModule;

NS_ASSUME_NONNULL_BEGIN

@interface TranquilMediaPlayer : NSObject

+ (TranquilMediaPlayer *)sharedInstance;
+ (void)play:(NSString *)filePath volume:(float)volume;
+ (void)play:(NSString *)filePath volume:(float)volume withCompletion:(void (^_Nullable)(BOOL))completion;
+ (void)stop;
+ (BOOL)isPlaying;
+ (BOOL)isOtherAudioPlaying;
+ (void)setVolume:(float)volume;
+ (void)setModule:(TranquilModule *)module;
+ (void)pauseForSample;

- (void)play:(NSString *)filePath volume:(float)volume;
- (void)play:(NSString *)filePath volume:(float)volume withCompletion:(void(^_Nullable)(BOOL))completion;
- (void)stop;
- (BOOL)isPlaying;
- (BOOL)isOtherAudioPlaying;
- (void)setVolume:(float)volume;
- (void)setModule:(TranquilModule *)module;
- (void)pauseForSample;

@end

NS_ASSUME_NONNULL_END