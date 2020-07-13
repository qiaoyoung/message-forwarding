//
//  MyForwardingTargetClass.m
//  消息转发机制
//
//  Created by Joeyoung on 2017/6/12.
//  Copyright © 2017年 Joe. All rights reserved.
//

#import "MyForwardingTargetClass.h"

@implementation MyForwardingTargetClass

// 不需要在.h中声明，运行时会动态查找类中是否实现该方法
- (void)doSomething {
    NSLog(@"备援接受者的方法调用了,程序没有crash!!!");
}

@end
