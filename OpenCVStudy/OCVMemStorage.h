//
//  IplOMemStorage.h
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/core/core_c.h>

@interface OCVMemStorage : NSObject
@property (nonatomic, assign) CvMemStorage *memStorage;
- (id)init;
- (id)initWithMemStorage:(CvMemStorage *)memStorage;
@end
