//
//  DTCmoduleOpenCV.m
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//
#warning //MARK: Must use .mm for Objective-C++ compilation

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

#import "DTCmoduleOpenCV.h"

#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>


@interface DTCcameraOpenCV : CvVideoCamera
- (void)updateOrientation;
- (void)layoutPreviewLayer;
@end

@implementation DTCcameraOpenCV
- (void)updateOrientation {
	self->customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
	[self layoutPreviewLayer];
}
- (void)layoutPreviewLayer {

	if (self.parentView != nil) {
		CALayer* layer = self->customPreviewLayer;
		CGRect bounds = self->customPreviewLayer.bounds;
		int rotation_angle = 0;

		switch (defaultAVCaptureVideoOrientation) {
			case AVCaptureVideoOrientationLandscapeRight:
				rotation_angle = 270;
				break;
			case AVCaptureVideoOrientationPortraitUpsideDown:
				rotation_angle = 180;
				break;
			case AVCaptureVideoOrientationLandscapeLeft:
				rotation_angle = 90;
				break;
			case AVCaptureVideoOrientationPortrait:
			default:
				break;
		}

		layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
		layer.affineTransform = CGAffineTransformMakeRotation( DEGREES_RADIANS(rotation_angle) );
		layer.bounds = bounds;
	}

}
@end


@interface DTCmoduleOpenCV () {
	CvVideoCamera *_videoCamera;

	NSMutableArray *_cvArray;
}

@property (strong, nonatomic) CvVideoCamera *videoCamera;

@end


@implementation DTCmoduleOpenCV

- (id)opencvVideoCamera {
	return (id)self.videoCamera;
}


- (void)prepareWithOpenCVpreview:(UIView*)opencvPreview {

	if (self.videoCamera) {
		return;
	}


	self.videoCamera = [[DTCcameraOpenCV alloc] initWithParentView:opencvPreview];
	self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
	self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;
	self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
	self.videoCamera.defaultFPS = 30;
	self.videoCamera.grayscaleMode = NO;
	self.videoCamera.delegate = self;

	[self.videoCamera start];
}


- (void)processImage:(cv::Mat&)image {

	cv::Mat outputMean;
	cv::Mat outputStdDev;
	cv::meanStdDev(image, outputMean, outputStdDev);

	cv::Mat coefficient;
	cv::divide(outputMean, outputStdDev, coefficient);


	cv::MatIterator_<double> iterator = coefficient.begin<double>();

	NSArray *coefficientArray = @[@(iterator[0]), @(iterator[1]), @(iterator[2])];

	[self.opencvScene performSelector:@selector(logCoefficientArray:) withObject:coefficientArray];
}

@end
