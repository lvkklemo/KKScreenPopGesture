//
//  UINavigationController+PopAnimate.m
//  Runtime
//
//  Created by 宇航 on 2020/3/28.
//  Copyright © 2020 yuhang. All rights reserved.
//

#import "UINavigationController+PopAnimate.h"
#import <objc/runtime.h>

@implementation UINavigationController (PopAnimate)

static NSString *nameKey = @"nameKey";

+ (void)load{
    
    Method originalMethod = class_getInstanceMethod(self, @selector(pushViewController:animated:));
    Method swizzledMethod = class_getInstanceMethod(self, @selector(kk_pushViewController:animated:));
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)kk_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self kk_pushViewController:viewController animated:animated];
    //class_copyPropertyList返回的仅仅是对象类的属性(@property申明的属性)
    //class_copyIvarList返回类的所有属性和变量(包括在@interface大括号中声明的变量)
    unsigned int count = 0;
    Ivar * var = class_copyIvarList([UIGestureRecognizer class], &count);
    for (int i=0; i<count; i++) {
        Ivar _var = *(var+i);
        NSLog(@"TypeEncoding:%s",ivar_getTypeEncoding(_var));
        NSLog(@"Name :%s",ivar_getName(_var));
    }
    
    self.interactivePopGestureRecognizer.enabled = NO;
    
    NSMutableArray*targets = [self.interactivePopGestureRecognizer valueForKey:@"_targets"];
    //    targets    __NSArrayM *    @"1 element"    0x0000000282ec7600
    //    [0]    UIGestureRecognizerTarget *    0x2820ac100    0x00000002820ac100
    //    NSObject    NSObject
    //    _target    _UINavigationInteractiveTransition *    0x109e1f180    0x0000000109e1f180
    //    _action    SEL    "handleNavigationTransition:"    0x0000000257b26b4f
    //UIGestureRecognizerTarget
    id targrt =[targets firstObject];
    //_UINavigationInteractiveTransition
    id navigationInteractiveTransition = [targrt valueForKey:@"_target"];
    
    SEL sel = NSSelectorFromString(@"handleNavigationTransition:");
    
    UIPanGestureRecognizer * pop = [[UIPanGestureRecognizer alloc] initWithTarget:navigationInteractiveTransition action:sel];
   
    //获取原来手势视图
    UIView*gesstureView = self.interactivePopGestureRecognizer.view;
    if (self.popIndex) {
        [gesstureView addGestureRecognizer:pop];
    }
    
}

- (void)setPopIndex:(BOOL)popIndex{
    objc_setAssociatedObject(self, &nameKey, [NSNumber numberWithBool:popIndex], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)popIndex{
    NSNumber * popNum = objc_getAssociatedObject(self, &nameKey);
    return popNum.boolValue;
}
@end
