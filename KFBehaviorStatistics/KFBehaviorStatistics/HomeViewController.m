//
//  HomeViewController.m
//  KFBehaviorStatistics
//
//  Created by carefree on 2018/11/13.
//  Copyright © 2018 carefree. All rights reserved.
//

#import "HomeViewController.h"
#import "BookListController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)pushToNext:(id)sender {
    BookListController *list = [BookListController viewControllerFromIB];
    list.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:list animated:YES];
}


@end
