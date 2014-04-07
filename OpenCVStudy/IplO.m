//
//  IplO.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "IplO.h"
#import <opencv2/imgproc/imgproc_c.h>
#import "OCVMemStorage.h"
#import "OCVSeq.h"

@interface IplO ()
@property (nonatomic, assign) CGImageRef cgimage;
@end

@implementation IplO
- (id)initWithIplImageWithoutCopy:(IplImage *)iplImage {
	if ((self = [super init]) == nil)
		return nil;
	_iplImage = iplImage;
	_width = _iplImage->width;
	_height = _iplImage->height;
	_bytesPerRow = _iplImage->widthStep;
	_depth = _iplImage->depth;
	_channels = _iplImage->nChannels;
	_data = _iplImage->imageData;
	return self;
}

- (id)initWithIplImage:(IplImage *)iplImage {
	IplImage *newIplImage = cvCloneImage(iplImage);
	return [self initWithIplImageWithoutCopy:newIplImage];
}

- (id)initWithSize:(CvSize)size depth:(int)depth channels:(int)channels {
	IplImage *iplImage = cvCreateImage(size, depth, channels);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithParameterIplImage:(IplO *)iplO {
	IplImage *iplImage = cvCreateImage(iplO.cvSize, iplO.depth, iplO.channels);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithSizeParameterIplImage:(IplO *)iplO depth:(int)depth channels:(int)channels {
	IplImage *iplImage = cvCreateImage(iplO.cvSize, depth, channels);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithBytes:(const void *)bytes size:(CvSize)size bytesPerRow:(int)bytesPerRow depth:(int)depth channels:(int)channels {
	IplImage iplHeader;
	cvInitImageHeader(&iplHeader, size, depth, channels, 0, 4);
	cvSetData(&iplHeader, (void *)bytes, bytesPerRow);
	IplImage *iplImage = cvCloneImage(&iplHeader);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
	void *imagedata = CVPixelBufferGetBaseAddress(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int b = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
	return [self initWithBytes:imagedata size:cvSize(w, h) bytesPerRow:b depth:IPL_DEPTH_8U channels:4];
}

- (id)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithIplImage:_iplImage];
}

- (CvSize)cvSize {
	return cvSize(_width, _height);
}

- (OCVSeq *)findContrours:(int)mode type:(int)method  {
	OCVMemStorage *st = [[OCVMemStorage alloc] init];
	CvContour *cvContour = NULL;
	if (mode < 0)
		mode = CV_RETR_LIST;
	if (method < 0)
		method = CV_CHAIN_APPROX_SIMPLE;
	cvFindContours(_iplImage, st.memStorage, (CvSeq **)&cvContour, sizeof(*cvContour), mode, method, cvPoint(0, 0));
	return [[OCVSeq alloc] initWithCvSeq:(CvSeq *)cvContour headerSize:sizeof(*cvContour) memStorage:st];
}


- (id)blackAndWhite:(double)threshold {
	IplO *grayscale = [self grayscale];
	IplO *newImage = [[self.class alloc] initWithSizeParameterIplImage:grayscale depth:IPL_DEPTH_8U channels:1];
	cvThreshold(grayscale.iplImage, newImage.iplImage, threshold, 255, (threshold < 0) ? CV_THRESH_OTSU : CV_THRESH_BINARY);
	return newImage;
}

- (id)grayscale {
	if (_channels == 1)
		return self;
	int cnv = CV_BGRA2GRAY;
	if (_channels == 3)
		cnv = CV_BGR2GRAY;
	IplO *newImage = [[self.class alloc] initWithSizeParameterIplImage:self depth:IPL_DEPTH_8U channels:1];
	cvCvtColor(_iplImage, newImage.iplImage, cnv);
	return newImage;
}

- (CGImageRef)CGImage {
	CGColorSpaceRef colorspace = NULL;
	CGBitmapInfo bitmapInfo = 0;
	int componentBits = 8;
	IplImage *iplImage = _iplImage;
	if (_channels == 1) {
		if (_depth == IPL_DEPTH_8U) {
			colorspace = [NSColorSpace genericGrayColorSpace].CGColorSpace;
			bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone;
		} else if (_depth == IPL_DEPTH_16U) {
			colorspace = [NSColorSpace genericGrayColorSpace].CGColorSpace;
			bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone;
			componentBits = 16;
		}
	} else if (_channels == 3) {
		colorspace = [NSColorSpace genericRGBColorSpace].CGColorSpace;
		bitmapInfo = kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst;
		iplImage = cvCreateImage(self.cvSize, IPL_DEPTH_8U, 4);
		cvCvtColor(_iplImage, iplImage, CV_BGR2BGRA);
	} else {
		colorspace = [NSColorSpace genericRGBColorSpace].CGColorSpace;
		bitmapInfo = kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst;
	}
	CGContextRef context = CGBitmapContextCreate(iplImage->imageData, iplImage->width, iplImage->height, componentBits, iplImage->widthStep, colorspace, bitmapInfo);
	CGImageRef newCGImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	if (_cgimage != NULL)
		CGImageRelease(_cgimage);
	_cgimage = newCGImage;
	if (iplImage != _iplImage)
		cvReleaseImage(&iplImage);
	return _cgimage;
}

- (NSImage *)NSImage {
	CGImageRef cgimage = [self CGImage];
	return [[NSImage alloc] initWithCGImage:cgimage size:NSZeroSize];
}

- (void)dealloc {
	if (_iplImage != NULL)
		cvReleaseImage(&_iplImage);
	if (_cgimage != NULL)
		CGImageRelease(_cgimage);
}
@end
