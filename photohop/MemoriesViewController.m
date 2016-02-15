//
//  ViewController.m
//  photohop
//
//  Created by Akshay Easwaran on 2/11/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import "MemoriesViewController.h"
#import "PhotoViewCell.h"
#import "SettingsViewController.h"
#import <Photos/Photos.h>
#import "AppDelegate.h"

#import <SFFocusViewLayout/SFFocusViewLayout.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "UIScrollView+EmptyDataSet.h"
#import "HexColors.h"
#import "Chameleon.h"

#ifdef NDEBUG
    #define PHPLog(...)
#else
    #define PHPLog NSLog
#endif

@interface MemoriesViewController () <UICollectionViewDataSource, UICollectionViewDelegate,DZNEmptyDataSetDelegate, DZNEmptyDataSetSource> {
    UILabel *titleLabel;
}
@property (strong, nonatomic) NSDate *today;
@property (strong, nonatomic) PHFetchResult *images;
@end

@implementation MemoriesViewController

-(NSString*)formatDateString:(NSNumber*)year {
    NSDateComponents *todayDateComps = [[NSCalendar currentCalendar] components: NSCalendarUnitYear fromDate:_today];
    NSInteger yearsBetween = (todayDateComps.year - year.integerValue);
    if (yearsBetween > 1) {
        return [NSString stringWithFormat:@"%li years ago", (long)yearsBetween];
    } else {
        return [NSString stringWithFormat:@"1 year ago"];
    }
}

-(NSDateFormatter*)dateFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[NSTimeZone localTimeZone].secondsFromGMT];
        [formatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
    });
    return formatter;
}

-(NSDateFormatter*)gmtFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm";
        NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        [formatter setTimeZone:gmt];
    });
    return formatter;
}

- (UIView*)navTitleBar {
    static dispatch_once_t onceToken;
    static UIView *navView;
    dispatch_once(&onceToken, ^{
        titleLabel = [[UILabel alloc] init];
        [titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [titleLabel setTextColor:[UIColor blackColor]];
        [titleLabel setText:@"Today's Memories"];
        [titleLabel sizeToFit];
        if (_todayMedia.count == 0) {
            [titleLabel setText:@""];
        }
        //[label.layer setBorderColor:[UIColor redColor].CGColor];
        //[label.layer setBorderWidth:1.0];
        [titleLabel setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, 25 + titleLabel.frame.size.height / 2.0)];
        
        navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, (25 + titleLabel.frame.size.height / 2.0) + 20)];
        navView.backgroundColor = [UIColor clearColor];
        [navView addSubview:titleLabel];
        if (_todayMedia.count > 0) {
            CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            gradientLayer.frame = navView.bounds;
            gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
            gradientLayer.startPoint = CGPointMake(0.0, 0.0);
            gradientLayer.endPoint = CGPointMake(0.0, 1.0);
            gradientLayer.borderColor = [UIColor clearColor].CGColor;
            [navView.layer insertSublayer:gradientLayer atIndex:0];
        }
        
    });
    return navView;
}

-(UIButton*)settingsButton {
    //settings button
    static dispatch_once_t onceToken;
    static UIButton *button;
    dispatch_once(&onceToken, ^{
        button = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 10 - 44, ([self navTitleBar].frame.size.height / 2.0) - 22, 44, 44)];
        button.center = CGPointMake(button.center.x, titleLabel.center.y);
        // [settingsButton.layer setBorderColor:[UIColor blueColor].CGColor];
        // [settingsButton.layer setBorderWidth:1.0];
        UIImage *buttonImg = [[UIImage imageNamed:@"SettingsImg"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        button.tintColor = kPHContrastTextColor;
        [button setImage:buttonImg forState:UIControlStateNormal];
        [button addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
    });
    
    return button;
}

-(PHImageManager*)imageManager {
    static dispatch_once_t onceToken;
    static PHImageManager *imageManager;
    dispatch_once(&onceToken, ^{
        imageManager = [[PHImageManager alloc] init];
    });
    return imageManager;
}

-(void)openSettings {
    SettingsViewController *settings = [[SettingsViewController alloc] initWithImage:[self currentScreenImage]];
    UINavigationController *setNav = [[UINavigationController alloc] initWithRootViewController:settings];
    setNav.navigationBarHidden = YES;
    setNav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:setNav animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    kPHBaseColor = [UIColor hx_colorWithHexString:@"f0f0f0"];
    kPHContrastTextColor = [UIColor colorWithContrastingBlackOrWhiteColorOn:kPHBaseColor isFlat:YES];
    kPHButtonColor = [UIColor flatOrangeColorDark];
    [self.collectionView setDelegate:self];
    [self.collectionView setDataSource:self];
    [self.collectionView registerNib:[UINib nibWithNibName:@"PhotoViewCell" bundle:nil] forCellWithReuseIdentifier:@"PhotoViewCell"];
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized) {
       [self refreshMedia];
    }
    [self.view addSubview:[self navTitleBar]];
    [[self navTitleBar] addSubview:[self settingsButton]];
    [self setNeedsStatusBarAppearanceUpdate];
    
}

