//
//  AppDelegate.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/04.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import <opencv2/core/core_c.h>
#import <opencv2/imgproc/imgproc_c.h>

static __inline__ NSImage *NSImageFromIplImage(IplImage *iplImage) {
	CGColorSpaceRef colorspace = [NSColorSpace genericRGBColorSpace].CGColorSpace;
	CGContextRef context = CGBitmapContextCreate(iplImage->imageData, iplImage->width, iplImage->height, 8, iplImage->widthStep, colorspace, kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst);
	CGImageRef cgImage = CGBitmapContextCreateImage(context);
	NSImage *nsImage = [[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize];
	CGImageRelease(cgImage);
	CGContextRelease(context);
	return nsImage;
}

@interface AppDelegate () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_semaphore_t imgProcSemaphore;
@property (nonatomic, strong) dispatch_semaphore_t imgCreaSemaphore;
@property (nonatomic, assign) IplImage *curImage;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.imgProcSemaphore = dispatch_semaphore_create(1);
	self.imgCreaSemaphore = dispatch_semaphore_create(1);
	AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:nil];
	AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
	dataOutput.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA) };
	[dataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("com.odaman.OpenCVStudy.cameraqueue", DISPATCH_QUEUE_SERIAL)];
	self.captureSession = [[AVCaptureSession alloc] init];
	[self.captureSession addInput:cameraInput];
	[self.captureSession addOutput:dataOutput];
	[self.captureSession startRunning];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self.captureSession stopRunning];
}

- (IplImage *)createNewImage:(IplImage *)iplImage {
	return iplImage;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);

	void *imagedata = CVPixelBufferGetBaseAddress(pixelBuffer);
	size_t w = CVPixelBufferGetWidth(pixelBuffer);
	size_t h = CVPixelBufferGetHeight(pixelBuffer);
	size_t b = CVPixelBufferGetBytesPerRow(pixelBuffer);

	IplImage *tmpimage = cvCreateImageHeader(cvSize((int)w, (int)h), IPL_DEPTH_8U, 4);
	cvSetData(tmpimage, imagedata, (int)b);

	dispatch_semaphore_wait(self.imgCreaSemaphore, DISPATCH_TIME_FOREVER);
	if (self.curImage != NULL)
		cvReleaseImage(&_curImage);
	self.curImage = cvCloneImage(tmpimage);
	dispatch_semaphore_signal(self.imgCreaSemaphore);

	cvReleaseImageHeader(&tmpimage);

	if (dispatch_semaphore_wait(self.imgProcSemaphore, DISPATCH_TIME_NOW) == 0) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			dispatch_semaphore_wait(self.imgCreaSemaphore, DISPATCH_TIME_FOREVER);
			IplImage *prcImage = cvCloneImage(self.curImage);
			dispatch_semaphore_signal(self.imgCreaSemaphore);
			IplImage *newImage = [self createNewImage:prcImage];
			NSImage *nsImage = NSImageFromIplImage(newImage);
			dispatch_async(dispatch_get_main_queue(), ^{
				self.imageView.hidden = NO;
				self.imageView.image = nsImage;
			});
			if (prcImage == newImage)
				cvReleaseImage(&prcImage);
			else {
				cvReleaseImage(&prcImage);
				cvReleaseImage(&newImage);
			}
			dispatch_semaphore_signal(self.imgProcSemaphore);
		});
	}

	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)dealloc {
	if (_curImage != NULL)
		cvReleaseImage(&_curImage);
}
@end
