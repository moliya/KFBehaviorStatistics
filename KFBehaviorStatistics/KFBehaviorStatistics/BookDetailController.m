//
//  BookDetailController.m
//  KFBehaviorStatistics
//
//  Created by carefree on 2018/11/15.
//  Copyright © 2018 carefree. All rights reserved.
//

#import "BookDetailController.h"

@interface BookDetailController ()

@end

@implementation BookDetailController

+ (instancetype)viewControllerFromIB {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"detail"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


@end
