//
//  MethodCrashClass.m
//  消息转发机制
//
//  Created by Joeyoung on 2017/6/12.
//  Copyright © 2017年 Joe. All rights reserved.
//

#import "MethodCrashClass.h"

@implementation MethodCrashClass

- (void)methodCrash:(NSInvocation *)invocation {
    NSLog(@"在类:%@中 未实现该方法:%@",NSStringFromClass([invocation.target class]),NSStringFromSelector(invocation.selector));
}

@end
