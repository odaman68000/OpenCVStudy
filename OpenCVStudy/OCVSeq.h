//
//  IplOSeq.h
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/core/core_c.h>

@class OCVStorage;

@interface OCVSeq : NSObject
@property (nonatomic, assign) CvSeq *seq;
@property (nonatomic, strong) OCVStorage *storage;
@property (nonatomic, assign) int headerSize;
@property (nonatomic, assign) CvSize baseSize;
- (id)initWithCvSeq:(CvSeq *)seq headerSize:(int)headerSize memStorage:(OCVStorage *)memStorage;
- (void)startTreeNodeIterator;
- (id)nextIterator;
- (int)total;
- (CvPoint *)pointAt:(int)index;
- (NSArray *)arrayOfCvPointNSValue;
- (NSArray *)arrayOfCGPointNSValue;
- (NSData *)memoryBlockOfCvPointArray;
- (id)pointSeq;
- (id)approxPoly:(double)eps recursive:(int)recursive;
- (id)convexHull2:(BOOL)clockwise;
@end
