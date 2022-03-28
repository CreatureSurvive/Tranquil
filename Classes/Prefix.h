//
//  Prefix.h
//  Tranquil
//
//  Created by Dana Buehre on 3/14/22.
//
//


#ifndef TRANQUIL_PREFIX_H
#define TRANQUIL_PREFIX_H

#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <dlfcn.h>

// https://stackoverflow.com/a/14770282/4668186
#define CLAMP(x, low, high) ({\
  __typeof__(x) __x = (x); \
  __typeof__(low) __low = (low);\
  __typeof__(high) __high = (high);\
  __x > __high ? __high : (__x < __low ? __low : __x);\
  })

// return negative value if condition is true
#define NEGATE_IF(x, c) (c == true ? -x : x)

NS_INLINE __unused NSBundle *ModuleBundle(BOOL loadIfNeeded)
{
    static NSBundle *moduleBundle;

    if (!moduleBundle) {

        moduleBundle = [NSBundle bundleWithPath:@"/Library/ControlCenter/Bundles/Tranquil.bundle"];
    }

    if (loadIfNeeded && ![moduleBundle isLoaded]) {

        [moduleBundle load];
    }

    return moduleBundle;
}

NS_INLINE __unused NSDictionary *Defaults(void)
{
    static NSDictionary *defaults;

    if (!defaults) {

        defaults =  @{
            @"kBackgroundSoundsActive" : @NO,
            @"kPauseOnRouteChange" : @YES,
            @"kPlaybackVolume" : @0.6,
            @"kPlaybackVolumeWithMedia" : @0.2,
            @"kUseWhenMediaIsPlaying" : @YES,
            @"kActiveSound" : [ModuleBundle(NO).bundlePath stringByAppendingPathComponent:@"Audio/BROWN_NOISE.m4a"]
        };
    }

    return defaults;
}

NS_INLINE __unused id DefaultValueForKey(NSString *key)
{
    if (!key) {

        return nil;
    }

    return Defaults()[key];
}

NS_INLINE __unused BOOL RTLLayout (UIView *view)
{
    return [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:view.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
}

NS_INLINE __unused NSString * LocalizeWithTable(NSString *key, NSString *table)
{
    if (!table) {

        table = @"Localizable";
    }

    return [ModuleBundle(YES) localizedStringForKey:key value:nil table:table];
}

NS_INLINE __unused NSString * Localize(NSString *key)
{
    return LocalizeWithTable(key, nil);
}

NS_INLINE __unused void SetCornerRadiusLayer(CALayer *layer, CGFloat radius)
{
    layer.cornerRadius = radius;
    layer.masksToBounds = YES;

    if (@available(iOS 13.0, *)) {

        layer.cornerCurve = kCACornerCurveContinuous;

    } else if ([layer respondsToSelector:@selector(continuousCorners)]) {

        [layer performSelector:@selector(continuousCorners) withObject:@YES];
    }
}

NS_INLINE __unused void OpenApplicationUrl(NSURL *url)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        void (*SBSOpenSensitiveURLAndUnlock)(NSURL *, BOOL);

        if ((SBSOpenSensitiveURLAndUnlock = (void (*)(NSURL *, BOOL)) dlsym(RTLD_DEFAULT, "SBSOpenSensitiveURLAndUnlock"))) {

            (*SBSOpenSensitiveURLAndUnlock)(url, YES);

        } else {

            dispatch_async(dispatch_get_main_queue(), ^{

                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            });
        }
    });
}

