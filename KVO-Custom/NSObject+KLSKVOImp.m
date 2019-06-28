//
//  NSObject+KLSKVOImp.m
//  KVO-Custom
//
//  Created by Leon Kang on 2019/6/27.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

#import "NSObject+KLSKVOImp.h"
#import <objc/runtime.h>

@implementation NSObject (KLSKVOImp)

- (void)kls_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions *)options context:(void *)context {
    NSString *oldClassName = NSStringFromClass([self class]);
    NSString *newClassName = [NSString stringWithFormat:@"NSKVONotifying_%@", oldClassName];
    
    Class newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
    class_addMethod(newClass, @selector(setName:), (IMP)setName, "v@:@");
    
    objc_registerClassPair(newClass);
    
    object_setClass(self, newClass);
    
    objc_setAssociatedObject(self, @selector(setName:), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)kls_observerValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
}


void setName(id self, SEL _cmd, NSString *str) {
    Ivar ivar = class_getInstanceVariable([self class], "_name");
    object_setIvar(self, ivar, str);
    
    NSObject *observer = objc_getAssociatedObject(self, @selector(setName:));
    
    if ([observer respondsToSelector:@selector(kls_observerValueForKeyPath:ofObject:change:context:)]) {
        [observer kls_observerValueForKeyPath:@"name"
                                     ofObject:self
                                       change:@{NSKeyValueChangeNewKey : str}
                                      context:nil];
    }
}
@end
