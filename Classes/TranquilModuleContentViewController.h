//
//  TranquilModuleContentViewController.h
//  Tranquil
//
//  Created by Dana Buehre on 3/8/22.
//
//

#import <UIKit/UIKit.h>
#import <ControlCenterUIKit/CCUIMenuModuleViewController.h>

@class TranquilModule;

@interface TranquilModuleContentViewController : CCUIMenuModuleViewController
@property (nonatomic, weak) TranquilModule* module;

- (void)updateItemSelection;
@end
