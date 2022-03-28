//
//  TranquilListItemsController.m
//  Tranquil
//
//  Created by Dana Buehre on 3/26/22.
//
//

#import <UIKit/UIKit.h>
#import <Preferences/PSSpecifier.h>
#import "TranquilListItemsController.h"
#import "UIImage+TranquilModule.h"
#import "TranquilPreferencesController.h"
#import "Prefix.h"

@implementation TranquilListItemsController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

    if ([self audioFileNeedsDownload:indexPath]) {

        [self setDownloadIconForCell:cell];
    }

    return cell;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    NSString *path = specifier.values.firstObject;
    NSMutableArray<UIContextualAction *> *actions = [NSMutableArray new];

    if ([path hasPrefix:@"/var/mobile/Library/Application Support/Tranquil/Audio"]) {

        if ([NSFileManager.defaultManager fileExistsAtPath:path]) {

            [actions addObject:[UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:Localize(@"SWIPE_ACTION_DELETE_TITLE") handler:^(UIContextualAction *action, __kindof UIView *sourceView, void (^completionHandler)(BOOL)) {

                [self deleteFileForIndexPath:indexPath];
                completionHandler(YES);
            }]];
        }

        if (![DownloadableAudioFileNames() containsObject:path.lastPathComponent]) {

            [actions addObject:[UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:Localize(@"SWIPE_ACTION_RENAME_TITLE") handler:^(UIContextualAction *action, __kindof UIView *sourceView, void (^completionHandler)(BOOL)) {

                [self renameFileForIndexPath:indexPath];
                completionHandler(YES);
            }]];

            [actions.lastObject setBackgroundColor:[UIColor systemBlueColor]];
        }
    }

    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:actions];
    configuration.performsFirstActionWithFullSwipe = NO;

    return configuration;
}

- (void)listItemSelected:(NSIndexPath *)indexPath
{
    if ([self audioFileNeedsDownload:indexPath]) {

        // prevent playing default sound when selecting a sound that is not yet downloaded
        [self _setPlaybackPausedForDownload:YES withPlaybackValue:nil notifyModule:NO];
        [super listItemSelected:indexPath];
        [self downloadAudioFileForSpecifierAtIndexPath:indexPath];

    } else {

        [super listItemSelected:indexPath];
    }
}

- (void)downloadAudioFileForSpecifierAtIndexPath:(NSIndexPath *)indexPath
{
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    NSString *identifier = [specifier.values.firstObject lastPathComponent];

    if ([DownloadableAudioFileNames() containsObject:identifier]) {

        NSString *destinationPath = [@"/var/mobile/Library/Application Support/Tranquil/Audio" stringByAppendingPathComponent:identifier];

        if ([NSFileManager.defaultManager fileExistsAtPath:destinationPath]) {

            return;
        }

        [self setSpinnerForCellAtIndexPath:indexPath enabled:YES];

        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURL *downloadURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://creaturecoding.com/shared/.tranquil_audio/%@", identifier]];

        [[session downloadTaskWithURL:downloadURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {

            if (error || !location || ![NSFileManager.defaultManager fileExistsAtPath:location.path]) {

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {

                        [self presentViewController:GenericErrorAlert(error, self) animated:YES completion:nil];
                    }

                    [self _selectDefaultValue];
                    [(PSListController *) self.parentController reloadSpecifier:self.specifier];
                    [self setDownloadIconForCell:[self.table cellForRowAtIndexPath:indexPath]];

                    [self _setPlaybackPausedForDownload:NO withPlaybackValue:nil notifyModule:YES];
                });

                return;
            }

            [NSFileManager.defaultManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:destinationPath] error:nil];
            NSDictionary *filePermissions = @{ NSFileOwnerAccountID: @(501), NSFileGroupOwnerAccountID: @(501), NSFilePosixPermissions: @(0755) };
            [NSFileManager.defaultManager setAttributes:filePermissions ofItemAtPath:destinationPath error:nil];

            [self _setPlaybackPausedForDownload:NO withPlaybackValue:specifier.values.firstObject notifyModule:YES];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self setSpinnerForCellAtIndexPath:indexPath enabled:NO];
            });
        }] resume];
    }
}

- (BOOL)audioFileNeedsDownload:(NSIndexPath *)indexPath
{
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    NSString *path = specifier.values.firstObject;
    return [DownloadableAudioFileNames() containsObject:path.lastPathComponent]
            && ![NSFileManager.defaultManager fileExistsAtPath:path];
}

