//
//  NSNotification+JSQKeyboard.m
//  JSQMessages
//
//  Created by Anil Anar on 17.02.2015.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import "NSNotification+JSQKeyboard.h"

@implementation NSNotification (JSQKeyboard)

-(CGRect)oldRectForView:(UIView *)view {
    return [self convertedRectForKey:UIKeyboardFrameBeginUserInfoKey toView:view];
}

-(CGRect)newRectForView:(UIView *)view {
    return [self convertedRectForKey:UIKeyboardFrameEndUserInfoKey toView:view];
}

-(CGRect)convertedRectForKey:(NSString *)key toView:(UIView *)view {
    CGRect rect = [self rectForKey:key];
    if(view)
        return [view convertRect:rect fromView:nil];
    else
        return rect;
}

-(CGRect)rectForKey:(NSString *)key {
    return [[self.userInfo objectForKey:key] CGRectValue];
}

-(BOOL)willShow {
    return [self.name isEqualToString:UIKeyboardWillShowNotification];
}

-(BOOL)didShow {
    return [self.name isEqualToString:UIKeyboardDidShowNotification];
}

-(BOOL)willHide {
    return [self.name isEqualToString:UIKeyboardWillHideNotification];
}

-(BOOL)didHide {
    return [self.name isEqualToString:UIKeyboardDidHideNotification];
}

-(void)animate:(void (^)(void))animations {
    double duration = [self.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSInteger options = [self.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16;
    options |= UIViewAnimationOptionLayoutSubviews;
    //    options |= UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:animations
                     completion:nil];
}

@end
