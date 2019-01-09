//
//  BookDetailController.h
//  KFBehaviorStatistics
//
//  Created by carefree on 2018/11/15.
//  Copyright © 2018 carefree. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BookDetailController : UIViewController

@property (nonatomic, copy) NSString    *bookName;

+ (instancetype)viewControllerFromIB;

@end

NS_ASSUME_NONNULL_END
