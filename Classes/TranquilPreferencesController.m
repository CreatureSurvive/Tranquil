//
//  TranquilPreferencesController.m
//  Tranquil
//
//  Created by Dana Buehre on 3/9/22.
//
//

#include "TranquilPreferencesController.h"
#import "Prefix.h"

#import <Preferences/PSSpecifier.h>
#import <Preferences/PSControlTableCell.h>

#import <AVFoundation/AVFoundation.h>
#import <SafariServices/SafariServices.h>

TranquilPreferencesController *loadedController;

@interface TranquilPreferencesController () <AVAudioPlayerDelegate, UIDocumentPickerDelegate, SFSafariViewControllerDelegate>

- (NSArray *)audioMetadata;
- (NSArray *)activeSoundTitles;
- (NSArray *)activeSoundValues;

@end

@implementation TranquilPreferencesController {

    __strong NSUserDefaults *_preferences;
	__weak PSTableCell *_volumeDisplayCell;
	__weak PSSpecifier *_volumeControlSpecifier;
	__weak PSTableCell *_volumeWithMediaDisplayCell;
	__weak PSSpecifier *_volumeWithMediaControlSpecifier;
	AVAudioPlayer *_musicPlayer;
	AVAudioPlayer *_soundPlayer;
}

- (NSMutableArray *)specifiers
{
	if(!_specifiers) {

		_specifiers = [self loadSpecifiersFromPlistName:@"Preferences" target:self].mutableCopy;
	}

	return _specifiers;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	loadedController = self;
    _preferences = [[NSUserDefaults alloc] initWithSuiteName:TranquilBundleIdentifier];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	if ([cell.specifier.identifier isEqualToString:@"volumeDisplaySpecifier"]) {

		_volumeDisplayCell = cell;
		cell.textLabel.textColor = [UIColor systemGrayColor];
		cell.separatorInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, CGFLOAT_MAX);

	} else if ([cell.specifier.identifier isEqualToString:@"volumeSpecifier"]) {

		_volumeControlSpecifier = cell.specifier;
		UISlider *slider = (UISlider *)[(PSControlTableCell *)cell control];
        [slider addTarget:self action:@selector(refreshVolumeDisplay) forControlEvents:UIControlEventValueChanged];
        [slider setContinuous:YES];

	} else if ([cell.specifier.identifier isEqualToString:@"volumeWithMediaDisplaySpecifier"]) {

		_volumeWithMediaDisplayCell = cell;
		cell.textLabel.textColor = [UIColor systemGrayColor];
		cell.separatorInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, CGFLOAT_MAX);

	} else if ([cell.specifier.identifier isEqualToString:@"volumeWithMediaSpecifier"]) {

		_volumeWithMediaControlSpecifier = cell.specifier;
		UISlider *slider = (UISlider *)[(PSControlTableCell *)cell control];
        [slider addTarget:self action:@selector(refreshVolumeWithMediaDisplay) forControlEvents:UIControlEventValueChanged];
        [slider setContinuous:YES];
	}

	return cell;
}

- (NSUserDefaults *)preferences
{
    return _preferences;
}

- (NSURL *)userImportedSoundsDirectoryURL
{
	return [NSURL fileURLWithPath:TranquilImportedAudioPath];
}

- (NSArray *)audioMetadata
{
	return AudioMetadata();
}

- (NSArray *)downloadableMetadata
{
	return DownloadableAudioMetadata();
}

- (NSArray *)activeSoundTitles
{
	NSArray *metadata = AudioMetadataIncludingDLC(YES);
	NSMutableArray *titles = [NSMutableArray new];

	for (NSDictionary *entry in metadata) 
	{
		[titles addObject:Localize(entry[@"name"])];
	}

	return titles;
}

- (NSArray *)activeSoundValues
{
	NSArray *metadata = AudioMetadataIncludingDLC(YES);
	NSMutableArray *values = [NSMutableArray new];

	for (NSDictionary *entry in metadata) 
	{
		[values addObject:entry[@"path"]];
	}

	return values;
}

