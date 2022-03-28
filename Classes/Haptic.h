//
//  Haptic.h
//  Tranquil
//
//  Created by Dana Buehre on 3/15/22.
//
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIImpactFeedbackGenerator.h>
#import <UIKit/UINotificationFeedbackGenerator.h>


NS_INLINE void PlayImpact(UIImpactFeedbackStyle feedbackStyle)
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:feedbackStyle];
    [feedbackGenerator prepare];
    [feedbackGenerator impactOccurred];
}

NS_INLINE void PlayImpactWithSound(UIImpactFeedbackStyle feedbackStyle, SystemSoundID soundID)
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:feedbackStyle];
    [feedbackGenerator prepare];
    AudioServicesPlaySystemSound(soundID);
    [feedbackGenerator impactOccurred];
}

NS_INLINE void PlayNotificationWithSound(UINotificationFeedbackType type)
{
    UINotificationFeedbackGenerator *feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
    [feedbackGenerator prepare];
    [feedbackGenerator notificationOccurred:type];
}
