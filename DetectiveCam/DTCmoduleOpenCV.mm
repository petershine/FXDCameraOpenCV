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
			if ([(NSNumber*)coefficientMatrix_0[innerIndex] isEqualToNumber:coefficientMatrix_1[innerIndex]]) {
				isSame = NO;
				break;
			}
		}

		if (isSame == NO) {
			break;
		}
	}

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

	NSArray *coefficientMatrix = @[@(iterator[0]), @(iterator[1]), @(iterator[2])];

	[self.opencvScene performSelector:@selector(logCoefficientMatrix:) withObject:[coefficientMatrix copy]];


	if (_coefficientGroup == nil) {
		_coefficientGroup = [[NSMutableArray alloc] initWithCapacity:0];
	}

	if (_coefficientGroup.count >= 6) {
		[_coefficientGroup removeObjectAtIndex:0];
	}

	[_coefficientGroup addObject:coefficientMatrix];

	if (_coefficientGroup.count < 6) {
		return;
	}


	NSLog(@"%@", _coefficientGroup);
	NSLog(@"%@", @(_hashDictionary.count));


	if (_hashTable == nil) {
		_hashTable = [[NSMutableArray alloc] initWithCapacity:0];
	}

	if (_hashDictionary == nil) {
		_hashDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
	}

	if (_hashTable.count == 0 || [(NSArray*)_hashTable.lastObject isSameCoefficientGroup:_coefficientGroup] == NO) {
		[_hashTable addObject:[_coefficientGroup copy]];
		[_hashDictionary setObject:@(1) forKey:_coefficientGroup.description];
	}
	else if (_hashDictionary.count > 0) {
		NSNumber *matchCount = [_hashDictionary objectForKey:_coefficientGroup.description];
		[_hashDictionary setObject:@(matchCount.integerValue+1) forKey:_coefficientGroup.description];
	}

	//[self.opencvScene performSelector:@selector(logHashDictionary:) withObject:[_hashDictionary copy]];
}

@end
