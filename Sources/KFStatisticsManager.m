//
//  KFStatisticsManager.m
//  KFBehaviorStatistics
//
//  Created by carefree on 2019/1/9.
//  Copyright © 2019 carefree. All rights reserved.
//

#import "KFStatisticsManager.h"
#import <PromiseKit/PromiseKit.h>
#import <Aspects/Aspects.h>

@implementation KFStatisticsManager

+ (void)load {
    //启动埋点器
    [[KFStatisticsManager sharedManager] start];
}

+ (instancetype)sharedManager {
    static KFStatisticsManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[KFStatisticsManager alloc] init];
    });
    
    return manager;
}

- (void)start {
    //读取埋点配置文件，也可以请求服务器获取
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"StatisticsConfig" ofType:@"plist"];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:filePath];
    if (!config) {
        return;
    }
    //遍历配置文件的key，即视图控制器的类名
    [[config allKeys] enumerateObjectsUsingBlock:^(id  _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
        Class cls = NSClassFromString(name);
        //该Class视图控制器下的所有埋点交互事件
        NSArray *events = [config[name] objectForKey:kBehaviorStatisticsControlEventsKey];
        if (!cls || !events) {
            return;
        }
        [events enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull event, NSUInteger idx, BOOL * _Nonnull stop) {
            //需要hook的方法和需要上报的事件
            NSString *selector = [event objectForKey:kBehaviorStatisticsSelectorKey];
            NSString *eventID = [event objectForKey:kBehaviorStatisticsEventIDKey];
            if (!selector || !eventID) {
                return;
            }
            
            SEL sel = NSSelectorFromString(selector);
            if (![cls instancesRespondToSelector:sel]) {
                return;
            }
            
            //额外的信息，可以添加到attributes
            NSArray *extra = [event objectForKey:kBehaviorStatisticsExtraKey];
            [cls aspect_hookSelector:sel withOptions:AspectPositionBefore usingBlock:^(id<AspectInfo> info) {
                [self handleExtra:extra withAspectInfo:info completion:^(NSDictionary *attributes, NSString *newID) {
                    NSString *eid = newID ?: eventID;
                    if (eid.length == 0) {
                        return;
                    }
                    //开始上报
                    NSLog(@"埋点统计Event：%@，attr：%@", eid, attributes);
                    if (attributes && attributes.allKeys.count > 0) {
                        //[MobClick event:eid attributes:attributes];
                    } else {
                        //[MobClick event:eid];
                    }
                }];
            } error:NULL];
        }];
    }];
}

