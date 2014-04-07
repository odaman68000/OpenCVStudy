//
//  IplOSeq.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "OCVSeq.h"
#import "OCVMemStorage.h"
#import <opencv2/core/core_c.h>
#import <opencv2/imgproc/imgproc_c.h>

@interface OCVSeq () {
	CvTreeNodeIterator treeNodeIterator;
}
@end

@implementation OCVSeq
- (id)init {
	OCVMemStorage *memStorage = [[OCVMemStorage alloc] init];
	return [self initWithMemStorage:memStorage];
}

- (id)initWithMemStorage:(OCVMemStorage *)memStorage {
	return [self initWithCvSeq:NULL headerSize:sizeof(CvSeq) memStorage:memStorage];
}

- (id)initWithCvSeq:(CvSeq *)seq headerSize:(int)headerSize memStorage:(OCVMemStorage *)memStorage {
	if ((self = [super init]) == nil)
		return nil;
	_seq = seq;
	_storage = memStorage;
	_headerSize = headerSize;
	return self;
}

- (id)approxPoly:(double)eps recursive:(BOOL)recursive {
	CvSeq *seq = cvApproxPoly(_seq, _headerSize, _storage.memStorage, CV_POLY_APPROX_DP, eps, recursive ? 1 : 0);
	return [[self.class alloc] initWithCvSeq:seq headerSize:_headerSize memStorage:_storage];
}

- (void)startTreeNodeIterator {
	cvInitTreeNodeIterator(&treeNodeIterator, _seq, 10);
}

- (id)nextIterator {
	CvSeq *next = cvNextTreeNode(&treeNodeIterator);
	if (next == NULL)
		return nil;
	return [[self.class alloc] initWithCvSeq:next headerSize:_headerSize memStorage:_storage];
}

- (int)total {
	return _seq->total;
}

- (CvPoint *)pointAt:(int)index {
	return (CvPoint *)cvGetSeqElem(_seq, index);
}
@end
