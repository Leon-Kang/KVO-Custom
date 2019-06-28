//
//  NSObject+KLSKVO.m
//  KVO-Custom
//
//  Created by Leon Kang on 2019/6/27.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

#import "NSObject+KLSKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kKLSKVOClassPrefix = @"KLSKVONotifying_";
NSString *const kKLSKVOAssociatedObservers = @"KLSKVOAssociatedObservers";

@interface KLSObservationInfo : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) KLSObservingBlock block;

@end

@implementation KLSObservationInfo

- (instancetype)initWithObserver:(NSObject *)observer
                         keyPath:(NSString *)keyPath
                           block:(KLSObservingBlock)block {
    self = [super init];
    if (self) {
        _observer = observer;
        _key = keyPath;
        _block = block;
    }
    
    return self;
}

static NSArray *ClassMethodNames(Class c) {
    NSMutableArray *array = [NSMutableArray array];
    
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for (i = 0; i < methodCount; i++) {
        [array addObject:NSStringFromSelector(method_getName(methodList[i]))];
    }
    
    free(methodList);
    
    return array;
}

@end

@implementation NSObject (KLSKVO)

- (void)kls_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath completionBlock:(KLSObservingBlock)block {
    SEL setterSelector = NSSelectorFromString(getSetterNameFromKeyPath(keyPath));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    
    if (!setterMethod) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, keyPath];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        
        return;
    }
    
    Class clazz = object_getClass(self);
    NSString *clazzName = NSStringFromClass(clazz);
    
    if (![clazzName hasPrefix:kKLSKVOClassPrefix]) {
        clazz = [self makeKVOClassWithOriginalClassName:clazzName];
        object_setClass(self, clazz);
    }
    
    if (![self hasSelector:setterSelector]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
    }
    
    KLSObservationInfo *info = [[KLSObservationInfo alloc] initWithObserver:observer keyPath:keyPath block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kKLSKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kKLSKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
    
}

- (void)kls_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)kKLSKVOAssociatedObservers);
    
    KLSObservationInfo *infoToRemove;
    for (KLSObservationInfo *info in observers) {
        if (info.observer == observer
            && [info.key isEqualToString:keyPath]) {
            infoToRemove = info;
            break;
        }
    }
    
    [observers removeObject:infoToRemove];
}

- (Class)makeKVOClassWithOriginalClassName:(NSString *)className {
    NSString *kvoClazzName = [kKLSKVOClassPrefix stringByAppendingString:className];
    Class clazz = NSClassFromString(kvoClazzName);
    
    if (clazz) {
        return clazz;
    }
    
    Class originalClazz = object_getClass(self);
    Class kvoClazz = objc_allocateClassPair(originalClazz, kvoClazzName.UTF8String, 0);
    
    Method clazzMethod = class_getInstanceMethod(originalClazz, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClazz, @selector(class), (IMP)kvo_class, types);
    
    objc_registerClassPair(kvoClazz);
    return kvoClazz;
}

static NSString *getSetterNameFromKeyPath(NSString *getter) {
    if (getter.length <= 0) {
        return nil;
    }
    
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    
    return setter;
}

static NSString *getGetterNameFromSetter(NSString *setter) {
    if (setter.length <= 0
        || [setter hasPrefix:@"set"] == NO
        || [setter hasSuffix:@":"] == NO) {
        return nil;
    }
    
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    NSString *firsetLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firsetLetter];
    
    return key;
}

static Class kvo_class(id self, SEL _cmd) {
    return class_getSuperclass(self);
}

static void kvo_setter(id self, SEL _cmd, id newValue) {
     NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getGetterNameFromSetter(setterName);
    
    if (!getterName) {
        
        return;
    }
    
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    
    objc_msgSendSuperCasted(&superClazz, _cmd, newValue);
    
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kKLSKVOClassPrefix));

    for (KLSObservationInfo *each in observers) {
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.block(self, getterName, oldValue, newValue);
            });
        }
    }
}

- (BOOL)hasSelector:(SEL)selector {
    Class clazz = object_getClass(self);
    
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(clazz, &methodCount);
    
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisMethod = method_getName(methodList[i]);
        if (thisMethod == selector) {
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}

@end
