//
//  IplOSeq.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "OCVSeq.h"
#import "OCVStorage.h"
#import <opencv2/core/core_c.h>
#import <opencv2/imgproc/imgproc_c.h>
#import "IplO.h"

@interface OCVSeq () {
	CvTreeNodeIterator treeNodeIterator;
}
@end

@implementation OCVSeq
- (id)initWithType:(int)type {
	OCVStorage *storage = [[OCVStorage alloc] init];
	size_t elemSize = 0;
	if (type == CV_SEQ_ELTYPE_POINT)
		elemSize = sizeof(CvPoint);
	else if (type == CV_SEQ_ELTYPE_POINT3D)
		elemSize = sizeof(CvPoint3D32f);
	else
		return nil;
	CvSeq *seq = cvCreateSeq(type, sizeof(CvSeq), elemSize, storage.memStorage);
	return [self initWithCvSeq:seq headerSize:sizeof(CvSeq) memStorage:storage];
}

- (id)initWithCvSeq:(CvSeq *)seq headerSize:(int)headerSize memStorage:(OCVStorage *)memStorage {
	if ((self = [super init]) == nil)
		return nil;
	_seq = seq;
	_storage = memStorage;
	_headerSize = headerSize;
	return self;
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

- (id)pointSeq {
	OCVSeq *newSeq = [[OCVSeq alloc] initWithType:CV_SEQ_ELTYPE_POINT];
	for (int i = 0; i < _seq->total; i++) {
		CvPoint *point = (CvPoint *)cvGetSeqElem(_seq, i);
		cvSeqPush(newSeq.seq, point);
	}
	newSeq.baseSize = _baseSize;
	return newSeq;
}

- (id)approxPoly:(double)eps recursive:(BOOL)recursive {
	CvSeq *seq = cvApproxPoly(_seq, _headerSize, _storage.memStorage, CV_POLY_APPROX_DP, eps, recursive ? 1 : 0);
	OCVSeq *newSeq = [[self.class alloc] initWithCvSeq:seq headerSize:_headerSize memStorage:_storage];
	newSeq.baseSize = _baseSize;
	return newSeq;
}

- (id)convexHull2:(BOOL)clockwise {
	CvSeq *hull = cvConvexHull2(_seq, NULL, clockwise ? CV_CLOCKWISE : CV_COUNTER_CLOCKWISE, 0);
	OCVSeq *newSeq = [[self.class alloc] initWithCvSeq:hull headerSize:0 memStorage:_storage];
	newSeq.baseSize = _baseSize;
	return newSeq;
}

- (id)debugQuickLookObject {
	if (_seq == NULL)
		return nil;
	if (_baseSize.width <= 0 || _baseSize.height <= 0)
		return nil;
	IplO *img = [[IplO alloc] initWithWidth:_baseSize.width height:_baseSize.height depth:IPL_DEPTH_8U channels:4];
	[img clear];
	[img drawContours:self lineWidth:2 extColor:CV_RGB(255, 0, 0) holeColor:CV_RGB(0, 255, 0) depth:10];
	return [img NSImage];
}
@end
