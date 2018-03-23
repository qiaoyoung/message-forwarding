//
//  ViewController.m
//  消息转发机制
//
//  Created by Joeyoung on 2017/6/12.
//  Copyright © 2017年 Joe. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

#import "MyForwardingTargetClass.h"

#import "MethodCrashClass.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];


    //实例化一个button,未实现其方法
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 50, 200, 100);
    button.backgroundColor = [UIColor greenColor];
    [button setTitle:@"消息转发" forState:UIControlStateNormal];
    [button addTarget:self
               action:@selector(doSomething)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    
}
#pragma mark - ---------------------------------------------------------------
#pragma mark ---- 消息转发机制 第一阶段 ----
//消息转发机制 第一阶段:动态方法解析
/*
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if ([NSStringFromSelector(sel) isEqualToString:@"doSomething"]) {
 
        class_addMethod([self class], sel, (IMP)dynamicMethodIMP, "v@:");
    }
    return [super resolveInstanceMethod:sel];
}
void dynamicMethodIMP(id self, SEL _cmd) {
    
    NSLog(@"动态添加了方法\"%@\" ,防止程序crash", NSStringFromSelector(_cmd));
    
}
//消息转发机制 第一阶段:备援接收者
- (id)forwardingTargetForSelector:(SEL)aSelector
{
    //备援接收者 只需要在.m中实现doSomething就可以防止crash
    if ([NSStringFromSelector(aSelector) isEqualToString:@"doSomething"]) {
        return [MyForwardingTargetClass new];
    }
    return [super forwardingTargetForSelector:aSelector];
    
}
*/
#pragma mark - ---------------------------------------------------------------
#pragma mark ---- 消息转发机制 第二阶段 ----
//消息转发机制 第二阶段:完整的消息转发机制
/*
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if ([NSStringFromSelector(aSelector) isEqualToString:@"doSomething"]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    return nil;
}
- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    MethodCrashClass *crashClass = [MethodCrashClass new];
    [crashClass methodCrash:anInvocation];
  
}
*/

@end
