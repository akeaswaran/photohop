//
//  PhotoMemory.h
//  photohop
//
//  Created by Akshay Easwaran on 2/15/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Photos;

#import <NYTPhotoViewer/NYTPhoto.h>

@interface PhotoMemory : NSObject <NYTPhoto>
@property (strong, nonatomic) PHAsset  * _Nullable asset;
@property (strong, nonatomic) UIImage * _Nullable media;
@property (strong, nonatomic) NSNumber * _Nullable year;
@property (strong, nonatomic) NSDate * _Nullable imageCreationDate;
@property (nonatomic) UIImage * _Nullable image;
@property (nonatomic) NSData * _Nullable imageData;
@property (nonatomic) UIImage * _Nullable placeholderImage;
@property (nonatomic) NSAttributedString * _Nullable attributedCaptionTitle;
@property (nonatomic) NSAttributedString * _Nullable attributedCaptionSummary;
@property (nonatomic) NSAttributedString * _Nullable attributedCaptionCredit;

+(instancetype _Nonnull)memoryWithDictionary:(NSDictionary *_Nonnull)dictionary;
@end
