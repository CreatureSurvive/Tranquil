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

#define TranquilBundleIdentifier @"com.creaturecoding.tranquil"
#define TranquilPreferencesChanged "com.creaturecoding.tranquil/preferences-changed"
#define TranquilPreferencesChangedExternal "com.creaturecoding.tranquil/preferences-changed-externally"

#define TranquilBundlePath @"/Library/ControlCenter/Bundles/Tranquil.bundle"
#define TranquilSupportPath @"/var/mobile/Library/Application Support/Tranquil/"
#define TranquilBundledAudioPath @"/Library/ControlCenter/Bundles/Tranquil.bundle/Audio"
#define TranquilImportedAudioPath @"/var/mobile/Library/Application Support/Tranquil/Audio/"
#define TranquilDownloadableAudioPath @"/var/mobile/Library/Application Support/Tranquil/Downloadable/"

NS_INLINE __unused NSBundle *ModuleBundle(BOOL loadIfNeeded)
{
    static NSBundle *moduleBundle;

    if (!moduleBundle) {

        moduleBundle = [NSBundle bundleWithPath:TranquilBundlePath];
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
            @"kActiveSound" : [TranquilBundledAudioPath stringByAppendingPathComponent:@"BROWN_NOISE.m4a"]
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

        NSMutableArray *metadata = [NSMutableArray new];
        for (NSString *fileName in DownloadableAudioFileNames())
        {
            [metadata addObject:@{
                    @"name" : [fileName stringByDeletingPathExtension],
                    @"path" : [TranquilDownloadableAudioPath stringByAppendingPathComponent:fileName]
            }];
        }

        downloadableAudioMetadata = metadata.copy;
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

NS_INLINE __unused NSArray<NSDictionary *> *AudioMetadataIncludingDLC(BOOL includeDownloadable)
{
    NSArray *bundledAudioFiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:TranquilBundledAudioPath error:nil];
    NSArray *importedAudioFiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:TranquilImportedAudioPath error:nil];
    NSArray *downloadedAudioFiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:TranquilDownloadableAudioPath error:nil];

    __block NSMutableSet *uniquePaths = [NSMutableSet new];
    __block NSMutableArray *combinedMetadata = [NSMutableArray new];

    void (^generateMetadata)(NSArray *, NSString *) = ^(NSArray *files, NSString *basePath)
    {
        for (NSString *file in files)
        {
            NSString *fullPath = [basePath stringByAppendingPathComponent:file];

            if ([uniquePaths containsObject:fullPath]) continue;
            [uniquePaths addObject:fullPath];
            [combinedMetadata addObject:@{
                    @"path" : fullPath,
                    @"name" : [file stringByDeletingPathExtension]
            }];
        }
    };

    generateMetadata(bundledAudioFiles, TranquilBundledAudioPath);
    generateMetadata(importedAudioFiles, TranquilImportedAudioPath);
    generateMetadata(downloadedAudioFiles, TranquilDownloadableAudioPath);

    if (includeDownloadable) {

        generateMetadata(DownloadableAudioFileNames(), TranquilDownloadableAudioPath);
    }

    [combinedMetadata sortUsingDescriptors:@[
            [NSSortDescriptor sortDescriptorWithKey:@"path" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]
    ]];

    return combinedMetadata;
}

NS_INLINE __unused NSArray<NSDictionary *> *AudioMetadata(void)
{
    return AudioMetadataIncludingDLC(NO);
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