- (void)setDownloadIconForCell:(PSTableCell *)cell
{
    UIImage *downloadImage = [[UIImage tranquil_moduleImageNamed:@"Download"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *download = [[UIImageView alloc] initWithImage:downloadImage];
    [download setContentMode:UIViewContentModeScaleAspectFill];
    [download setTintColor:UIColor.systemBlueColor];
    [cell setAccessoryView:download];
}

- (void)setSpinnerForCellAtIndexPath:(NSIndexPath *)indexPath enabled:(BOOL)enabled
{
    UITableViewCell *cell = [self.table cellForRowAtIndexPath:indexPath];
    if (enabled) {

        if (!cell.accessoryView || ![cell.accessoryView isKindOfClass:UIActivityIndicatorView.class]) {

            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner setColor:UIColor.systemGrayColor];
            [spinner setFrame:CGRectMake(0, 0, 24, 24)];
            [cell setAccessoryView:spinner];
            [spinner startAnimating];
        }

    } else {

        [cell setAccessoryView:nil];
    }
}

- (void)deleteFileForIndexPath:(NSIndexPath *)indexPath
{
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    NSString *path = specifier.values.firstObject;

    NSError *error;
    [NSFileManager.defaultManager removeItemAtPath:path error:&error];

    if (error != nil) {

        [self presentViewController:GenericErrorAlert(error, self) animated:YES completion:nil];

    } else {

        NSString *activeSound = [self.parentController readPreferenceValue:self.specifier];
        BOOL isActiveSound = [activeSound isEqualToString:path];

        if (isActiveSound) {

            [self _selectDefaultValue];
        }

        [(PSListController *) self.parentController reloadSpecifier:self.specifier];

        if ([self audioFileNeedsDownload:indexPath]) {

            [self setDownloadIconForCell:[self.table cellForRowAtIndexPath:indexPath]];

        } else {

            [self removeSpecifier:specifier animated:YES];
        }
    }
}

- (void)renameFileForIndexPath:(NSIndexPath *)indexPath
{
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    __block NSString *path = specifier.values.firstObject;
    __block NSString *fileName = [path.lastPathComponent stringByDeletingPathExtension];

    UIAlertController *renameController = [UIAlertController alertControllerWithTitle:Localize(@"RENAME_FILE_TITLE") message:Localize(@"RENAME_FILE_MESSAGE") preferredStyle:UIAlertControllerStyleAlert];
    [renameController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = fileName;
        textField.placeholder = fileName;
    }];

    [renameController addAction:[UIAlertAction actionWithTitle:Localize(@"OKAY_LABEL") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *newFileName = [renameController.textFields.firstObject text];

        // invalid name
        if (newFileName.length == 0 || [newFileName hasPrefix:@"."]) {

            NSString *message = [NSString stringWithFormat:Localize(@"RENAME_FILE_ERROR_MESSAGE"), fileName, newFileName];
            UIAlertController *invalidAlert = [UIAlertController alertControllerWithTitle:Localize(@"RENAME_FILE_TITLE") message:message preferredStyle:UIAlertControllerStyleAlert];
            [invalidAlert addAction:[UIAlertAction actionWithTitle:Localize(@"OKAY_LABEL") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [renameController.textFields[0] setText:fileName];
                [renameController.textFields[0] setPlaceholder:fileName];
                [self presentViewController:renameController animated:YES completion:nil];
            }]];

            [self presentViewController:invalidAlert animated:YES completion:nil];

        // valid name
        } else {

            NSString *fullFileName = [newFileName stringByAppendingPathExtension:path.pathExtension];

            NSError *error;
            NSString *destination = [[path stringByDeletingLastPathComponent] stringByAppendingPathComponent:fullFileName];
            [NSFileManager.defaultManager moveItemAtPath:path toPath:destination error:&error];

            if (error != nil) {

                [self presentViewController:GenericErrorAlert(error, self) animated:YES completion:nil];

            } else {

                [specifier setName:newFileName];
                [specifier setIdentifier:newFileName];
                [specifier setValues:@[destination] titles:@[newFileName]];

                NSString *activeSound = [self.parentController readPreferenceValue:self.specifier];
                if ([activeSound isEqualToString:path]) {

                    [self.parentController setPreferenceValue:destination specifier:self.specifier];
                }

                [(PSListController *) self.parentController reloadSpecifiers];
                [self reloadSpecifier:specifier animated:YES];
            }
        }
    }]];

    [renameController addAction:[UIAlertAction actionWithTitle:Localize(@"CANCEL_LABEL") style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:renameController animated:YES completion:nil];
}

- (void)_selectDefaultValue
{
    NSString *defaultValue = DefaultValueForKey(@"kActiveSound");
    [self.parentController setPreferenceValue:defaultValue specifier:self.specifier];
    NSInteger index = [self.specifier.values indexOfObject:defaultValue];
    [self listItemSelected:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (void)_setPlaybackPausedForDownload:(BOOL)pause withPlaybackValue:(NSString *)playbackValue notifyModule:(BOOL)notify
{
    [[(TranquilPreferencesController *) self.parentController preferences] setBool:pause forKey:@"kPauseForDownload"];

    if (playbackValue) {

        [self.parentController setPreferenceValue:playbackValue specifier:self.specifier];
    }

    if (notify) {

        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.creaturecoding.tranquil/preferences-changed"), NULL, NULL, TRUE);
    }
}

@end
