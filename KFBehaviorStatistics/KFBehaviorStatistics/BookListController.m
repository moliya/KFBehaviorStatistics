//
//  BookListController.m
//  KFBehaviorStatistics
//
//  Created by carefree on 2018/11/15.
//  Copyright © 2018 carefree. All rights reserved.
//

#import "BookListController.h"
#import "BookDetailController.h"

@interface BookListController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView    *tableView;
@property (nonatomic, strong) NSMutableArray        *books;

@end

@implementation BookListController

+ (instancetype)viewControllerFromIB {
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"list"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 56;
    
    self.books = [NSMutableArray array];
    [self.books addObjectsFromArray:@[@"Book 1", @"Book 2", @"Book 3", @"Book 4", @"Book 5"]];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.books.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bookCell" forIndexPath:indexPath];
    cell.textLabel.text = self.books[indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BookDetailController *detail = [BookDetailController viewControllerFromIB];
    detail.bookName = self.books[indexPath.row];
    [self.navigationController pushViewController:detail animated:YES];
}

@end
