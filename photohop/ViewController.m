//
//  ViewController.m
//  photohop
//
//  Created by Akshay Easwaran on 2/11/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>

@interface ViewController ()
@property (strong, nonatomic) NSDate *today;
@property (strong, nonatomic) PHFetchResult *images;
@property (strong, nonatomic) NSMutableArray *todayMedia;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blueColor];
    _today = [NSDate date];
    _todayMedia = [NSMutableArray array];
    _images = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    for (PHAsset *asset  in _images) {
        PHContentEditingInputRequestOptions *options = [[PHContentEditingInputRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        
        [asset requestContentEditingInputWithOptions:options completionHandler:^(PHContentEditingInput *contentEditingInput, NSDictionary *info) {
            CIImage *fullImage = [CIImage imageWithContentsOfURL:contentEditingInput.fullSizeImageURL];
            NSLog(@"FULL IMAGE CREATION DATE STRING: %@", fullImage.properties[@"{TIFF}"][@"DateTime"]);
            NSDate *creationDate = fullImage.properties[@"{TIFF}"][@"DateTime"];
            NSLog(@"CREATION DATE: %@", creationDate);
            NSDateComponents *creationDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth fromDate:creationDate];
            NSDateComponents *todayDateComps = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth fromDate:_today];
            if (todayDateComps.month == creationDateComps.month && todayDateComps.day == creationDateComps.day) {
                [_todayMedia addObject:asset];
            }
        }];
    }
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