- (void)handleExtra:(NSArray *)extra withAspectInfo:(id<AspectInfo>)info completion:(void(^)(NSDictionary *attributes, NSString *newID))completion {
    //多线程异步执行
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        if (!extra) {
            [self customConfigureWithAspectInfo:info completion:completion];
            return;
        }
        NSMutableArray *promises = [NSMutableArray array];
        [extra enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PMKPromise *pmk = [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
                NSArray *args = [info arguments];
                //指定参数的下标
                NSNumber *index = [obj objectForKey:kBehaviorStatisticsIndexKey];
                //指定参数需要调用的函数
                NSString *func = [obj objectForKey:kBehaviorStatisticsFuncKey];
                //指定参数处理后需要比对的值
                id value = [obj objectForKey:kBehaviorStatisticsEqualKey];
                //待添加的attributes
                NSDictionary *attr = [obj objectForKey:kBehaviorStatisticsAttributesKey];
                /**
                 *  这里分两种情况：
                 *  1.当没有设置index值时，表示该项为必添参数，无需进行比对，直接添加
                 *  2.当有设置index值时，表示需要对参数进行比对，只有匹配条件时才添加
                 */
                //情况1
                if (!index) {
                    fulfill(attr);
                    return;
                }
                //情况2
                if (!args || !value || !attr) {
                    fulfill(nil);
                    return;
                }
                if (args.count == 0 || args.count <= index.integerValue || index.integerValue < 0) {
                    fulfill(nil);
                    return;
                }
                //待处理的参数对象
                id arg = args[index.integerValue];
                [self executeFunc:func withObject:arg block:^(id returnValue) {
                    //处理CGRect、CGPoint、CGSize等结构体里的星号
                    if ([returnValue isKindOfClass:[NSString class]]) {
                        returnValue = [self replacedStr:returnValue byWildcardStr:value];
                    }
                    
                    //进行比对
                    BOOL ok1 = [value isKindOfClass:[NSString class]] && [returnValue isKindOfClass:[NSString class]] && [value isEqualToString:returnValue];
                    BOOL ok2 = [value isKindOfClass:[NSNumber class]] && [returnValue isKindOfClass:[NSNumber class]] && [value isEqualToNumber:returnValue];
                    if (!ok1 && !ok2) {
                        fulfill(nil);
                        return;
                    }
                    fulfill(attr);
                }];
            }];
            
            [promises addObject:pmk];
        }];
        
        [PMKPromise all:promises].thenInBackground(^(NSArray *results) {
            NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
            __block NSString *newID;
            [results enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![obj isKindOfClass:[NSDictionary class]]) {
                    return;
                }
                NSString *tmp = [obj objectForKey:kBehaviorStatisticsNewIDKey];
                if (tmp && tmp.length > 0) {
                    newID = tmp;
                    return;
                }
                [attributes addEntriesFromDictionary:obj];
            }];
            if (completion) {
                completion(attributes, newID);
            }
        });
    });
}

- (void)executeFunc:(NSString *)func withObject:(id)object block:(void(^)(id returnValue))block {
    if (!func) {
        if (block) {
            block(object);
        }
        return;
    }
    //在主线程执行，因为可能会调用UI相关的API
    __block id returnValue = object;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *selectors = [func componentsSeparatedByString:@"."];
        for (NSString *name in selectors) {
            if (name.length == 0) {
                continue;
            }
            SEL sel = NSSelectorFromString(name);
            if (![returnValue respondsToSelector:sel]) {
                break;
            }
            // methodReturnType的字符对应关系
            // @ -> id
            // v -> void
            // i -> int
            // f -> float
            // B -> BOOL
            // q -> NSInteger
            // Q -> NSUInteger
            // d -> CGFloat
            // {CGRect={CGPoint=dd}{CGSize=dd}} -> CGRect
            // {CGPoint=dd} -> CGPoint
            // {CGSize=dd} -> CGSize
            // {_NSRange=QQ} -> NSRange
            // {UIEdgeInsets=dddd} -> UIEdgeInsets
            // {UIOffset=dd} -> UIOffset
            NSMethodSignature *sign = [returnValue methodSignatureForSelector:sel];
            NSString *returnType = [NSString stringWithUTF8String:sign.methodReturnType];
            if ([returnType isEqualToString:@"@"]) {
                IMP imp = [returnValue methodForSelector:sel];
                id (*func)(id, SEL) = (void *)imp;
                returnValue = func(returnValue, sel);
            } else if ([returnType isEqualToString:@"v"]) {
                break;
            } else if ([returnType isEqualToString:@"i"]) {
                IMP imp = [returnValue methodForSelector:sel];
                int (*func)(id, SEL) = (void *)imp;
                returnValue = @(func(returnValue, sel));
            } else if ([returnType isEqualToString:@"f"]) {
                IMP imp = [returnValue methodForSelector:sel];
                float (*func)(id, SEL) = (void *)imp;
                returnValue = @(func(returnValue, sel));
            } else if ([returnType isEqualToString:@"B"]) {
                IMP imp = [returnValue methodForSelector:sel];
                BOOL (*func)(id, SEL) = (void *)imp;
                returnValue = @(func(returnValue, sel));
            } else if ([returnType isEqualToString:@"q"]) {
                IMP imp = [returnValue methodForSelector:sel];
                NSInteger (*func)(id, SEL) = (void *)imp;
                returnValue = @(func(returnValue, sel));
            } else if ([returnType isEqualToString:@"Q"]) {
                IMP imp = [returnValue methodForSelector:sel];
                NSUInteger (*func)(id, SEL) = (void *)imp;
                returnValue = @(func(returnValue, sel));
            } else if ([returnType isEqualToString:@"d"]) {
                IMP imp = [returnValue methodForSelector:sel];
                CGFloat (*func)(id, SEL) = (void *)imp;
                returnValue = @(func(returnValue, sel));
            } else if ([returnType containsString:@"CGRect"]) {
                IMP imp = [returnValue methodForSelector:sel];
                CGRect (*func)(id, SEL) = (void *)imp;
                returnValue = NSStringFromCGRect(func(returnValue, sel));
            } else if ([returnType containsString:@"CGPoint"]) {
                IMP imp = [returnValue methodForSelector:sel];
                CGPoint (*func)(id, SEL) = (void *)imp;
                returnValue = NSStringFromCGPoint(func(returnValue, sel));
            } else if ([returnType containsString:@"CGSize"]) {
                IMP imp = [returnValue methodForSelector:sel];
                CGSize (*func)(id, SEL) = (void *)imp;
                returnValue = NSStringFromCGSize(func(returnValue, sel));
            } else if ([returnType containsString:@"NSRange"]) {
                IMP imp = [returnValue methodForSelector:sel];
                NSRange (*func)(id, SEL) = (void *)imp;
                returnValue = NSStringFromRange(func(returnValue, sel));
            } else if ([returnType containsString:@"UIEdgeInsets"]) {
                IMP imp = [returnValue methodForSelector:sel];
                UIEdgeInsets (*func)(id, SEL) = (void *)imp;
                returnValue = NSStringFromUIEdgeInsets(func(returnValue, sel));
            } else if ([returnType containsString:@"UIOffset"]) {
                IMP imp = [returnValue methodForSelector:sel];
                UIOffset (*func)(id, SEL) = (void *)imp;
                returnValue = NSStringFromUIOffset(func(returnValue, sel));
            }
        }
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            if (block) {
                block(returnValue);
            }
        });
    });
}

