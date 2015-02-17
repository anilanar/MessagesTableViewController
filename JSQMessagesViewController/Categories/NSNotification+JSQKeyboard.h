//
//  NSNotification+JSQKeyboard.h
//  JSQMessages
//
//  Created by Anil Anar on 17.02.2015.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSNotification (JSQKeyboard)

-(CGRect)oldRectForView:(UIView *)view;
-(CGRect)newRectForView:(UIView *)view;

-(BOOL)willShow;
-(BOOL)didShow;
-(BOOL)willHide;
-(BOOL)didHide;

-(void)animate:(void (^)(void))animations;

@end
