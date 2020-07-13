//
//  NSObject+crashLog.m
//  消息转发机制
//
//  Created by Joeyoung on 2017/6/13.
//  Copyright © 2017年 Joe. All rights reserved.
//

#import "NSObject+crashLog.h"


@implementation NSObject (crashLog)

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // 方法签名
    return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"在类:%@中 未实现该方法:%@",NSStringFromClass([anInvocation.target class]),NSStringFromSelector(anInvocation.selector));
}

@end
