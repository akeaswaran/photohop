//
//  PhotoViewCell.h
//  photohop
//
//  Created by Akshay Easwaran on 2/11/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoViewCell : UICollectionViewCell
//@IBOutlet weak var backgroundImageView: UIImageView!
//@IBOutlet weak var overlayView: UIView!
//@IBOutlet weak var titleLabel: UILabel!
//@IBOutlet weak var descriptionLabel: UILabel!
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@end
