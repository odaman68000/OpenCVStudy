//
//  OCV.m
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/14.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import "OCV.h"

@implementation NSColor (OCVExtension)
+ (id)colorWithCvScalar:(CvScalar)cvScalar {
	return [self colorWithCalibratedRed:cvScalar.val[0] / 255.0 green:cvScalar.val[1] / 255.0 blue:cvScalar.val[2] / 255.0 alpha:cvScalar.val[3] / 255.0];
}

- (CvScalar)cvScalar {
	CGFloat components[4];
	[self getComponents:components];
	if (self.numberOfComponents == 2) {
		CGFloat alpha = components[1];
		components[1] = components[2] = components[0];
		components[3] = alpha;
	}
	return cvScalar(components[2] * 255.0, components[1] * 255.0, components[0] * 255.0, components[3] * 255.0);
}
@end

@implementation NSValue (OCVExtension)
+ (id)valueWithGLKVector3:(GLKVector3)vector3 {
	return [self valueWithBytes:&vector3 objCType:@encode(GLKVector3)];

}

+ (id)valueWithGLKMatrix4:(GLKMatrix4)matrix4 {
	return [self valueWithBytes:&matrix4 objCType:@encode(GLKMatrix4)];
}

- (GLKVector3)GLKVector3Value {
	GLKVector3 vector3;
	[self getValue:&vector3];
	return vector3;
}

- (GLKMatrix4)GLKMatrix4Value {
	GLKMatrix4 matrix4;
	[self getValue:&matrix4];
	return matrix4;
}
@end