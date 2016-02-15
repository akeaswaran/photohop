//
//  PhotoMemory.m
//  photohop
//
//  Created by Akshay Easwaran on 2/15/16.
//  Copyright © 2016 Akshay Easwaran. All rights reserved.
//

#import "PhotoMemory.h"

@implementation PhotoMemory
+(NSDateFormatter*)dateFormatter {
    static dispatch_once_t onceToken;
    static NSDateFormatter *formatter;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterLongStyle];
    });
    return formatter;
}

+(instancetype)memoryWithDictionary:(NSDictionary*)dictionary {
    PhotoMemory *memory = [[PhotoMemory alloc] init];
    [memory setAsset:dictionary[@"asset"]];
    [memory setImageCreationDate:memory.asset.creationDate];
    [memory setMedia:dictionary[@"media"]];
    [memory setYear:dictionary[@"year"]];
    
    [memory setImage:memory.media];
    [memory setImageData:UIImageJPEGRepresentation(memory.media, 0.75)];
    [memory setAttributedCaptionTitle:[[NSAttributedString alloc] initWithString:[[PhotoMemory dateFormatter] stringFromDate:memory.imageCreationDate] attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]}]];
    [memory setAttributedCaptionSummary:nil];
    [memory setAttributedCaptionCredit:[[NSAttributedString alloc] initWithString:@"From your photo library" attributes:@{NSForegroundColorAttributeName: [UIColor grayColor], NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]}]];
    return memory;
}
@end
