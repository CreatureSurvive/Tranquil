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


NS_INLINE void HapticImpact(UIImpactFeedbackStyle feedbackStyle)
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:feedbackStyle];
    [feedbackGenerator prepare];
    [feedbackGenerator impactOccurred];
}

NS_INLINE void HapticImpactAfterDelay(UIImpactFeedbackStyle feedbackStyle, NSTimeInterval delay)
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:feedbackStyle];
    [feedbackGenerator prepare];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [feedbackGenerator impactOccurred];
    });
}

NS_INLINE void HapticImpactWithSound(UIImpactFeedbackStyle feedbackStyle, SystemSoundID soundID)
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:feedbackStyle];
    [feedbackGenerator prepare];
    AudioServicesPlaySystemSound(soundID);
    [feedbackGenerator impactOccurred];
}

NS_INLINE void HapticImpactWithSoundAfterDelay(UIImpactFeedbackStyle feedbackStyle, SystemSoundID soundID, NSTimeInterval delay)
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:feedbackStyle];
    [feedbackGenerator prepare];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AudioServicesPlaySystemSound(soundID);
        [feedbackGenerator impactOccurred];
    });
}

NS_INLINE void HapticSelection()
{
    UISelectionFeedbackGenerator *feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
    [feedbackGenerator prepare];
    [feedbackGenerator selectionChanged];
}

NS_INLINE void HapticSelectionAfterDelay(NSTimeInterval delay)
{
    UISelectionFeedbackGenerator *feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
    [feedbackGenerator prepare];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [feedbackGenerator selectionChanged];
    });
}

NS_INLINE void HapticNotification(UINotificationFeedbackType type)
{
    UINotificationFeedbackGenerator *feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
    [feedbackGenerator prepare];
    [feedbackGenerator notificationOccurred:type];
}

NS_INLINE void HapticNotificationAfterDelay(UINotificationFeedbackType type, NSTimeInterval delay)
{
    UINotificationFeedbackGenerator *feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
    [feedbackGenerator prepare];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [feedbackGenerator notificationOccurred:type];
    });
}
