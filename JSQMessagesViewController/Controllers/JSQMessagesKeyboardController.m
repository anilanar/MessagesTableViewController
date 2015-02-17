//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//
//
//  Ideas for keyboard controller taken from Daniel Amitay
//  DAKeyboardControl
//  https://github.com/danielamitay/DAKeyboardControl
//

#import "JSQMessagesKeyboardController.h"

#import "UIDevice+JSQMessages.h"
#import "NSNotification+JSQKeyboard.h"


NSString * const JSQMessagesKeyboardControllerNotificationKeyboardDidChangeFrame = @"JSQMessagesKeyboardControllerNotificationKeyboardDidChangeFrame";
NSString * const JSQMessagesKeyboardControllerUserInfoKeyKeyboardDidChangeFrame = @"JSQMessagesKeyboardControllerUserInfoKeyKeyboardDidChangeFrame";

static void * kJSQMessagesKeyboardControllerKeyValueObservingContext = &kJSQMessagesKeyboardControllerKeyValueObservingContext;

typedef void (^JSQAnimationCompletionBlock)(BOOL finished);



@interface JSQMessagesKeyboardController () <UIGestureRecognizerDelegate>

@property (assign, nonatomic) BOOL jsq_isObserving;

@property (weak, nonatomic) UIView *keyboardView;
@property (assign, nonatomic) BOOL keyboardIsVisible;
@property (assign, nonatomic) CGRect currentKeyboardFrame;
@property (assign, nonatomic) CGFloat inputHeight;
@end



@implementation JSQMessagesKeyboardController

#pragma mark - Initialization

-(instancetype)initWithTextView:(UITextView *)textView
                     scrollView:(UIScrollView *)scrollView
                  referenceView:(UIView *)referenceView
                       delegate:(id<JSQMessagesKeyboardControllerDelegate>)delegate {
    self = [super init];
    if (self) {
        _textView = textView;
        _scrollView = scrollView;
        _referenceView = referenceView;
        _delegate = delegate;
        _jsq_isObserving = NO;
    }
    
    return self;
}

- (void)dealloc
{
    _textView = nil;
    _referenceView = nil;
    _delegate = nil;
}

#pragma mark - Getters

- (CGRect)currentKeyboardFrame
{
    if (!_keyboardIsVisible) {
        return CGRectNull;
    }

    return _currentKeyboardFrame;
}

#pragma mark - Keyboard controller

- (void)beginListeningForKeyboard
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)endListeningForKeyboard
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
}

-(void)handleNotification:(NSNotification *)notification {
    CGFloat osVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(osVersion < 8.00000) {
        [self handleIos7:notification];
    }
    else {
        [self handleIos8:notification];
    }
}

