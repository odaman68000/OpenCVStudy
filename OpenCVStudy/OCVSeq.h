//
//  IplOSeq.h
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/core/core_c.h>

@class OCVMemStorage;

@interface OCVSeq : NSObject
@property (nonatomic, assign) CvSeq *seq;
@property (nonatomic, strong) OCVMemStorage *memStorage;
@property (nonatomic, assign) int headerSize;
- (id)init;
- (id)initWithMemStorage:(OCVMemStorage *)memStorage;
- (id)initWithCvSeq:(CvSeq *)seq headerSize:(int)headerSize memStorage:(OCVMemStorage *)memStorage;
- (id)approxPoly:(double)eps recursive:(BOOL)recursive;
- (void)startTreeNodeIterator;
- (OCVSeq *)nextIterator;
- (int)total;
- (CvPoint *)pointAt:(int)index;
@end
