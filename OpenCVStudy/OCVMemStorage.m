//
//  IplOMemStorage.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "OCVMemStorage.h"

@implementation OCVMemStorage
- (id)init {
	CvMemStorage *memStorage = cvCreateMemStorage(0);
	return [self initWithMemStorage:memStorage];
}

- (id)initWithMemStorage:(CvMemStorage *)memStorage {
	if ((self = [super init]) == nil)
		return nil;
	_memStorage = memStorage;
	return self;
}

- (void)dealloc {
	if (_memStorage != NULL)
		cvReleaseMemStorage(&_memStorage);
}
@end