- (NSString *)replacedStr:(NSString *)str1 byWildcardStr:(NSString *)str2 {
    if (![str1 containsString:@"{"] || ![str1 containsString:@"}"] || ![str1 containsString:@","]) {
        return str1;
    }
    if (![str2 containsString:@"{"] || ![str2 containsString:@"}"] || ![str2 containsString:@","]) {
        return str1;
    }
    if (![str2 containsString:@"*"]) {
        return str1;
    }
    NSArray *arr1 = [str1 componentsSeparatedByString:@","];
    NSArray *arr2 = [str2 componentsSeparatedByString:@","];
    if (arr1.count != arr2.count) {
        return str1;
    }
    
    NSMutableArray *newArr = [NSMutableArray array];
    for (NSInteger i = 0; i < arr1.count; i ++) {
        if ([arr2[i] containsString:@"*"]) {
            [newArr addObject:arr2[i]];
        } else {
            [newArr addObject:arr1[i]];
        }
    }
    NSMutableString *newStr = [NSMutableString string];
    for (NSString *tmp in newArr) {
        [newStr appendFormat:@"%@,", tmp];
    }
    [newStr deleteCharactersInRange:NSMakeRange(newStr.length - 1, 1)];
    
    return newStr;
}

- (void)customConfigureWithAspectInfo:(id<AspectInfo>)info completion:(void(^)(NSDictionary *attributes, NSString *newID))completion {
    //控制器实例
    //    id object = [info instance];
    //    //方法
    //    NSInvocation *invocation = [info originalInvocation];
    //    //参数
    //    NSArray *args = [info arguments];
    
    if (completion) {
        completion(nil, nil);
    }
}

@end
