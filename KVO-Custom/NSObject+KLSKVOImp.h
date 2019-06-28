//
//  NSObject+KLSKVOImp.h
//  KVO-Custom
//
//  Created by Leon Kang on 2019/6/27.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (KLSKVOImp)

- (void)kls_addObserver:(NSObject *)observer
             forKeyPath:(NSString *)keyPath
                options:(NSKeyValueObservingOptions *)options
                context:(void *)context;

- (void)kls_observerValueForKeyPath:(NSString *)keyPath
                           ofObject:(id)object
                             change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                            context:(void *)context;

@end

NS_ASSUME_NONNULL_END
