//
//  ViewController.h
//  photohop
//
//  Created by Akshay Easwaran on 2/11/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import <UIKit/UIKit.h>

static UIColor *kPHBaseColor;
static UIColor *kPHContrastTextColor;
static UIColor *kPHButtonColor;

@import Photos;

@interface MemoriesViewController : UIViewController
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *todayMedia;
@end

