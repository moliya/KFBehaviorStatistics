//
//  SetupController.m
//  KFBehaviorStatistics
//
//  Created by carefree on 2018/11/15.
//  Copyright © 2018 carefree. All rights reserved.
//

#import "SetupController.h"

@interface SetupController ()

@end

@implementation SetupController

+ (instancetype)viewControllerFromIB {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"setup"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

@end
