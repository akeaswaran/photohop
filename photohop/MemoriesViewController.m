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

#import <SFFocusViewLayout/SFFocusViewLayout.h>
#import <JGProgressHUD/JGProgressHUD.h>
#import "UIScrollView+EmptyDataSet.h"
#import "HexColors.h"

const NSInteger kPHPhotoLoadLimit = 100;

#ifdef NDEBUG
    #define PHPLog(...)
#else
    #define PHPLog NSLog
#endif

@interface MemoriesViewController () <UICollectionViewDataSource, UICollectionViewDelegate,DZNEmptyDataSetDelegate, DZNEmptyDataSetSource> {
    JGProgressHUD *HUD;
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
        UILabel *label = [[UILabel alloc] init];
        [label setFont:[UIFont systemFontOfSize:18]];
        [label setTextColor:[UIColor whiteColor]];
        [label setText:@"Today's Memories"];
        [label sizeToFit];
        if (_todayMedia.count == 0) {
            [label setText:@""];
        }
        //[label.layer setBorderColor:[UIColor redColor].CGColor];
        //[label.layer setBorderWidth:1.0];
        [label setCenter:CGPointMake([UIScreen mainScreen].bounds.size.width / 2.0, 25 + label.frame.size.height / 2.0)];
        
        navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, (25 + label.frame.size.height / 2.0) + 20)];
        navView.backgroundColor = [UIColor clearColor];
        [navView addSubview:label];
        if (_todayMedia.count > 0) {
            CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            gradientLayer.frame = navView.bounds;
            gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor, nil];
            gradientLayer.startPoint = CGPointMake(0.0, 0.0);
            gradientLayer.endPoint = CGPointMake(0.0, 1.0);
            gradientLayer.borderColor = [UIColor clearColor].CGColor;
            [navView.layer insertSublayer:gradientLayer atIndex:0];
        }
        
        //settings button
        UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 10 - 44, (navView.frame.size.height / 2.0) - 22, 44, 44)];
        settingsButton.center = CGPointMake(settingsButton.center.x, label.center.y);
        // [settingsButton.layer setBorderColor:[UIColor blueColor].CGColor];
        // [settingsButton.layer setBorderWidth:1.0];
        [settingsButton setImage:[UIImage imageNamed:@"SettingsImg"] forState:UIControlStateNormal];
        [settingsButton addTarget:self action:@selector(openSettings) forControlEvents:UIControlEventTouchUpInside];
        [navView addSubview:settingsButton];
    });
    return navView;
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
}

-(void)refreshMedia {
    _today = [NSDate date];
    _todayMedia = [NSMutableArray array];
    HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    HUD.indicatorView = [[JGProgressHUDRingIndicatorView alloc] initWithHUDStyle:HUD.style];
    HUD.textLabel.text = @"Looking through your photos...";
    HUD.center = self.view.center;
    [HUD showInView:self.view];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        [options setIncludeHiddenAssets:NO];
        [options setIncludeAllBurstAssets:YES];
        [options setIncludeAssetSourceTypes:PHAssetSourceTypeUserLibrary];
        [options setFetchLimit:kPHPhotoLoadLimit];
        _images = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
        for (int i = 0; i < _images.count; i++) {
            PHAsset *asset = _images[i];
            float progress = ((float)i / (float)_images.count);
            PHPLog(@"PROGRESS: %f", progress);
            [HUD setProgress:progress animated:YES];
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            options.version = PHImageRequestOptionsVersionOriginal;
            [[self imageManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                //PHPLog(@"DICTIONARY: %@", info);
                //PHPLog(@"PHAsset creationDate: %@", asset.creationDate);
                NSDateComponents *creationDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:asset.creationDate];
                NSDateComponents *todayDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[[self gmtFormatter] dateFromString:[[self gmtFormatter] stringFromDate:_today]]];
                if (todayDateComps.month == creationDateComps.month && todayDateComps.day == creationDateComps.day && todayDateComps.year != creationDateComps.year) {
                    [_todayMedia addObject:@{@"media" : result, @"date" : asset.creationDate, @"year" : @(creationDateComps.year)}];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (i == _images.count - 1) {
                        [[self navTitleBar] removeFromSuperview];
                        [self.view addSubview:[self navTitleBar]];
                        [HUD dismissAnimated:YES];
                        PHPLog(@"IMAGES: %lu", (unsigned long)_todayMedia.count);
                        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"year" ascending:NO];
                        _todayMedia = [NSMutableArray arrayWithArray:[_todayMedia.copy sortedArrayUsingDescriptors:@[sort]]];
                        [self.collectionView reloadData];
                    }
                });

            }];
        }
    });
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
    textColor = [UIColor hx_colorWithHexString:@"c9c9c9"];
    
    
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
    text = @"If you have memories from today in years past, you'll see them here.";
    font = [UIFont systemFontOfSize:13.0];
    textColor = [UIColor hx_colorWithHexString:@"cfcfcf"];
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
        textColor = [UIColor hx_colorWithHexString:(state == UIControlStateNormal) ? @"05adff" : @"6bceff"];
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
    return [UIColor hx_colorWithHexString:@"090909"];
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
        NSString *message = [NSString stringWithFormat:@"My memory from %@ ago today!",[self formatDateString:infoDict[@"year"]]];
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
