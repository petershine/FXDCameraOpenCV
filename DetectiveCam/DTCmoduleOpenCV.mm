//
//  DTCmoduleOpenCV.m
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//
#warning //MARK: Must use .mm for Objective-C++ compilation

#import "DTCmoduleOpenCV.h"


#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>


@interface DTCcameraOpenCV : CvVideoCamera
/*
- (void)updateOrientation;
- (void)layoutPreviewLayer;
 */
@end

@implementation DTCcameraOpenCV
//MARK: TO simplify unnecessary working for orientation
/*
- (void)updateOrientation {	FXDLog_DEFAULT;
	self->customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
	[self layoutPreviewLayer];
}

- (void)layoutPreviewLayer {

	if (self.parentView == nil) {
		return;
	}


	FXDLog_DEFAULT;

	CALayer *layer = self->customPreviewLayer;
	CGRect bounds = self->customPreviewLayer.bounds;
	Float64 rotation_angle = 0;

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
	layer.affineTransform = CGAffineTransformMakeRotation(((rotation_angle) / 180.0 * M_PI));
	layer.bounds = bounds;

}
 */
@end


@interface DTCmoduleOpenCV () {
	CvVideoCamera *_videoCamera;
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

	self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetHigh;	//AVCaptureSessionPresetiFrame1280x720;

	//MARK: Use the initial orientation at launch, or matching one at the build setting
	self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;	//AVCaptureVideoOrientationPortrait;

	self.videoCamera.grayscaleMode = NO;
	self.videoCamera.defaultFPS = 30;

	
	AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	FXDLogObject(cameraDevice);
	FXDLogObject(cameraDevice.formats);


	NSArray *frameRateRanges = cameraDevice.activeFormat.videoSupportedFrameRateRanges;
	FXDLogObject(frameRateRanges);

	AVFrameRateRange *defaultFrameRate = frameRateRanges.firstObject;

	NSError *error = nil;

	if ([cameraDevice lockForConfiguration:&error]) {
		[cameraDevice setActiveVideoMinFrameDuration:defaultFrameRate.minFrameDuration];
		[cameraDevice setActiveVideoMaxFrameDuration:defaultFrameRate.maxFrameDuration];
	}

	FXDLogObject(error);
	[cameraDevice unlockForConfiguration];


	self.videoCamera.delegate = self;

	[self.videoCamera start];
}


- (void)processImage:(cv::Mat&)image {
	cv::MatIterator_<uchar> imageIterator, endOfMatrix;

	cv::Mat outputMean;
	cv::Mat outputStdDev;
	cv::meanStdDev(image, outputMean, outputStdDev);

	cv::Mat coefficient;
	cv::divide(outputStdDev, outputMean, coefficient);

	cv::MatIterator_<double> cvIterator = coefficient.begin<double>();
	//FXDLog(@"cvIterator: %@ %@ %@ %@", @(cvIterator[0]), @(cvIterator[1]), @(cvIterator[2]), @(cvIterator[3]));
}

@end