-(void)refreshMedia {
    _today = [NSDate date];
    _todayMedia = [NSMutableArray array];
    NSMutableArray *todayAssets = [NSMutableArray array];
    [SVProgressHUD showWithStatus:@"Looking through your photos..."];
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleLight];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    [options setIncludeHiddenAssets:NO];
    [options setIncludeAllBurstAssets:NO];
    [options setIncludeAssetSourceTypes:PHAssetSourceTypeUserLibrary];
    //[options setFetchLimit:100];
    _images = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    for (int i = 0; i < _images.count; i++) {
        PHAsset *asset = _images[i];
        [SVProgressHUD showProgress:(CGFloat)i / (CGFloat)_images.count status:[NSString stringWithFormat:@"Checking image %i of %lu", i, (unsigned long)_images.count]];
        NSDateComponents *creationDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:asset.creationDate];
        NSDateComponents *todayDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[[self gmtFormatter] dateFromString:[[self gmtFormatter] stringFromDate:_today]]];
        if (todayDateComps.month == creationDateComps.month && todayDateComps.day == creationDateComps.day && todayDateComps.year != creationDateComps.year) {
            [todayAssets addObject:asset];
        }
    }
    
    if (todayAssets.count > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [SVProgressHUD showProgress:0 status:[NSString stringWithFormat:@"Getting image 0 of %lu", (unsigned long)todayAssets.count]];
        
            PHImageRequestOptions *reqOptions = [[PHImageRequestOptions alloc] init];
            reqOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            reqOptions.networkAccessAllowed = YES;
            reqOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
            reqOptions.version = PHImageRequestOptionsVersionOriginal;
            for (int j = 0; j < todayAssets.count; j++) {
                PHAsset *curAsset = todayAssets[j];
                [[self imageManager] requestImageForAsset:curAsset targetSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, 280) contentMode:PHImageContentModeAspectFill options:reqOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                    [SVProgressHUD showProgress:(CGFloat)j / (CGFloat)todayAssets.count status:[NSString stringWithFormat:@"Getting image %i of %lu", j, (unsigned long)todayAssets.count]];
                    NSDateComponents *creationDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:curAsset.creationDate];
                    if (result) {
                        [_todayMedia addObject:@{@"media" : result, @"date" : curAsset.creationDate, @"year" : @(creationDateComps.year)}];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (j == _images.count - 1) {
                            [SVProgressHUD showSuccessWithStatus:@"Done!"];
                            [[self navTitleBar] removeFromSuperview];
                            [self.view addSubview:[self navTitleBar]];
                            
                            PHPLog(@"IMAGES: %lu", (unsigned long)_todayMedia.count);
                            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"year" ascending:NO];
                            _todayMedia = [NSMutableArray arrayWithArray:[_todayMedia.copy sortedArrayUsingDescriptors:@[sort]]];
                            [self.collectionView reloadData];
                            
                            if (_todayMedia.count > 0) {
                                UIApplication *application = [UIApplication sharedApplication];
                                if (_todayMedia.count > 0) {
                                    application.statusBarStyle = UIStatusBarStyleLightContent;
                                    [[self settingsButton] setTintColor:[UIColor whiteColor]];
                                    [self.collectionView setBackgroundColor:[UIColor blackColor]];
                                } else {
                                    application.statusBarStyle = UIStatusBarStyleDefault;
                                    [[self settingsButton] setTintColor:kPHContrastTextColor];
                                }
                                [self setNeedsStatusBarAppearanceUpdate];
                            }
                        }
                    });
                }];
            }
        });
    } else {
        [SVProgressHUD showSuccessWithStatus:@"Done!"];
        [[self navTitleBar] removeFromSuperview];
        [self.view addSubview:[self navTitleBar]];
        UIApplication *application = [UIApplication sharedApplication];
        application.statusBarStyle = UIStatusBarStyleDefault;
        [[self settingsButton] setTintColor:kPHContrastTextColor];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

-(UIImage*)currentScreenImage {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIGraphicsBeginImageContext(screenRect.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] set];
    CGContextFillRect(ctx, screenRect);
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window.layer renderInContext:ctx];
    UIImage *screengrab = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screengrab;
}

