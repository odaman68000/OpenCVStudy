//
//  IplO.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "IplO.h"
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/legacy/legacy.hpp>
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

- (id)pyrSegmentation:(OCVSeq **)seqO {
	OCVStorage *st = [[OCVStorage alloc] init];
	CvSeq *seq = NULL;
	IplO *src = [self BGRImage];
	IplO *dst = [src copy];
	cvPyrSegmentation(src.iplImage, dst.iplImage, st.memStorage, &seq, 4, 255.0, 50.0);
	if (seqO != nil)
		*seqO = [[OCVSeq alloc] initWithCvSeq:seq headerSize:sizeof(*seq) memStorage:st];
	return dst;
}

- (id)pyrMeanShiftFiltering {
	IplO *src = [self BGRImage];
	IplO *dst = [src copy];
	cvPyrMeanShiftFiltering(src.iplImage, dst.iplImage, 30.0, 30.0, 2, cvTermCriteria(CV_TERMCRIT_ITER + CV_TERMCRIT_EPS, 5, 1));
	return dst;
}

- (id)erodeWithShape:(int)shape size:(CvSize)size anchor:(CvPoint)anchor iterations:(int)iterations {
	IplO *dst = [self copy];
	IplConvKernel *kernel = cvCreateStructuringElementEx(size.width, size.height, anchor.x, anchor.y, shape, NULL);
	if (kernel != NULL) {
		cvErode(_iplImage, dst.iplImage, kernel, iterations);
		cvReleaseStructuringElement(&kernel);
	}
	return dst;
}

- (id)dilateWithShape:(int)shape size:(CvSize)size anchor:(CvPoint)anchor iterations:(int)iterations {
	IplO *dst = [self copy];
	IplConvKernel *kernel = cvCreateStructuringElementEx(size.width, size.height, anchor.x, anchor.y, shape, NULL);
	if (kernel != NULL) {
		cvDilate(_iplImage, dst.iplImage, kernel, iterations);
		cvReleaseStructuringElement(&kernel);
	}
	return dst;
}

- (id)not {
	IplO *newImage = [[self.class alloc] initWithParameterIplImage:self];
	cvNot(_iplImage, newImage.iplImage);
	return newImage;
}

- (id)blackAndWhite:(double)threshold {
	IplO *grayscale = [self grayscale];
	IplO *newImage = [[self.class alloc] initWithSizeParameterIplImage:grayscale depth:IPL_DEPTH_8U channels:1];
	cvThreshold(grayscale.iplImage, newImage.iplImage, threshold, 255, (threshold < 0) ? CV_THRESH_OTSU : CV_THRESH_BINARY);
	return newImage;
}

- (id)grayscale {
	int cnv = CV_BGRA2GRAY;
	if (_channels == 1)
		return self;
	else if (_channels == 3)
		cnv = CV_BGR2GRAY;
	IplO *newImage = [[self.class alloc] initWithSizeParameterIplImage:self depth:IPL_DEPTH_8U channels:1];
	cvCvtColor(_iplImage, newImage.iplImage, cnv);
	return newImage;
}

- (id)BGRImage {
	int cnv = CV_BGRA2BGR;
	if (_channels == 1)
		cnv = CV_GRAY2BGR;
	else if (_channels == 3)
		return self;
	IplO *newImage = [[self.class alloc] initWithSizeParameterIplImage:self depth:IPL_DEPTH_8U channels:3];
	cvCvtColor(_iplImage, newImage.iplImage, cnv);
	return newImage;
}

- (id)BGRAImage {
	int cnv = CV_BGR2BGRA;
	if (_channels == 1)
		cnv = CV_GRAY2BGRA;
	else if (_channels == 4)
		return self;
	IplO *newImage = [[self.class alloc] initWithSizeParameterIplImage:self depth:IPL_DEPTH_8U channels:4];
	cvCvtColor(_iplImage, newImage.iplImage, cnv);
	return newImage;
}

- (CGImageRef)createCGImage {
	CGColorSpaceRef colorspace = NULL;
	CGBitmapInfo bitmapInfo = (CGBitmapInfo)kCGImageAlphaNone;
	int componentBytes = 1;
	IplImage *iplImage = _iplImage;
	if (_channels == 1) {
		colorspace = [NSColorSpace genericGrayColorSpace].CGColorSpace;
		if (_depth == IPL_DEPTH_16U || _depth == IPL_DEPTH_16S)
			componentBytes = sizeof(short);
		else if (_depth == IPL_DEPTH_32F || _depth == IPL_DEPTH_32S) {
			bitmapInfo |= kCGBitmapFloatComponents;
			componentBytes = sizeof(float);
		}
	} else {
		colorspace = [NSColorSpace genericRGBColorSpace].CGColorSpace;
		bitmapInfo = kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst;
		if (_depth == IPL_DEPTH_8U || _depth == IPL_DEPTH_8S) {
			if (_channels == 3) {
				iplImage = cvCreateImage(cvGetSize(self.iplImage), IPL_DEPTH_8U, 4);
				cvCvtColor(_iplImage, iplImage, CV_BGR2BGRA);
			}
		} else if (_depth == IPL_DEPTH_16U || _depth == IPL_DEPTH_16S)
			componentBytes = sizeof(short);
		else if (_depth == IPL_DEPTH_32F || _depth == IPL_DEPTH_32S) {
			bitmapInfo = kCGBitmapFloatComponents|kCGImageAlphaPremultipliedFirst;
			componentBytes = sizeof(float);
		}
	}
	CGContextRef context = CGBitmapContextCreate(iplImage->imageData, iplImage->width, iplImage->height, componentBytes * 8, iplImage->widthStep, colorspace, bitmapInfo);
	CGImageRef newCGImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	if (iplImage != _iplImage)
		cvReleaseImage(&iplImage);
	return newCGImage;
}

- (CGImageRef)CGImage {
	@synchronized(self) {
		if (_cgimage != NULL)
			_cgimage = [self createCGImage];
		return _cgimage;
	}
}

- (NSImage *)NSImage {
	CGImageRef cgimage = [self createCGImage];
	if (cgimage == NULL)
		return nil;
	NSImage *newImage = [[NSImage alloc] initWithCGImage:cgimage size:NSZeroSize];
	CGImageRelease(cgimage);
	return newImage;
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
