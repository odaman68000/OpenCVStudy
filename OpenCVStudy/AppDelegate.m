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
#import "IplO.h"
#import "OCVSeq.h"

@interface AppDelegate () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_semaphore_t imgProcSemaphore;
@property (nonatomic, strong) dispatch_semaphore_t imgCreaSemaphore;
@property (nonatomic, strong) IplO *curImage;
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

- (IplO *)createNewImage:(IplO *)iplImage {
	IplO *grayImage = [[IplO alloc] initWithSizeParameterIplImage:iplImage depth:IPL_DEPTH_8U channels:1];
	IplO *binaImage = [[IplO alloc] initWithSizeParameterIplImage:iplImage depth:IPL_DEPTH_8U channels:1];
	cvCvtColor(iplImage.iplImage, grayImage.iplImage, CV_BGRA2GRAY);
	cvThreshold(grayImage.iplImage, binaImage.iplImage, 64, 255, CV_THRESH_BINARY);

	OCVSeq *contour = [binaImage findContrours:-1 type:-1];
	OCVSeq *approxPoly = [contour approxPoly:0.001 recursive:NO];
	[approxPoly startTreeNodeIterator];
	int seqCount = 0;
	for (OCVSeq *seq = [approxPoly nextIterator]; seq != nil; seq = [approxPoly nextIterator], seqCount++) {
		NSLog(@"%d: points: %d", seqCount, seq.total);
	}
	cvDrawContours(iplImage.iplImage, contour.seq, CV_RGB(255, 0, 0), CV_RGB(0, 0, 255), 1, 2, 4, cvPoint(0, 0));
	return iplImage;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(pixelBuffer, 0);

	IplO *iplO = [[IplO alloc] initWithPixelBuffer:pixelBuffer];
	dispatch_semaphore_wait(self.imgCreaSemaphore, DISPATCH_TIME_FOREVER);
	self.curImage = iplO;
	dispatch_semaphore_signal(self.imgCreaSemaphore);

	if (dispatch_semaphore_wait(self.imgProcSemaphore, DISPATCH_TIME_NOW) == 0) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			dispatch_semaphore_wait(self.imgCreaSemaphore, DISPATCH_TIME_FOREVER);
			IplO *prcImage = self.curImage;
			dispatch_semaphore_signal(self.imgCreaSemaphore);
			IplO *newImage = [self createNewImage:prcImage];
			NSImage *nsImage = newImage.NSImage;
			dispatch_async(dispatch_get_main_queue(), ^{
				self.imageView.hidden = NO;
				self.imageView.image = nsImage;
			});
			dispatch_semaphore_signal(self.imgProcSemaphore);
		});
	}

	CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}
@end
