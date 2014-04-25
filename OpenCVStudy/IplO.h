//
//  IplO.h
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/07.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/core/core_c.h>

@class OCVSeq;

@interface IplO : NSObject <NSCopying>
@property (nonatomic, assign, readonly) IplImage *iplImage;
@property (nonatomic, assign, readonly) void *data;
@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;
@property (nonatomic, assign, readonly) int bytesPerRow;
@property (nonatomic, assign, readonly) int depth;
@property (nonatomic, assign, readonly) int channels;
- (id)initWithIplImage:(IplImage *)iplImage;
- (id)initWithWidth:(int)width height:(int)height depth:(int)depth channels:(int)channels;
- (id)initWithBytes:(const void *)bytes width:(int)width height:(int)height bytesPerRow:(int)bytesPerRow depth:(int)depth channels:(int)channels;
- (id)initWithParameterIplImage:(IplO *)iplO;
- (id)initWithSizeParameterIplImage:(IplO *)iplO depth:(int)depth channels:(int)channels;
- (id)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)clear;
- (id)blackAndWhite:(double)threshold;
- (id)grayscale;
- (id)not;
- (OCVSeq *)findContrours:(int)mode type:(int)method;
- (void)drawContours:(OCVSeq *)contours lineWidth:(int)lineWidth extColor:(CvScalar)extColor holeColor:(CvScalar)holeColor depth:(int)depth;
- (id)pyrSegmentation:(OCVSeq **)seqO;
- (id)pyrMeanShiftFiltering;

/**
 * erode アルゴリズム(膨張)で画像を加工する
 * @param   shape          	CV_SHAPE_CROSS, CV_SHAPE_ELLIPSE, CV_SHAPE_RECT を指定
 * @param   size          	shape のサイズ
 * @param   anchor         	アンカー位置 (CV_SHAPE_CROSS の時のみ有効)
 * @param   iterations      繰り返し回数
 */
- (id)erodeWithShape:(int)shape size:(CvSize)size anchor:(CvPoint)anchor iterations:(int)iterations;

/**
 * dilate アルゴリズム(縮退)で画像を加工する
 * @param   shape          	CV_SHAPE_CROSS, CV_SHAPE_ELLIPSE, CV_SHAPE_RECT を指定
 * @param   size          	shape のサイズ
 * @param   anchor         	アンカー位置 (CV_SHAPE_CROSS の時のみ有効)
 * @param   iterations      繰り返し回数
 */
- (id)dilateWithShape:(int)shape size:(CvSize)size anchor:(CvPoint)anchor iterations:(int)iterations;

- (id)BGRImage;
- (CGImageRef)CGImage;
- (NSImage *)NSImage;
@end
