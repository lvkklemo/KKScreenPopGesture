## Runtime+KVC

滑动手势`UIPanGestureRecognizer`
利用runtime遍历它的所有成员变量，看看系统是怎么存储这个属性

```objc
 unsigned int count = 0;
    Ivar * var = class_copyIvarList([UIPanGestureRecognizer class], &count);
    for (int i=0; i<count; i++) {
        Ivar _var = *(var+i);
        NSLog(@"TypeEncoding:%s",ivar_getTypeEncoding(_var));
        NSLog(@"Name :%s",ivar_getName(_var));
    }
```

```
2020-03-28 11:44:53.929541+0800 Runtime[85529:862632] TypeEncoding:@"NSMutableArray"
2020-03-28 11:44:53.929751+0800 Runtime[85529:862632] Name :_touches
```

通过log我们可以看到，UIGestureRecognizer有一个叫_targets的属性，它的类型为NSMutableArray。

它是用数组来存储每一个target－action，所以可以动态的增加手势触发对象。那么又是什么存储每一个target-action呢？为了了解这个我们拿到这个属性的名字"_targets"通过kvc获取它，接着打印出来。

```objective-c
      UIGestureRecognizer*gesture = self.navigationController.interactivePopGestureRecognizer;
    NSMutableArray * _targets = [gesture valueForKey:@"_targets"];
    NSLog(@"%@",_targets);
```
log输出

![WechatIMG187](/Users/lvkk/Desktop/KKScreenPopGesture/WechatIMG187.jpeg)

我们看到，原来每一个target-action是用UIGestureRecognizerTarget这样一个类来存储的，它也是一个私有类。
苹果把许多的类做私有化也是有原因所在，其实在平时我们拿到这个类也是没有用的，他们的目的之一是避免对开发者公开无用的类，影响了封装性。所以在类的设计上，还是要向苹果学习。

在控制器的ViewDidLoad加上这段代码，并且它只需要执行一次。

```objc
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //获取系统原始手势的view,并关闭原始手势
        UIGestureRecognizer *gesture = self.navigationController.interactivePopGestureRecognizer;
        gesture.enabled=NO;
        UIView*gestureView = gesture.view;
        
        //获取系统手势的target数组
        NSMutableArray*_targets = [gesture valueForKey:@"_targets"];
      
        //获取数组唯一对象,我们知道他是一个UIGestureRecognizerTarget的私有类,他有一个属性交_target
        id gestureRecognizerTarget = _targets.firstObject;
        
        //获取_target: UINavigationInteractiveTransition,他有一个方法handleNavigationTransition
        id navigationInteractiveTransition=[gestureRecognizerTarget valueForKey:@"_target"];
        NSLog(@"%@",navigationInteractiveTransition);
        
        //通过前面的打印,我们在控制台c取出来他的方法签名
        SEL handleTransition = NSSelectorFromString(@"handleNavigationTransition:");
        
        ///创建一个与系统一样的手势,只是把类修改为UIGestureRecognizer
        UIPanGestureRecognizer * pop = [[UIPanGestureRecognizer alloc] initWithTarget:navigationInteractiveTransition action:handleTransition];
        [gestureView addGestureRecognizer:pop];
    });
```


#### 分类
```objc
#import <UIKit/UIKit.h>
@interface UINavigationController (PopAnimate)
@property(nonatomic,assign) BOOL popIndex;
@end
```

```objc
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

```