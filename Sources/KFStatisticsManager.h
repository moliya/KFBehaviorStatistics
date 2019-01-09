//
//  KFStatisticsManager.h
//  KFBehaviorStatistics
//
//  Created by carefree on 2019/1/9.
//  Copyright © 2019 carefree. All rights reserved.
//

#import <Foundation/Foundation.h>

// 页面事件
static NSString *const  kBehaviorStatisticsPageEventsKey = @"PageEvents";
// 交互事件
static NSString *const  kBehaviorStatisticsControlEventsKey = @"ControlEvents";
// 页面进入事件
static NSString *const  kBehaviorStatisticsPageEnterKey = @"Enter";
// 页面退出事件
static NSString *const  kBehaviorStatisticsPageExitKey = @"Exit";
// 对象的方法（自定义或系统）
static NSString *const  kBehaviorStatisticsSelectorKey = @"SEL";
// 上报的事件名
static NSString *const  kBehaviorStatisticsEventIDKey = @"EventID";
// 附加参数内容
static NSString *const  kBehaviorStatisticsExtraKey = @"Extra";
// 方法中指定的参数下标
static NSString *const  kBehaviorStatisticsIndexKey = @"Index";
// 参数需要调用的函数
static NSString *const  kBehaviorStatisticsFuncKey = @"Func";
// 待比对的值（使用调用函数后返回的值与之比对）
static NSString *const  kBehaviorStatisticsEqualKey = @"Equal";
// 上报的自定义attributes
static NSString *const  kBehaviorStatisticsAttributesKey = @"Attributes";
// 重命名的事件名
static NSString *const  kBehaviorStatisticsNewIDKey = @"NewID";

NS_ASSUME_NONNULL_BEGIN

@interface KFStatisticsManager : NSObject

@end

NS_ASSUME_NONNULL_END
