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


@interface DTCmoduleOpenCV () {
	CvVideoCamera *_videoCamera;

	cv::Mat _previousImage;
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


	self.videoCamera = [[CvVideoCamera alloc] initWithParentView:opencvPreview];
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


	NSString *valueString = @"";

	cv::MatIterator_<double> _it = coefficient.begin<double>();
	
	for(; _it != coefficient.end<double>(); _it++){
		valueString = [valueString stringByAppendingFormat:@"%d ", (int)*_it];
	}

	NSLog(@"%@", valueString);
}

@end