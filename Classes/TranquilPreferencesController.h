//
//  TranquilPreferencesController.h
//  Tranquil
//
//  Created by Dana Buehre on 3/9/22.
//
//

#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface TranquilPreferencesController : PSListController

- (NSUserDefaults *)preferences;

@end