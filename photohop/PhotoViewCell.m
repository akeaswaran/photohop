//
//  PhotoViewCell.m
//  photohop
//
//  Created by Akshay Easwaran on 2/11/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import "PhotoViewCell.h"

@interface PhotoViewCell ()


@end

@implementation PhotoViewCell

-(void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    [super applyLayoutAttributes:layoutAttributes];
    CGFloat featuredHeight = 280;
    CGFloat standardHeight = 100;
    
    CGFloat delta = 1 - (featuredHeight - CGRectGetHeight(self.frame)) / (featuredHeight - standardHeight);
    
    CGFloat minAlpha = 0.3;
    CGFloat maxAlpha = 0.75;
    
    CGFloat alpha = maxAlpha - (delta * (maxAlpha - minAlpha));
    self.overlayView.alpha = alpha;
    
    CGFloat scale = MAX(delta, 0.5);
    self.titleLabel.transform = CGAffineTransformMakeScale(scale, scale);
    self.descriptionLabel.alpha = delta;
}


@end
