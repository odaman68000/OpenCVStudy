//
//  IplO.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "IplO.h"
#import <opencv2/imgproc/imgproc_c.h>
#import "OCVStorage.h"
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

- (id)initWithWidth:(int)width height:(int)height depth:(int)depth channels:(int)channels {
	IplImage *iplImage = cvCreateImage(cvSize(width, height), depth, channels);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithParameterIplImage:(IplO *)iplO {
	IplImage *iplImage = cvCreateImage(cvGetSize(iplO.iplImage), iplO.depth, iplO.channels);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithSizeParameterIplImage:(IplO *)iplO depth:(int)depth channels:(int)channels {
	IplImage *iplImage = cvCreateImage(cvGetSize(iplO.iplImage), depth, channels);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithBytes:(const void *)bytes width:(int)width height:(int)height bytesPerRow:(int)bytesPerRow depth:(int)depth channels:(int)channels {
	IplImage iplHeader;
	cvInitImageHeader(&iplHeader, cvSize(width, height), depth, channels, 0, 4);
	cvSetData(&iplHeader, (void *)bytes, bytesPerRow);
	IplImage *iplImage = cvCloneImage(&iplHeader);
	return [self initWithIplImageWithoutCopy:iplImage];
}

- (id)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
	CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	void *imagedata = CVPixelBufferGetBaseAddress(pixelBuffer);
	int w = (int)CVPixelBufferGetWidth(pixelBuffer);
	int h = (int)CVPixelBufferGetHeight(pixelBuffer);
	int b = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
	id image = [self initWithBytes:imagedata width:w height:h bytesPerRow:b depth:IPL_DEPTH_8U channels:4];
	CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	return image;
}

- (id)copyWithZone:(NSZone *)zone {
	return [[self.class allocWithZone:zone] initWithIplImage:_iplImage];
}

- (void)clear {
	cvZero(_iplImage);
}

- (OCVSeq *)findContrours:(int)mode type:(int)method  {
	NSAssert(_channels == 1, @"%@: image channel should be 1.", NSStringFromClass(self.class));
	OCVStorage *st = [[OCVStorage alloc] init];
	CvContour *cvContour = NULL;
	if (mode < 0)
		mode = CV_RETR_LIST;
	if (method < 0)
		method = CV_CHAIN_APPROX_SIMPLE;
	cvFindContours(_iplImage, st.memStorage, (CvSeq **)&cvContour, sizeof(*cvContour), mode, method, cvPoint(0, 0));
	OCVSeq *ocvSeq = [[OCVSeq alloc] initWithCvSeq:(CvSeq *)cvContour headerSize:sizeof(*cvContour) memStorage:st];
	ocvSeq.baseSize = cvSize(_width, _height);
	return ocvSeq;
}

- (void)drawContours:(OCVSeq *)contours lineWidth:(int)lineWidth extColor:(CvScalar)extColor holeColor:(CvScalar)holeColor depth:(int)depth {
	cvDrawContours(_iplImage, contours.seq, extColor, holeColor, depth, lineWidth, 4, cvPoint(0, 0));
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

- (id)not {
	IplO *newImage = [[self.class alloc] initWithParameterIplImage:self];
	cvNot(_iplImage, newImage.iplImage);
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
		iplImage = cvCreateImage(cvGetSize(self.iplImage), IPL_DEPTH_8U, 4);
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

- (id)debugQuickLookObject {
	NSImage *debugImage = [self NSImage];
	return debugImage;
}

- (void)dealloc {
	if (_iplImage != NULL)
		cvReleaseImage(&_iplImage);
	if (_cgimage != NULL)
		CGImageRelease(_cgimage);
}
@end