-(void)handleIos7:(NSNotification *)notification {
    CGRect oldRect = [notification oldRectForView:self.referenceView];
    CGRect newRect = [notification newRectForView:self.referenceView];
    CGFloat heightDiff = newRect.size.height - oldRect.size.height;
    CGFloat yDiff = newRect.origin.y - oldRect.origin.y;
    
    BOOL inputHeightDidChange =
    self.inputHeight != [self.delegate contentHeightForInputAccessoryView];
    
    CGFloat newHeight = 0.0;
    BOOL skip = notification.didShow || notification.didHide;
    
    
    // show | cancel | rotation.3
    if(heightDiff > 0 && yDiff < 0) {
        // rotation.3
        if(inputHeightDidChange) {
            if(notification.willShow) {
                newHeight = newRect.size.height;
                self.inputHeight = [self.delegate contentHeightForInputAccessoryView];
            }
        }
        // show
        else if(!self.keyboardIsVisible) {
            if(notification.willShow)
                newHeight = newRect.size.height;
            else
                self.keyboardIsVisible = YES;
        }
        // cancel
        else {
            skip = YES;
        }
    }
    
    // hide | rotation.3
    else if(heightDiff < 0 && yDiff > 0) {
        // rotation.3
        if(inputHeightDidChange) {
            if(notification.willShow) {
                newHeight = newRect.size.height;
                self.inputHeight = [self.delegate contentHeightForInputAccessoryView];
            }
        }
        // hide
        else {
            if(notification.willShow)
                newHeight = newRect.size.height;
            else
                self.keyboardIsVisible = NO;
        }
    }
    
    // inc/dec | pop navigation
    else if(heightDiff == 0 && yDiff == 0) {
        // hw hidden
        if([self isRectOutOfScreen:newRect] && notification.willShow)
            newHeight = [self.delegate contentHeightForInputAccessoryView];
        // pop navigation
        else if(oldRect.origin.x < 0) {
            if(notification.willShow)
                newHeight = newRect.size.height;
            else
                self.keyboardIsVisible = NO;
        }
        
        else if(notification.willShow)
            newHeight = newRect.size.height;
        
        if(notification.willShow)
            self.inputHeight = [self.delegate contentHeightForInputAccessoryView];
    }
    
    // rotation.1 | hw shown to hw hidden | sw shown to hw hidden
    else if(heightDiff == 0 && yDiff > 0) {
        // rotation.1
        if(notification.willHide && newRect.origin.y == self.referenceView.frame.size.height) {
            skip = YES;
        }
        // hw shown to hw hidden | sw shown to hw hidden
        else if(newRect.origin.y != self.referenceView.frame.size.height) {
            if(notification.willHide)
                newHeight = self.currentKeyboardFrame.size.height - (newRect.origin.y - oldRect.origin.y);
            else
                self.keyboardIsVisible = NO;
        }
    }
    
    // rotation.2, hw hidden to hw shown | hw cancel | modal initial
    else if(heightDiff == 0 && yDiff < 0) {
        // hw hidden & rotation.2
        if([self isRectOutOfScreen:newRect]) {
            if(notification.willShow)
                newHeight = [self.delegate contentHeightForInputAccessoryView];
        }
        // (!hw & rotation.2) | (hw shown & rotation.2)
        else if(oldRect.origin.y == self.referenceView.frame.size.height) {
            if(notification.willShow)
                newHeight = newRect.size.height;
        }
        // hw cancel
        else if(self.keyboardIsVisible) {
            skip = YES;
        }
        // modal initial
        else if(oldRect.origin.y > newRect.origin.y + newRect.size.height) {
            if(notification.willShow)
                newHeight = [self.delegate contentHeightForInputAccessoryView];
        }
        // hw hidden to hw shown
        else {
            if(notification.willShow) {
                newHeight = newRect.size.height;
            }
            else {
                self.keyboardIsVisible = YES;
            }
        }
    }
    // sw hidden to hw hidden | didShow | didHide
    // heightDiff > 0 && yDiff == 0
    else
        skip = YES;
    
    if(!skip) {
        CGRect keyboardFrame = newRect;
        CGFloat oldHeight = _currentKeyboardFrame.size.height;
        keyboardFrame.size.height = newHeight;
        _currentKeyboardFrame = keyboardFrame;
        
        [notification animate:^{
            [self animateWithOldHeight:oldHeight newHeight:newHeight];
        }];
    }
}

