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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  The `JSQMessagesKeyboardControllerDelegate` protocol defines methods that 
 *  allow you to respond to the frame change events of the system keyboard.
 *
 *  A `JSQMessagesKeyboardController` object also posts the `JSQMessagesKeyboardControllerNotificationKeyboardDidChangeFrame`
 *  in response to frame change events of the system keyboard.
 */
@protocol JSQMessagesKeyboardControllerDelegate <NSObject>

@required

- (CGFloat)contentHeightForInputAccessoryView;

@end

@interface JSQMessagesKeyboardController : NSObject

/**
 *  The object that acts as the delegate of the keyboard controller.
 */
@property (weak, nonatomic) id<JSQMessagesKeyboardControllerDelegate> delegate;

/**
 *  The text view in which the user is editing with the system keyboard.
 */
@property (weak, nonatomic, readonly) UITextView *textView;

@property (weak, nonatomic, readonly) UIScrollView *scrollView;

/**
 *  The view in which the keyboard will be shown and whose coordinate system will be used
 *  to inform of keyboard frame changes.
 */
@property (weak, nonatomic, readonly) UIView *referenceView;

/**
 *  Returns `YES` if the keyboard is currently visible, `NO` otherwise.
 */
@property (assign, nonatomic, readonly) BOOL keyboardIsVisible;

/**
 *  Returns the current frame of the keyboard if it is visible, otherwise `CGRectNull`.
 */
@property (assign, nonatomic, readonly) CGRect currentKeyboardFrame;

- (instancetype)initWithTextView:(UITextView *)textView
                      scrollView:(UIScrollView *)scrollView
                   referenceView:(UIView *)referenceView
                        delegate:(id<JSQMessagesKeyboardControllerDelegate>)delegate;

/**
 *  Tells the keyboard controller that it should begin listening for system keyboard notifications.
 */
- (void)beginListeningForKeyboard;

/**
 *  Tells the keyboard controller that it should end listening for system keyboard notifications.
 */
- (void)endListeningForKeyboard;

@end