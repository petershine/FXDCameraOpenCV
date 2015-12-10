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


@interface NSMutableArray (AddedForOpenCV)
- (BOOL)isSameCoefficientGroup:(NSArray*)coefficientGroup;
@end

@implementation NSArray (AddedForOpenCV)
- (BOOL)isSameCoefficientGroup:(NSArray*)coefficientGroup {
	NSAssert(self.count == coefficientGroup.count, @"1.Element count differenct");

	BOOL isSame = YES;

	for (NSInteger outerIndex = 0; outerIndex < self.count; outerIndex++) {

		NSArray *coefficientMatrix_0 = self[outerIndex];
		NSArray *coefficientMatrix_1 = coefficientGroup[outerIndex];
		NSAssert(coefficientMatrix_0.count == coefficientMatrix_1.count, @"2.Element count differenct");

		for (NSInteger innerIndex = 0; innerIndex < coefficientMatrix_0.count; innerIndex++) {

			if ([(NSNumber*)coefficientMatrix_0[innerIndex] isEqualToNumber:coefficientMatrix_1[innerIndex]] == NO) {

				isSame = NO;
				break;
			}
		}

		if (isSame == NO) {
			break;
		}
	}

	//NSLog(@"isSame: %d", isSame);

	return isSame;
}
@end


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

	NSMutableArray *_coefficientGroup;
	NSMutableArray *_hashTable;
	NSMutableDictionary *_hashDictionary;
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
	NSLog(@"cameraDevice: %@", cameraDevice);

	NSLog(@"[videoDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]: %d", [cameraDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset1280x720]);
	NSLog(@"cameraDevice.formats: %@", cameraDevice.formats);


	NSArray *frameRateRanges = cameraDevice.activeFormat.videoSupportedFrameRateRanges;
	NSLog(@"frameRateRanges: %@", frameRateRanges);

	AVFrameRateRange *defaultFrameRate = frameRateRanges.firstObject;

	NSError *error = nil;

	if ([cameraDevice lockForConfiguration:&error]) {
		[cameraDevice setActiveVideoMinFrameDuration:defaultFrameRate.minFrameDuration];
		[cameraDevice setActiveVideoMaxFrameDuration:defaultFrameRate.maxFrameDuration];
	}

	NSLog(@"error: %@", error);
	[cameraDevice unlockForConfiguration];


	self.videoCamera.delegate = self;

	[self.videoCamera start];
}


- (void)processImage:(cv::Mat&)image {
	cv::MatIterator_<uchar> imageIterator, endOfMatrix;

	NSInteger elementCount = 0;

	Float64 sum = 0.0;

	for (imageIterator = image.begin<uchar>(), endOfMatrix = image.end<uchar>(); imageIterator != endOfMatrix; ++imageIterator) {
		//NSLog(@"%d", *it);
		sum += *imageIterator;

		elementCount++;
	}

	Float64 mean = ((elementCount > 0) ? (sum/(Float64)elementCount):0.0);

	Float64 sumOfSquaredDifferences = 0.0;

	for (imageIterator = image.begin<uchar>(), endOfMatrix = image.end<uchar>(); imageIterator != endOfMatrix; ++imageIterator) {
		Float64 difference = ((Float64)*imageIterator) - mean;
		sumOfSquaredDifferences += (difference * difference);
	}

	Float64 stdDeviation = sqrt(sumOfSquaredDifferences / (Float64)elementCount);
	Float64 coefficientVar = (stdDeviation/mean);

	NSLog(@"image.rows: %d, image.cols: %d, sum: %f mean: %f stdDeviation: %f coefficient: %f", image.rows, image.cols, sum, mean, stdDeviation, coefficientVar);


	cv::Mat outputMean;
	cv::Mat outputStdDev;
	cv::meanStdDev(image, outputMean, outputStdDev);

	cv::MatIterator_<double> meanIterator = outputMean.begin<double>();
	NSLog(@"meanIterator: %@ %@ %@ %@", @(meanIterator[0]), @(meanIterator[1]), @(meanIterator[2]), @(meanIterator[3]));

	cv::MatIterator_<double> stddevIterator = outputStdDev.begin<double>();
	NSLog(@"stddevIterator: %@ %@ %@ %@", @(stddevIterator[0]), @(stddevIterator[1]), @(stddevIterator[2]), @(stddevIterator[3]));

	cv::Mat coefficient;
	cv::divide(outputStdDev, outputMean, coefficient);

	cv::MatIterator_<double> cvIterator = coefficient.begin<double>();
	NSLog(@"cvIterator: %@ %@ %@ %@", @(cvIterator[0]), @(cvIterator[1]), @(cvIterator[2]), @(cvIterator[3]));


	return;



	NSArray *coefficientMatrix = @[@(cvIterator[0]), @(cvIterator[1]), @(cvIterator[2])];

	if (_coefficientGroup == nil) {
		_coefficientGroup = [[NSMutableArray alloc] initWithCapacity:0];
	}

	if (_coefficientGroup.count >= 6) {
		[_coefficientGroup removeObjectAtIndex:0];
	}

	NSArray *integerMatrix = @[@([coefficientMatrix[0] integerValue]), @([coefficientMatrix[1] integerValue]), @([coefficientMatrix[2] integerValue])];
	[_coefficientGroup addObject:integerMatrix];

	if (_coefficientGroup.count < 6) {
		return;
	}


	//NSLog(@"%@", _coefficientGroup);

	NSNumber *matchCount = [_hashDictionary objectForKey:_coefficientGroup];
	NSArray *hashKey = (NSArray*)_hashTable.lastObject;

	if ([hashKey isSameCoefficientGroup:_coefficientGroup] == NO) {
		matchCount = @(0);
		hashKey = _coefficientGroup;

		if (_hashTable == nil) {
			_hashTable = [[NSMutableArray alloc] initWithCapacity:0];
		}

		[_hashTable addObject:hashKey];
	}

	if (_hashDictionary == nil) {
		_hashDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
	}

	[_hashDictionary setObject:@(matchCount.integerValue+1) forKey:hashKey];

	//NSLog(@"%@", _hashTable);
}

@end