-(void)handleIos8:(NSNotification *)notification {
    CGRect oldRect = [notification oldRectForView:self.referenceView];
    CGRect newRect = [notification newRectForView:self.referenceView];
    CGFloat heightDiff = newRect.size.height - oldRect.size.height;
    CGFloat yDiff = newRect.origin.y - oldRect.origin.y;
    
    CGFloat oldInputHeight = self.inputHeight;
    CGFloat newInputHeight = [self.delegate contentHeightForInputAccessoryView];
    self.inputHeight = newInputHeight;
    BOOL inputHeightDidChange = oldInputHeight != newInputHeight;
    
    
    CGFloat newHeight = 0.0;
    BOOL skip = notification.didShow || notification.didHide;
    
    
    // cancel | rotation.3 | inc/dec | hw hidden to hw shown.2
    if(heightDiff > 0 && yDiff < 0) {
        // rotation.3 | inc/dec
        //        if(inputHeightDidChange) {
        if(notification.willShow) {
            newHeight = newRect.size.height;
        }
        //        }
        // cancel | hw hidden to hw shown.2
        //        else {
        //            skip = YES;
        //        }
    }
    
    // rotation.3 | inc/dec | hw shown to hw hidden.2
    else if(heightDiff < 0 && yDiff > 0) {
        // rotation.3 | inc/dec
        if(inputHeightDidChange && notification.willShow) {
            newHeight = newRect.size.height;
            self.inputHeight = [self.delegate contentHeightForInputAccessoryView];
        }
        // hw shown to hw hidden.2
        else if(notification.willShow) {
            skip = YES;
        }
    }
    
    // hide.2 | sw hidden to hw hidden | initial show | navigation pop
    else if(heightDiff == 0 && yDiff == 0 && notification.willShow) {
        // hide.2 | initial show
        if(newRect.size.height == [self.delegate contentHeightForInputAccessoryView])
            newHeight = [self.delegate contentHeightForInputAccessoryView];
        // sw hidden to hw hidden
        else if([self isRectOutOfScreen:newRect])
            newHeight = [self.delegate contentHeightForInputAccessoryView];
        // navigation pop
        else
            newHeight = newRect.size.height;
        self.inputHeight = [self.delegate contentHeightForInputAccessoryView];
    }
    
    // hide | rotation.1 | hw shown to hw hidden.1 | sw shown to hw hidden | rotation.4
    else if(heightDiff == 0 && yDiff > 0) {
        // rotation.4
        if(newRect.size.height == [self.delegate contentHeightForInputAccessoryView])
            skip = YES;
        // rotation.1
        if(newRect.origin.y == MAX(self.referenceView.frame.size.height, self.referenceView.frame.size.width)) {
            skip = YES;
        }
        // hide | hw shown to hw hidden.1 | sw shown to hw hidden
        else if(newRect.origin.y != self.referenceView.frame.size.height) {
            if(notification.willHide)
                newHeight = [self.delegate contentHeightForInputAccessoryView];
            else
                self.keyboardIsVisible = NO;
        }
    }
    
    // show | rotation.2, hw hidden to hw shown.1 | hw hidden to sw shown | hw cancel
    else if(heightDiff == 0 && yDiff < 0) {
        // hw hidden & rotation.2
        if([self isRectOutOfScreen:newRect]) {
            if(notification.willShow)
                newHeight = [self.delegate contentHeightForInputAccessoryView];
        }
        // (!hw & rotation.2) | (hw shown & rotation.2)
        else if(oldRect.origin.y == self.referenceView.frame.size.height) {
            if(notification.willShow)
                newHeight = newRect.size.height;
        }
        // hw cancel
        else if(self.keyboardIsVisible) {
            skip = YES;
        }
        // show | hw hidden to hw shown | hw hidden to sw shown
        else {
            if(notification.willShow) {
                newHeight = newRect.size.height;
            }
            else {
                self.keyboardIsVisible = YES;
            }
        }
    }
    // didShow | didHide
    // heightDiff > 0 && yDiff == 0
    else
        skip = YES;
    
    if(!skip) {
        CGRect keyboardFrame = newRect;
        CGFloat oldHeight = _currentKeyboardFrame.size.height;
        keyboardFrame.size.height = newHeight;
        _currentKeyboardFrame = keyboardFrame;
        
        [notification animate:^{
            [self animateWithOldHeight:oldHeight newHeight:newHeight];
        }];
    }
}

-(CGRect)convertRect:(CGRect)rect {
    if(self.referenceView)
        return [self.referenceView convertRect:rect fromView:nil];
    else
        return rect;
}

-(void)animateWithOldHeight:(CGFloat)oldHeight newHeight:(CGFloat)newHeight {
    CGFloat heightDiff = newHeight - oldHeight;
    UIEdgeInsets insets = self.scrollView.contentInset;
    insets.bottom += heightDiff;
    self.scrollView.contentInset = insets;
    self.scrollView.scrollIndicatorInsets = insets;
    
    if (heightDiff > 0) {
        CGPoint contentOffset = self.scrollView.contentOffset;
        CGFloat newAreaHeight = self.scrollView.bounds.size.height - self.scrollView.contentInset.top - self.scrollView.contentInset.bottom;
        CGFloat oldAreaHeight = newAreaHeight + heightDiff;
        
        if (self.scrollView.contentSize.height > oldAreaHeight) {
            contentOffset.y += heightDiff;
        } else if (self.scrollView.contentSize.height > newAreaHeight) {
            contentOffset.y += self.scrollView.contentSize.height - newAreaHeight;
        }
        self.scrollView.contentOffset = contentOffset;
    }
}



-(BOOL)isRectOutOfScreen: (CGRect)rect {
    return rect.origin.y + rect.size.height > self.referenceView.frame.size.height;
}

@end