#pragma mark - DZNEmptyDataSetSource Methods

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = nil;
    UIFont *font = nil;
    UIColor *textColor = nil;
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted) {
        text = @"No Memories Imported";
    } else {
        text = @"No Memories Today!";
    }
    
    font = [UIFont boldSystemFontOfSize:16.0];
    textColor = kPHContrastTextColor;     
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];

}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = nil;
    UIFont *font = nil;
    UIColor *textColor = nil;
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted) {
        text = @"Allow PhotoHop access to your photos to see memories from years gone by.";
    } else {
        text = @"If you have memories from today in years past, you'll see them here.";
    }
    font = [UIFont systemFontOfSize:13.0];
    textColor = kPHContrastTextColor;
    paragraph.lineSpacing = 4.0;
    
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    if (paragraph) [attributes setObject:paragraph forKey:NSParagraphStyleAttributeName];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    
    return attributedString;
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted) {
        NSString *text = nil;
        UIFont *font = nil;
        UIColor *textColor = nil;
        font = [UIFont boldSystemFontOfSize:16.0];
        textColor = kPHButtonColor;
        text = @"Import your photos";
        NSMutableDictionary *attributes = [NSMutableDictionary new];
        if (font) [attributes setObject:font forKey:NSFontAttributeName];
        if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
        
        return [[NSAttributedString alloc] initWithString:text attributes:attributes];
    } else {
        return nil;
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return kPHBaseColor;//[UIColor hx_colorWithHexString:@"090909"];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return 0.0;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView
{
    return 20.0;
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    return YES;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView
{
    return YES;
}

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button
{
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                [self refreshMedia];
            }
        }];
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

-(void)shareMemory:(UILongPressGestureRecognizer *)longPress  {
    PhotoViewCell *cell = (PhotoViewCell*)longPress.view;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (self.presentedViewController == nil) {
        NSDictionary *infoDict = _todayMedia[indexPath.item];
        NSString *message = [NSString stringWithFormat:@"My memory from %@ today!",[self formatDateString:infoDict[@"year"]]];
        UIImage *image = infoDict[@"media"];
        
        NSArray *shareItems = @[message, image];
        
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
        
        [self presentViewController:avc animated:YES completion:nil];
    }
   
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoViewCell *photoCell = (PhotoViewCell*)cell;
    NSDictionary *infoDict = _todayMedia[indexPath.item];
    photoCell.titleLabel.text = [self formatDateString:infoDict[@"year"]];
    photoCell.descriptionLabel.text = @"";
    UIImage *media = infoDict[@"media"];
    [photoCell.backgroundImageView setImage:media];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(shareMemory:)];
    longPress.cancelsTouchesInView = YES;
    longPress.minimumPressDuration = 1.0;
    [photoCell addGestureRecognizer:longPress];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _todayMedia.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoViewCell"
                                                                           forIndexPath:indexPath];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SFFocusViewLayout *focusViewLayout = (SFFocusViewLayout*)collectionView.collectionViewLayout;
    CGFloat offset = focusViewLayout.dragOffset * indexPath.item;
    if (collectionView.contentOffset.y != offset) {
        [collectionView setContentOffset:CGPointMake(0, offset) animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
