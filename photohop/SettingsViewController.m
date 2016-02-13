//
//  SettingsViewController.m
//  photohop
//
//  Created by Akshay Easwaran on 2/12/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import "SettingsViewController.h"
#import "PWCirclesView.h"
#import "HexColors.h"

@import Photos;

@interface SettingsViewController ()
@property (strong, nonatomic) UIImage *backgroundImage;
@property (nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) IBOutlet UIVisualEffectView *visView;
@end

@implementation SettingsViewController

-(instancetype)initWithImage:(UIImage*)bImage {
    if (self = [super init]) {
        _backgroundImage = bImage;
    }
    return self;
}

- (UIView*)navTitle {
    UILabel *label = [[UILabel alloc] init];
    [label setFont:[UIFont systemFontOfSize:18]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Settings"];
    [label sizeToFit];
    [label setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, 25 + label.frame.size.height / 2.0)];
    
    UIView *navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, (25 + label.frame.size.height / 2.0) + 20)];
    navView.backgroundColor = [UIColor clearColor];
    [navView addSubview:label];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(10, (navView.frame.size.height / 2.0) - 22, 44, 44)];
    doneButton.center = CGPointMake(doneButton.center.x, label.center.y);
    [doneButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
    [navView addSubview:doneButton];
    
    return navView;
}

-(void)dismissVC {
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _imageView = [[UIImageView alloc] initWithImage:_backgroundImage];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_imageView];
    _visView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    _visView.frame = self.view.bounds;
    
    UILabel *constructionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 25)];
    [constructionLabel setTextColor:[UIColor whiteColor]];
    [constructionLabel setText:@"Nothing here yet!"];
    [constructionLabel sizeToFit];
    constructionLabel.center = _visView.center;
    [_visView.contentView addSubview:constructionLabel];
    
    [self.view addSubview:_visView];
    [self.view addSubview:[self navTitle]];
    
    //photo load limit
    
    //licenses/attribution (all cocoapods, and Icons8)
    //dev website
    //dev email
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
