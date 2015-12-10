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
	self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetiFrame1280x720;
	self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;

	self.videoCamera.grayscaleMode = NO;


	self.videoCamera.defaultFPS = 30;

	AVCaptureDevice *cameraDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	FXDLog(@"cameraDevice: %@", cameraDevice);

	FXDLog(@"[videoDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]: %d", [cameraDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]);
	FXDLog(@"cameraDevice.formats: %@", cameraDevice.formats);


	NSArray *frameRateRanges = cameraDevice.activeFormat.videoSupportedFrameRateRanges;
	FXDLog(@"frameRateRanges: %@", frameRateRanges);

	AVFrameRateRange *defaultFrameRate = frameRateRanges.firstObject;

	NSError *error = nil;

	if ([cameraDevice lockForConfiguration:&error]) {
		[cameraDevice setActiveVideoMinFrameDuration:defaultFrameRate.minFrameDuration];
		[cameraDevice setActiveVideoMaxFrameDuration:defaultFrameRate.maxFrameDuration];
	}

	FXDLog(@"error: %@", error);
	[cameraDevice unlockForConfiguration];


	self.videoCamera.delegate = self;

	[self.videoCamera start];
}


- (void)processImage:(cv::Mat&)image {
	cv::MatIterator_<uchar> imageIterator, endOfMatrix;

	cv::Mat outputMean;
	cv::Mat outputStdDev;
	cv::meanStdDev(image, outputMean, outputStdDev);

	cv::MatIterator_<double> meanIterator = outputMean.begin<double>();
	FXDLog(@"meanIterator: %@ %@ %@ %@", @(meanIterator[0]), @(meanIterator[1]), @(meanIterator[2]), @(meanIterator[3]));

	cv::MatIterator_<double> stddevIterator = outputStdDev.begin<double>();
	FXDLog(@"stddevIterator: %@ %@ %@ %@", @(stddevIterator[0]), @(stddevIterator[1]), @(stddevIterator[2]), @(stddevIterator[3]));

	cv::Mat coefficient;
	cv::divide(outputStdDev, outputMean, coefficient);

	cv::MatIterator_<double> cvIterator = coefficient.begin<double>();
	FXDLog(@"cvIterator: %@ %@ %@ %@", @(cvIterator[0]), @(cvIterator[1]), @(cvIterator[2]), @(cvIterator[3]));
}

@end