- (NSString *)getActiveVolume
{
	PSSpecifier *controlSpecifier = _volumeControlSpecifier ? : [self specifierForID:@"volumeSpecifier"];
	float value = [[self readPreferenceValue:controlSpecifier] floatValue];
	return [NSString stringWithFormat:@"%d", (int)(value * 100)];
}

- (void)refreshVolumeDisplay
{
	_volumeDisplayCell.detailTextLabel.text = [self getActiveVolume];
}

- (NSString *)getActiveVolumeWithMedia
{
	PSSpecifier *controlSpecifier = _volumeWithMediaControlSpecifier ? : [self specifierForID:@"volumeWithMediaSpecifier"];
	float value = [[self readPreferenceValue:controlSpecifier] floatValue];
	return [NSString stringWithFormat:@"%d", (int)(value * 100)];
}

- (void)refreshVolumeWithMediaDisplay
{
	_volumeWithMediaDisplayCell.detailTextLabel.text = [self getActiveVolumeWithMedia];

	if (_soundPlayer && _soundPlayer.isPlaying) {

		PSSpecifier *controlSpecifier = _volumeWithMediaControlSpecifier ? : [self specifierForID:@"volumeWithMediaSpecifier"];
		_soundPlayer.volume = [[self readPreferenceValue:controlSpecifier] floatValue];
	}
}

- (void)playSampleWithMedia
{
    [_preferences setBool:YES forKey:@"kPauseForSample"];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(TranquilPreferencesChanged), NULL, NULL, TRUE);

    PSSpecifier *stopSampleSpecifier = [PSSpecifier preferenceSpecifierNamed:Localize(@"STOP_SAMPLE_BUTTON_LABEL") target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
	stopSampleSpecifier->action = @selector(stopSampleWithMedia);
	stopSampleSpecifier.identifier = @"stopSampleSpecifier";

	[self replaceContiguousSpecifiers:@[[self specifierForID:@"playSampleSpecifier"]] withSpecifiers:@[stopSampleSpecifier]];

	PSSpecifier *controlSpecifier = _volumeWithMediaControlSpecifier ? : [self specifierForID:@"volumeWithMediaSpecifier"];
	float volume = [[self readPreferenceValue:controlSpecifier] floatValue];

	NSString *activeSoundPath = [self readPreferenceValue:[self specifierForID:@"activeSoundSpecifier"]]
								? : DefaultValueForKey(@"kActiveSound");
	NSURL *soundURL = [NSURL fileURLWithPath:activeSoundPath];
	NSURL *musicURL = [NSURL fileURLWithPath:@"/Library/Ringtones/Night Owl.m4r"];
	
	_soundPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
	_musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:nil];

	_soundPlayer.numberOfLoops = -1;
	_soundPlayer.volume = volume;
	_musicPlayer.delegate = self;
	
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
	[[AVAudioSession sharedInstance] setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
	[_soundPlayer play];
	[_musicPlayer play];
}

