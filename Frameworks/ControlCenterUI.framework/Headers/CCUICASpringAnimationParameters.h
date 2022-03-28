/*
 * This header is generated by classdump-dyld 1.0
 * on Thursday, January 25, 2018 at 11:29:33 PM Eastern European Standard Time
 * Operating System: Version 11.1.2 (Build 15B202)
 * Image Source: /System/Library/PrivateFrameworks/ControlCenterUI.framework/ControlCenterUI
 * classdump-dyld is licensed under GPLv3, Copyright © 2013-2016 by Elias Limneos.
 */

#import <ControlCenterUI/ControlCenterUI-Structs.h>
#import "CCUIAnimationParameters.h"


@protocol CCUIAnimationTimingFunctionDescription;
@class NSString;

@interface CCUICASpringAnimationParameters : NSObject <CCUIAnimationParameters, NSMutableCopying> {

	CGFloat _mass;
	CGFloat _stiffness;
	CGFloat _damping;
	id<CCUIAnimationTimingFunctionDescription> _timingFunction;

}

@property (nonatomic,readonly) CGFloat mass;									//@synthesize mass=_mass - In the implementation block
@property (nonatomic,readonly) CGFloat stiffness;								//@synthesize stiffness=_stiffness - In the implementation block
@property (nonatomic,readonly) CGFloat damping;									//@synthesize damping=_damping - In the implementation block
@property (nonatomic,copy,readonly) id<CCUIAnimationTimingFunctionDescription> timingFunction;			//@synthesize timingFunction=_timingFunction - In the implementation block
@property (readonly) NSUInteger hash;
@property (readonly) Class superclass;
@property (copy,readonly) NSString * description;
@property (copy,readonly) NSString * debugDescription;
- (instancetype)init;
- (BOOL)isEqual:(id)arg1;
- (NSUInteger)hash;
- (NSString *)description;
- (id)copyWithZone:(NSZone*)arg1;
- (id<CCUIAnimationTimingFunctionDescription>)timingFunction;
- (CGFloat)damping;
- (CGFloat)mass;
- (id)mutableCopyWithZone:(NSZone*)arg1;
- (CGFloat)stiffness;
- (instancetype)_initWithAnimationParameters:(id)arg1;
@end