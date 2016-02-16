//
//  SettingsViewController.m
//  photohop
//
//  Created by Akshay Easwaran on 2/12/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import "SettingsViewController.h"
#import "MemoriesViewController.h"

#import "HexColors.h"
#import "Chameleon.h"

@import Photos;
@import MessageUI;

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate> {
    BOOL todayMediaExists;
    MemoriesViewController *memVC;
}
@property (strong, nonatomic) UIImage *backgroundImage;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIVisualEffectView *visView;
@property (strong, nonatomic) UITableView *tableView;
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
    [label setFont:[UIFont boldSystemFontOfSize:18]];
    if (todayMediaExists) {
        [label setTextColor:[UIColor whiteColor]];
    } else {
        [label setTextColor:[UIColor blackColor]];
    }
    [label setText:@"Settings"];
    [label sizeToFit];
    [label setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, 25 + label.frame.size.height / 2.0)];
    
    UIView *navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, (25 + label.frame.size.height / 2.0) + 20)];
    navView.backgroundColor = [UIColor clearColor];
    [navView addSubview:label];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(10, (navView.frame.size.height / 2.0) - 22, 44, 44)];
    doneButton.center = CGPointMake(doneButton.center.x, label.center.y);
    if (todayMediaExists) {
        doneButton.tintColor = [UIColor hx_colorWithHexString:@"FFFFFF" alpha:0.25];
    } else {
        doneButton.tintColor = [UIColor hx_colorWithHexString:@"000000" alpha:0.25];
    }
    [doneButton setImage:[[UIImage imageNamed:@"close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(dismissVC) forControlEvents:UIControlEventTouchUpInside];
    [navView addSubview:doneButton];
    
    return navView;
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    if (memVC && memVC.todayMedia.count > 0) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

-(void)dismissVC {
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    memVC = (MemoriesViewController*)self.navigationController.presentingViewController;
    todayMediaExists = (memVC.todayMedia.count > 0);
    [self setNeedsStatusBarAppearanceUpdate];
    
    _imageView = [[UIImageView alloc] initWithImage:_backgroundImage];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:_imageView];
    if (todayMediaExists) {
        _visView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewHeaderFooterView class]]] setTextColor:[UIColor hx_colorWithHexString:@"FFFFFF" alpha:0.25]];
    } else {
        _visView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        [[UILabel appearanceWhenContainedInInstancesOfClasses:@[[UITableViewHeaderFooterView class]]] setTextColor:[UIColor hx_colorWithHexString:@"000000" alpha:0.25]];
    }
    
    _visView.frame = self.view.bounds;

    [_visView addSubview:[self navTitle]];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, [self navTitle].frame.origin.y + [self navTitle].frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height - [self navTitle].frame.origin.y + [self navTitle].frame.size.height) style:UITableViewStyleGrouped];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    if (todayMediaExists) {
        [_tableView setSeparatorColor:[UIColor hx_colorWithHexString:@"FFFFFF" alpha:0.25]];
    } else {
        [_tableView setSeparatorColor:[UIColor hx_colorWithHexString:@"000000" alpha:0.25]];
    }
    [_tableView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:_visView];
    [self.view addSubview:_tableView];

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 8;
    } else {
        return 2;
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        cell.backgroundColor = [UIColor clearColor];
        
        UIView *bgView = [[UIView alloc] initWithFrame:cell.bounds];
        if (todayMediaExists) {
            [cell.textLabel setTextColor:[UIColor whiteColor]];
            [bgView setBackgroundColor:[UIColor hx_colorWithHexString:@"FFFFFF" alpha:0.25]];
        } else {
            [cell.textLabel setTextColor:[UIColor blackColor]];
            [bgView setBackgroundColor:[UIColor hx_colorWithHexString:@"000000" alpha:0.1]];
        }
        [cell setSelectedBackgroundView:bgView];
    }

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [cell.textLabel setText:@"ChameleonFramework"];
        } else if (indexPath.row == 1) {
            [cell.textLabel setText:@"DZNEmptyDataSet"];
        } else if (indexPath.row == 2) {
            [cell.textLabel setText:@"FLAnimatedImage"];
        } else if (indexPath.row == 3) {
            [cell.textLabel setText:@"HexColors"];
        } else if (indexPath.row == 4) {
            [cell.textLabel setText:@"NYTPhotoViewer"];
        } else if (indexPath.row == 5) {
            [cell.textLabel setText:@"SFFocusViewLayout"];
        } else if (indexPath.row == 6) {
            [cell.textLabel setText:@"SVProgressHUD"];
        } else {
            [cell.textLabel setText:@"Icons8"];
        }
    } else {
        if (indexPath.row == 0) {
            [cell.textLabel setText:@"Developer's Website"];
        } else {
            [cell.textLabel setText:@"Email Developer"];
        }
    }
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) return @"Libraries Used in this App";
    else return @"Support";
}

-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1)
        return [NSString stringWithFormat:@"Version %@ (%@)\nCopyright (c) 2016 Akshay Easwaran.",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    else
        return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        NSString *url;
        if (indexPath.row == 0) {
            url = @"https://github.com/ViccAlexander/Chameleon";
        } else if (indexPath.row == 1) {
            url = @"https://github.com/dzenbot/DZNEmptyDataSet";
        } else if (indexPath.row == 2) {
            url = @"https://github.com/Flipboard/FLAnimatedImage";
        } else if (indexPath.row == 3) {
            url = @"https://github.com/mRs-/HexColors";
        } else if (indexPath.row == 4) {
            url = @"https://github.com/NYTimes/NYTPhotoViewer";
        } else if (indexPath.row == 5) {
            url = @"https://github.com/fdzsergio/SFFocusViewLayout";
        } else if (indexPath.row == 6) {
            url = @"https://github.com/SVProgressHUD/SVProgressHUD";
        } else {
            url = @"http://icons8.com";
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do you want to open this link in Safari?" message:nil preferredStyle:UIAlertControllerStyleAlert];
        alert.view.tintColor = kPHBaseColor;
        [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }]];
        [self presentViewController:alert animated:YES completion:^{
            alert.view.tintColor = kPHBaseColor;
        }];
    } else {
        if (indexPath.row == 0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Do you want to open this link in Safari?" message:nil preferredStyle:UIAlertControllerStyleAlert];
            alert.view.tintColor = kPHBaseColor;
            [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://akeaswaran.me"]];
            }]];
            [self presentViewController:alert animated:YES completion:^{
                alert.view.tintColor = kPHBaseColor;
            }];
        } else {
            MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
            [composer setMailComposeDelegate:self];
            [composer setToRecipients:@[@"akeaswaran@me.com"]];
            [composer setSubject:[NSString stringWithFormat:@"PhotoHop %@ (%@)",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
            [self presentViewController:composer animated:YES completion:nil];
        }
    }
}


-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultFailed:
            [self dismissViewControllerAnimated:YES completion:nil];
            [self emailFail:error];
            break;
        case MFMailComposeResultSent:
            [self dismissViewControllerAnimated:YES completion:nil];
            [self emailSuccess];
        default:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
    }
}

-(void)emailSuccess {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Your email was sent successfully!" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)emailFail:(NSError*)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Your email was unable to be sent." message:[NSString stringWithFormat:@"Sending failed with the following error: \"%@\".",error.localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
