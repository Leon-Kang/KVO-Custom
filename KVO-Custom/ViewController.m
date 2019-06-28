//
//  ViewController.m
//  KVO-Custom
//
//  Created by Leon Kang on 2019/6/27.
//  Copyright © 2019 Leon Kang. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+KLSKVO.h"

@interface Message : NSObject

@property (nonatomic, copy) NSString *text;

@end

@implementation Message

@end

@interface ViewController ()

@property (nonatomic, strong) Message *message;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.message = [[Message alloc] init];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(100, 100, 100, 100);
    btn.backgroundColor = UIColor.blueColor;
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
    [self.message kls_addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) completionBlock:^(id  _Nonnull observedObject, NSString * _Nonnull observedKey, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"%@", newValue);
    }];
}

- (void)tap:(UIButton *)sender {
    self.message.text = [NSString stringWithFormat:@"%ld", random()];
}

@end