NS_INLINE __unused NSArray<NSDictionary *> *AudioMetadata(NSString *bundlePath)
{
    NSString *bundledAudioPath = [bundlePath stringByAppendingPathComponent:@"Audio"];
    NSArray *bundledAudioFiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:bundledAudioPath error:nil];

    NSString *userProvidedAudioPath = @"/var/mobile/Library/Application Support/Tranquil/Audio";
    NSArray *userProvidedAudioFiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:userProvidedAudioPath error:nil];

    __block NSMutableArray *combinedMetadata = [NSMutableArray new];

    void (^generateMetadata)(NSArray *, NSString *) = ^(NSArray *files, NSString *basePath)
    {
        NSArray *sortedFiles = [files sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

        for (NSString *file in sortedFiles)
        {
            [combinedMetadata addObject:@{
                    @"path" : [basePath stringByAppendingPathComponent:file],
                    @"name" : [file stringByDeletingPathExtension]
            }];
        }
    };

    generateMetadata(bundledAudioFiles, bundledAudioPath);
    generateMetadata(userProvidedAudioFiles, userProvidedAudioPath);

    return combinedMetadata;
}

NS_INLINE __unused NSArray<NSString *> *DownloadableAudioFileNames(void)
{
    static NSArray *downloadableAudioFileNames;

    if (!downloadableAudioFileNames) {

        downloadableAudioFileNames = @[
            @"FLOWING_STREAM.m4a",
            @"LIGHT_RAIN.m4a",
            @"OCEAN_WAVES.m4a",
            @"THUNDER_STORM.m4a",
            @"INFRA_NOISE.m4a",
            @"ULTRA_NOISE.m4a"
        ];
    }

    return downloadableAudioFileNames;
}

NS_INLINE __unused NSArray<NSDictionary *> *DownloadableAudioMetadata(void)
{
    static NSArray *downloadableAudioMetadata;

    if (!downloadableAudioMetadata) {

        downloadableAudioMetadata = @[
            @{
                    @"name" : @"INFRA_NOISE",
                    @"path" : @"/var/mobile/Library/Application Support/Tranquil/Audio/INFRA_NOISE.m4a"
            }, @{
                    @"name" : @"ULTRA_NOISE",
                    @"path" : @"/var/mobile/Library/Application Support/Tranquil/Audio/ULTRA_NOISE.m4a"
            }, @{
                    @"name" : @"FLOWING_STREAM",
                    @"path" : @"/var/mobile/Library/Application Support/Tranquil/Audio/FLOWING_STREAM.m4a"
            }, @{
                    @"name" : @"LIGHT_RAIN",
                    @"path" : @"/var/mobile/Library/Application Support/Tranquil/Audio/LIGHT_RAIN.m4a"
            }, @{
                    @"name" : @"OCEAN_WAVES",
                    @"path" : @"/var/mobile/Library/Application Support/Tranquil/Audio/OCEAN_WAVES.m4a"
            }, @{
                    @"name" : @"THUNDER_STORM",
                    @"path" : @"/var/mobile/Library/Application Support/Tranquil/Audio/THUNDER_STORM.m4a"
            }
        ];
    }

    return downloadableAudioMetadata;
}

NS_INLINE __unused BOOL DownloadableContentAvailable(void)
{
    BOOL downloadsAvailable = NO;
    for (NSDictionary *entry in DownloadableAudioMetadata())
    {
        if ([NSFileManager.defaultManager fileExistsAtPath:entry[@"path"]]) continue;
        downloadsAvailable = YES;
        break;
    }

    return downloadsAvailable;
}

NS_INLINE __unused UIAlertController *GenericErrorAlert(NSError *error, UIViewController *controller)
{
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:Localize(@"GENERIC_ERROR_TITLE") message:error.localizedFailureReason preferredStyle:UIAlertControllerStyleAlert];
    [errorAlert addAction:[UIAlertAction actionWithTitle:@"More Info" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController *detailedErrorAlert = [UIAlertController alertControllerWithTitle:Localize(@"GENERIC_ERROR_TITLE") message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        [detailedErrorAlert addAction:[UIAlertAction actionWithTitle:Localize(@"OKAY_LABEL") style:UIAlertActionStyleCancel handler:nil]];
        [controller presentViewController:detailedErrorAlert animated:YES completion:nil];
    }]];
    [errorAlert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil]];

    return errorAlert;
}

#endif //TRANQUIL_PREFIX_H
