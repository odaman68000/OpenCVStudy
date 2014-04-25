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
#import "OCV.h"
#import "IplO.h"
#import "OCVSeq.h"

@interface AppDelegate () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, weak) IBOutlet NSImageView *imageView;
@property (nonatomic, weak) IBOutlet NSTextField *framesPerSecTextField;
@property (nonatomic, assign) int frames;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_semaphore_t imgProcSemaphore;
@property (atomic, strong) IplO *curImage;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	self.imgProcSemaphore = dispatch_semaphore_create(1);
	AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *cameraInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:nil];
	AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
	dataOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
	[dataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("com.odaman.OpenCVStudy.cameraqueue", DISPATCH_QUEUE_SERIAL)];
	self.captureSession = [[AVCaptureSession alloc] init];
	[self.captureSession addInput:cameraInput];
	[self.captureSession addOutput:dataOutput];
	[self.captureSession startRunning];
	NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)timer:(NSTimer *)timer {
	dispatch_async(dispatch_get_main_queue(), ^{
		self.framesPerSecTextField.intValue = self.frames;
		self.frames = 0;
	});
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self.captureSession stopRunning];
}

- (IplO *)createNewImage:(IplO *)iplImage {
	IplO *binaImage = [[iplImage blackAndWhite:64] not];
	binaImage = [binaImage erodeWithShape:CV_SHAPE_RECT size:cvSize(20, 20) anchor:cvPoint(0, 0) iterations:1];
	OCVSeq *contour = [[binaImage copy] findContrours:-1 type:-1];
	OCVSeq *approxPoly = [contour approxPoly:5.0 recursive:1];
	IplO *retImage = [iplImage copy];
	[retImage drawContours:approxPoly lineWidth:2 extColor:[NSColor redColor].cvScalar holeColor:[NSColor greenColor].cvScalar depth:10];
	return retImage;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	self.curImage = [[IplO alloc] initWithPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
	if (dispatch_semaphore_wait(self.imgProcSemaphore, DISPATCH_TIME_NOW) == 0) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			IplO *newImage = [self createNewImage:self.curImage];
			NSImage *nsImage = newImage.NSImage;
			dispatch_async(dispatch_get_main_queue(), ^{
				self.imageView.hidden = NO;
				self.imageView.image = nsImage;
			});
			self.frames++;
			dispatch_semaphore_signal(self.imgProcSemaphore);
		});
	}
}
@end
