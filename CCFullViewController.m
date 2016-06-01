//
//  CCFullViewController.m
//
//
//  Created by Cocos on 16/3/2.
//  Copyright © 2016年 Cocos. All rights reserved.
//

#import "CCFullViewController.h"

@interface CCFullViewController ()

@end

@implementation CCFullViewController

-(void)loadView{
    [super loadView];
    self.view = [[UIView alloc] init];
//    self.view.alpha = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscapeRight;
}

@end
