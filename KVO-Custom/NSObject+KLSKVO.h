//
//  NSObject+KLSKVO.h
//  KVO-Custom
//
//  Created by Leon Kang on 2019/6/27.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^KLSObservingBlock)(id observedObject, NSString *observedKey, id oldValue, id newValue);

@interface NSObject (KLSKVO)

- (void)kls_addObserver:(NSObject *)observer
             forKeyPath:(NSString *)keyPath
        completionBlock:(KLSObservingBlock)block;

- (void)kls_removeObserver:(NSObject *)observer
                forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
