# message-forwarding
若想令类能理解某条消息，我们必须以程序码实现出对应的方法才行。但是，编译器在编译时还无法知道类中有没有对某个方法的实现。当对象接收到无法解读的消息后，就会启动“消息转发”（message forwarding）机制，我们可以经由此过程告诉对象应该如何处理未知消息。
如果控制台中看到下面的这种提示，那就说明你曾向某个对象发送过一条其无法解读的消息，从而启动了消息转发机制，并将此消息转发给了NSObject的默认实现。
![](http://upload-images.jianshu.io/upload_images/3265534-5bce50521b4d2e8c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
上面这段异常信息是由NSObject的 “doesNotRecognizeSelector：”方法所抛出的，此异常表明，消息接收者的类型是 ViewController，而该接收者无法理解名为 doSomething 的选择子。
在本例中，消息转发过程以程序崩溃而告终，不过，开发者在编写自己的类时，可于转发过程中设置挂钩，用以执行预定的逻辑，而不使应用程序崩溃。
>**消息转发机制分为两大阶段**。第一阶段先征询接收者所属的类，看其是否能动态添加方法，以处理当前这个“未知的选择子”(unknow selector)，这叫做**“动态方法解析”(dynamic method resolution)**。第二阶段涉及**“完整的消息转发机制”(full forwarding mechanism)**.

## 一、动态方法解析

>![](http://upload-images.jianshu.io/upload_images/3265534-075043d47b41932c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
如果该方法是**实例方法**，对象在接收到无法解读的消息后，首先将调用其所属类的 resolveInstanceMethod: 类方法。sel就是未知的选择子，该方法返回一个boolean类型，表示这个类是否能新增一个实例方法处理此选择子。


---
>![](http://upload-images.jianshu.io/upload_images/3265534-c3f36da765ab92a3.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
如果该方法是**类方法**，那么运行期系统就会调用resolveClassMethod：类方法。

##### 使用上面方法的前提是：相关方法的实现代码已经写好，只等着运行的时候动态插在类里面就可以了。
下面还是以上面的button为例，为其实现动态方法解析。
```
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
```
控制台打印如下：程序不会crash。
![](http://upload-images.jianshu.io/upload_images/3265534-ab9314f8c5ffbe83.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
## 备援接收者
>当前接收者还有第二次机会能处理未知的选择子，在这一步中，运行期系统会问它：能不能把这条消息转发给其他接收者来处理。与该步骤对应的处理方法如下：
![](http://upload-images.jianshu.io/upload_images/3265534-bb09f5c6a4566688.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
方法参数代表未知选择子，若当前接收者能找到备援对象，则将其返回，若找不到，就返回nil。通过此方案，我们可以用“组合(composition)”来**模拟“多重继承”的某些特性**。在一个对象内部，可能还有一系列其他对象，该对象可经由此方法将能够处理某选择子的相关内部对象返回，这样的话，在外界看来，好像是该对象亲自处理了这些消息。

##### 请注意，我们无法操作经由这一步所转发的消息。若是想在发送给备援接收者之前先修改消息内容，那就得通过完整的消息转发机制来做。
下面还是以上面的button为例，为其实现备援接收者。
```
声明一个备援接收者的类
#import <Foundation/Foundation.h>

@interface MyForwardingTargetClass : NSObject

@end

#import "MyForwardingTargetClass.h"

@implementation MyForwardingTargetClass

//不需要在.h中声明，运行时会动态查找类中是否实现该方法
- (void)doSomething
{
NSLog(@"备援接受者的方法调用了,程序没有crash!!!");
}

@end
```
在VC中实现备援接收者的处理方法：
```
//消息转发机制 第一阶段:备援接收者
- (id)forwardingTargetForSelector:(SEL)aSelector
{
//备援接收者 只需要在.m中实现doSomething就可以防止crash
if ([NSStringFromSelector(aSelector) isEqualToString:@"doSomething"]) {
return [MyForwardingTargetClass new];
}
return [super forwardingTargetForSelector:aSelector];

}

```
控制台打印如下，程序没有crash.
![](http://upload-images.jianshu.io/upload_images/3265534-6a8994dd597cc436.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 二、完整的消息转发机制
如果转发算法已经到了这一步，那只能启动完整的消息转发机制了。首先创建NSInvocation 对象，把与尚未处理的那条消息有关的全部细节都封于其中。此对象包含**选择子**、**（目标 target）**、**参数**。在触发NSInvocation对象时，“消息派发系统”将亲自出马，把消息指派给目标对象。
>此步骤会调用下列方法来转发消息：
![](http://upload-images.jianshu.io/upload_images/3265534-c1f09fe2180029f4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这个方法可以实现的很简单：*只需要改变调用目标，使消息在新的目标上得以调用即可。*然而这样实现出来的方法与“备援接收者”方案所实现的等效，**一般很少采用这么简单的实现方式**。
比较有用的实现方式为：**在触发消息前，先以某种方式改变消息内容，比如追加另一个参数，或者改变选择子等等。**
实现此方法时，若发现某调用操作不应由本类处理，则需调用超类的同名方法。这样的话，继承体系中的每个类都有机会处理此调用请求，直至NSObject。如果最后调用了NSObject类的方法，那么该方法还会继而调用“doesNotRecognizeSelector：”以抛出异常，此异常表明选择子最终未能得到处理。

下面还是以上面的button为例，为其实现完整的消息转发机制。此处先简单的实现下（和备援接收者实现方案等效）：
```
创建一个类，处理vc不能处理的方法
#import <Foundation/Foundation.h>
@interface MethodCrashClass : NSObject

- (void)methodCrash:(NSInvocation *)invocation;

@end

#import "MethodCrashClass.h"
@implementation MethodCrashClass

- (void)methodCrash:(NSInvocation *)invocation
{
NSLog(@"在类:%@中 未实现该方法:%@",NSStringFromClass([invocation.target class]),NSStringFromSelector(invocation.selector));
}

@end
```
控制台打印如下，程序没有crash。

![](http://upload-images.jianshu.io/upload_images/3265534-ff716caf57976103.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
##### 那么问题来了！这些方法是在VC中实现的，如果我们想要给每个类都添加一个防止crash的方法呢？显然这样添加不是一个很好的选择。
解决方案：
```
//创建NSObject的分类
#import <Foundation/Foundation.h>
@interface NSObject (crashLog)

@end

#import "NSObject+crashLog.h"
@implementation NSObject (crashLog)

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
//方法签名
return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
NSLog(@"在类:%@中 未实现该方法:%@",NSStringFromClass([anInvocation.target class]),NSStringFromSelector(anInvocation.selector));
}

@end
```
控制台打印如下，程序没有crash。

![](http://upload-images.jianshu.io/upload_images/3265534-41f03d3582d35067.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
>因为在category中复写了父类的方法，会出现下面的警告，
![](http://upload-images.jianshu.io/upload_images/3265534-f1201589385e2628.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
解决办法就是在Xcode的Build Phases中的资源文件里，在对应的文件后面 -w ，忽略所有警告。
![](http://upload-images.jianshu.io/upload_images/3265534-791c66acc96b8072.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

---
>此处还有一点需要解释的，就是在方法签名中的Types:**"v@:@"**,这些符号是什么意思呢？
其实这些符号就是返回值和方法参数对应的类型。可在Xcode中的开发者文档中搜索**Type Encodings**就可看到符号对应的含义，此处不再列举了。

## 消息转发全流程


![](http://upload-images.jianshu.io/upload_images/3265534-28151afc2dc7aba8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

接收者在每一步中均有机会处理消息。**步骤越往后，处理消息的代价越大。**最好能在第一步处理完，这样运行期系统可以把此方法缓存起来。如果这个类的实例稍后还会收到同名选择子，则无须启动消息转发流程。
若想在第三步里把消息转发给备援接收者，还不如把转发操作提前到第二步。因为第三步只是修改了调用目标，这项改动放在第二步执行会更简单，不然的话，还要创建并处理完整的NSIncocation。

##### 可以利用消息转发机制的三个步骤，选择哪一步去改造比较合适呢？

*这里我们选择了第二步`forwardingTargetForSelector`。引用 [《大白健康系统—iOS APP运行时Crash自动修复系统》](http://www.yopai.com/show-3-150721-1.html) 的分析：*

- `resolveInstanceMethod` 需要在类的本身上动态添加它本身不存在的方法，这些方法对于该类本身来说冗余的。
- `forwardInvocation` 可以通过 NSInvocation 的形式将消息转发给多个对象，但是其开销较大，需要创建新的 NSInvocation 对象，并且 `forwardInvocation` 的函数经常被使用者调用，来做多层消息转发选择机制，不适合多次重写。
- `forwardingTargetForSelector` 可以将消息转发给一个对象，开销较小，并且被重写的概率较低，适合重写。
