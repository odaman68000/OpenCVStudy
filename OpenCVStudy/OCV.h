//
//  OCV.h
//  OpenCVStudy
//
//  Created by 織田 哲男 on 2014/04/14.
//  Copyright (c) 2014年 織田 哲男. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import <opencv2/core/types_c.h>

@interface NSColor (OCVExtension)
+ (id)colorWithCvScalar:(CvScalar)cvScalar;
- (CvScalar)cvScalar;
@end

@interface NSValue (OCVExtension)
+ (id)valueWithGLKVector3:(GLKVector3)vector3;
+ (id)valueWithGLKMatrix4:(GLKMatrix4)matrix4;
- (GLKVector3)GLKVector3Value;
- (GLKMatrix4)GLKMatrix4Value;
@end