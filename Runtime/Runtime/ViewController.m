//
//  ViewController.m
//  Runtime
//
//  Created by 宇航 on 2020/3/23.
//  Copyright © 2020 yuhang. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "PopAnimateVC.h"
#import "UINavigationController+PopAnimate.h"

@interface ViewController ()
@property(nonatomic, strong) NSString *strongStr;
@property(nonatomic, copy) NSString *copyedStr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)popAction:(id)sender {
    PopAnimateVC*vc = [[PopAnimateVC alloc] init];
    self.navigationController.popIndex = YES;
    [self.navigationController pushViewController:vc animated:YES];
}


@end