- (void)stopSampleWithMedia
{
	PSSpecifier *playSampleSpecifier = [PSSpecifier preferenceSpecifierNamed:Localize(@"PLAY_SAMPLE_BUTTON_LABEL") target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
	playSampleSpecifier->action = @selector(playSampleWithMedia);
	playSampleSpecifier.identifier = @"playSampleSpecifier";

	[self replaceContiguousSpecifiers:@[[self specifierForID:@"stopSampleSpecifier"]] withSpecifiers:@[playSampleSpecifier]];

	[_soundPlayer stop];
	[_musicPlayer stop];
	_soundPlayer = nil;
	_musicPlayer = nil;

	[[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

    [_preferences setBool:NO forKey:@"kPauseForSample"];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(TranquilPreferencesChanged), NULL, NULL, TRUE);
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	[self stopSampleWithMedia];
}

- (void)openImportDirectory
{
	NSString *filzaURLString = [NSString stringWithFormat:@"filza://view%@", [self userImportedSoundsDirectoryURL].resourceSpecifier];
	[UIApplication.sharedApplication openURL:[NSURL URLWithString:filzaURLString] options:@{} completionHandler:nil];
}

- (void)openTranslations
{
	[self openURLInBrowser:@"https://github.com/CreatureSurvive/Project-Localizations"];
}

- (void)openSourceCode
{
	[self openURLInBrowser:@"https://github.com/CreatureSurvive/Tranquil"];
}

- (void)openDepiction
{
	[self openURLInBrowser:@"https://creaturecoding.com/?page=depiction&id=tranquil"];
}

- (void)openURLInBrowser:(NSString *)url {
	SFSafariViewController *safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
	safari.delegate = self;
	[self presentViewController:safari animated:YES completion:nil];
}

- (void)presentDocumentPicker
{
	UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.audio"] inMode:UIDocumentPickerModeImport];
	documentPicker.delegate = self;
	[self presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
	if (!url || ![NSFileManager.defaultManager fileExistsAtPath:url.path]) {

		NSString *accessMessage = Localize(@"IMPORTING_FILE_ACCESSIBILITY_ERROR_MESSAGE");
		UIAlertController *accessAlert = [UIAlertController alertControllerWithTitle:Localize(@"IMPORTING_FILE_ERROR_TITLE") message:accessMessage preferredStyle:UIAlertControllerStyleAlert];
		[accessAlert addAction:[UIAlertAction actionWithTitle:Localize(@"OKAY_LABEL") style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:accessAlert animated:YES completion:nil];
		return;
	}

	__block NSString *fileName = [url.lastPathComponent stringByDeletingPathExtension];

	NSString *renameMessage = Localize(@"RENAME_FILE_MESSAGE");
	UIAlertController *renameController = [UIAlertController alertControllerWithTitle:Localize(@"RENAME_FILE_TITLE") message:renameMessage preferredStyle:UIAlertControllerStyleAlert];
	[renameController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
		textField.text = fileName;
		textField.placeholder = fileName;
	}];
	[renameController addAction:[UIAlertAction actionWithTitle:Localize(@"OKAY_LABEL") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		NSString *newFileName = [renameController.textFields[0] text];

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

			newFileName = [newFileName stringByAppendingPathExtension:url.pathExtension];

			NSError *error;
			NSURL *destination = [NSURL fileURLWithPath:newFileName relativeToURL:[self userImportedSoundsDirectoryURL]];
			[NSFileManager.defaultManager moveItemAtURL:url toURL:destination error:&error];

			// error copying file
			if (error) {

				[self presentViewController:GenericErrorAlert(error, self) animated:YES completion:nil];

			// success
			} else {

				NSString *message = [NSString stringWithFormat:Localize(@"IMPORTED_FILE_MESSAGE"), newFileName];
				UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:Localize(@"IMPORTED_FILE_TITLE") message:message preferredStyle:UIAlertControllerStyleAlert];
				[successAlert addAction:[UIAlertAction actionWithTitle:Localize(@"OKAY_LABEL") style:UIAlertActionStyleCancel handler:nil]];

				[self presentViewController:successAlert animated:YES completion:nil];
				[self reloadSpecifiers];
			}
		}
	}]];
	[renameController addAction:[UIAlertAction actionWithTitle:Localize(@"CANCEL_LABEL") style:UIAlertActionStyleCancel handler:nil]];
	[self presentViewController:renameController animated:YES completion:nil];
}

@end

void preferencesChangedExternally(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	if (loadedController) {

		[loadedController reloadSpecifiers];
	}
}

__attribute__((constructor))
static void init(void)
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChangedExternally, CFSTR(TranquilPreferencesChangedExternal), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}