//
//  DTCmoduleCapture.m
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import "DTCmoduleCapture.h"


@implementation DTCmoduleCapture

- (instancetype)init {
	self = [super init];

	if (self) {

		AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
		NSLog(@"authorizationStatus: %ld", (long)authorizationStatus);

		if (authorizationStatus == AVAuthorizationStatusAuthorized) {
			[self prepareCaptureModule];
			return self;
		}


		[AVCaptureDevice
		 requestAccessForMediaType:AVMediaTypeVideo
		 completionHandler:^(BOOL granted) {
			 NSLog(@"granted: %d", granted);

			 if (granted) {
				 [self prepareCaptureModule];
			 }
		 }];
	}

	return self;
}

#pragma mark -
- (AVCaptureDeviceInput*)videoDeviceInput {
	if (_videoDeviceInput) {
		return _videoDeviceInput;
	}


	AVCaptureDevice *cameraDevice = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

	for (AVCaptureDevice *device in devices) {
		if (device.position == AVCaptureDevicePositionBack) {
			cameraDevice = device;
			break;
		}
	}

	NSLog(@"cameraDevice: %@", cameraDevice);

	if (cameraDevice == nil) {
		return nil;
	}


	NSLog(@"cameraDevice.formats: %@", cameraDevice.formats);

	NSArray *frameRateRanges = cameraDevice.activeFormat.videoSupportedFrameRateRanges;
	NSLog(@"frameRateRanges: %@", frameRateRanges);

	AVFrameRateRange *defaultFrameRate = frameRateRanges.firstObject;

	NSError *error = nil;

	if ([cameraDevice lockForConfiguration:&error]) {
		cameraDevice.activeVideoMinFrameDuration = defaultFrameRate.minFrameDuration;
		cameraDevice.activeVideoMaxFrameDuration = defaultFrameRate.maxFrameDuration;
	}
	NSLog(@"error: %@", error);
	[cameraDevice unlockForConfiguration];


	error = nil;
	_videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
	NSLog(@"error: %@", error);

	return _videoDeviceInput;
}


#pragma mark -
- (void)prepareCaptureModule {

	_capturingQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);

	dispatch_async
	(_capturingQueue,
	 ^{
		 _captureSession = [[AVCaptureSession alloc] init];
		 _captureSession.sessionPreset = AVCaptureSessionPresetHigh;


		 _sampleOutputQueue = dispatch_queue_create("outputQueue", DISPATCH_QUEUE_SERIAL);

		 _sampleDataOutput = [[AVCaptureVideoDataOutput alloc] init];
		 _sampleDataOutput.alwaysDiscardsLateVideoFrames = YES;
		 _sampleDataOutput.videoSettings = nil;

		 [_sampleDataOutput setSampleBufferDelegate:self queue:_sampleOutputQueue];


		 [_captureSession beginConfiguration];

		 if ([_captureSession canAddInput:self.videoDeviceInput]) {
			 [_captureSession addInput:self.videoDeviceInput];
		 }

		 if ([_captureSession canAddOutput:_sampleDataOutput]) {
			 [_captureSession addOutput:_sampleDataOutput];
		 }

		 [_captureSession commitConfiguration];


		 [_captureSession startRunning];
	 });
}

#pragma mark -
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

	if (CMFormatDescriptionGetMediaType(formatDescription) != kCMMediaType_Video) {
		return;
	}


	[self displaySampleBuffer:sampleBuffer];


	//MARK: Before compression h.264 codec is not used, even though preset was set with iFrame

	[self
	 compressWithSampleBuffer:sampleBuffer
	 withCallback:^(CMSampleBufferRef compressedSample) {

		 [self describeSampleBuffer:compressedSample];
	 }];
}

#pragma mark -
- (void)compressWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withCallback:(void(^)(CMSampleBufferRef compressedSampleBuffer))finishedCallback {

	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
	CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);


	static VTCompressionSessionRef compressionSession;

	if (compressionSession == NULL) {
		VTCompressionSessionCreate
		(NULL,
		 videoDimensions.width,
		 videoDimensions.height,
		 kCMVideoCodecType_H264,
		 NULL,
		 NULL,
		 NULL,
		 NULL,
		 NULL,
		 &compressionSession);
	}


	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

	CMTime presentationTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	CMTime duration = CMSampleBufferGetDuration(sampleBuffer);

	VTCompressionSessionEncodeFrameWithOutputHandler
	(compressionSession,
	 pixelBuffer,
	 presentationTimestamp,
	 duration,
	 NULL,
	 NULL,
	 ^(OSStatus status,
	   VTEncodeInfoFlags infoFlags,
	   CMSampleBufferRef  _Nullable compressedSample) {

		 NSLog(@"COMPRESSED: status: %s, infoFlags: %u", FourCC2Str(status), infoFlags);
		 NSLog(@"COMPRESSED: compressedSample:\n%@", compressedSample);

		 if (finishedCallback) {
			 finishedCallback(compressedSample);
		 }
	 });
}

- (void)decompressFromCompressedSample:(CMSampleBufferRef)compressedSample withCallback:(void(^)(CVImageBufferRef imageBuffer))finishedCallback {

	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(compressedSample);


	static VTDecompressionSessionRef decompressionSession;

	if (decompressionSession == NULL) {
		VTDecompressionSessionCreate
		(NULL,
		 formatDescription,
		 NULL,
		 NULL,
		 NULL,
		 &decompressionSession);
	}


	VTDecompressionSessionDecodeFrameWithOutputHandler
	(decompressionSession,
	 compressedSample,
	 kVTDecodeFrame_EnableAsynchronousDecompression,
	 NULL,
	 ^(OSStatus status,
	   VTDecodeInfoFlags infoFlags,
	   CVImageBufferRef  _Nullable imageBuffer,
	   CMTime presentationTimeStamp,
	   CMTime presentationDuration) {

		 NSLog(@"DE-COMPRESSED: status: %s, infoFlags: %u", FourCC2Str(status), infoFlags);
		 NSLog(@"DE-COMPRESSED: imageBuffer:\n%@", imageBuffer);

		 if (finishedCallback) {
			 finishedCallback(imageBuffer);
		 }
	 });
}

- (void)describeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
#warning //TODO: learn about CMBlockBuffer is compressed data. Check if it's h.264 with motion vectors

	// dataBuffer: contains 6 H.264 frames in decode order (P2,B0,B1,I5,B3,B4)
	// dataFormatDescription: describes H.264 video


	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
	NSLog(@"formatDescription:\n%@", formatDescription);

	FourCharCode codecType = CMFormatDescriptionGetMediaSubType(formatDescription);
	NSLog(@"codecType: %s", FourCC2Str(codecType));


	size_t parameterSetCount = 0;

	CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription, 0, NULL, NULL, &parameterSetCount, NULL);
	NSLog(@"parameterSetCount: %lu", parameterSetCount);


	CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);

	NSLog(@"dataBlock:\n%@", dataBuffer);

	if (dataBuffer == NULL) {
		return;
	}


	size_t offset = 0;
	size_t lengthAtOffset = 0;
	size_t totalLength = 0;
	uint8_t *dataPointer;

	CMBlockBufferGetDataPointer(dataBuffer,
								offset,
								&lengthAtOffset,
								&totalLength,
								(char**)&dataPointer);

	NSLog(@"lengthAtOffset: %lu, totalLength: %lu dataPointer: %p", lengthAtOffset, totalLength, dataPointer);

	NSLog(@"CMBlockBufferIsRangeContiguous(dataBuffer, 0, %lu): %d", totalLength, CMBlockBufferIsRangeContiguous(dataBuffer, 0, totalLength));


	NSData *blockData = [NSData dataWithBytes:dataPointer length:totalLength];
	NSLog(@"blockData:\n%@", blockData);
}

- (void)displaySampleBuffer:(CMSampleBufferRef)sampleBuffer {

	if (_sampleDisplayLayer == nil) {
		return;
	}


	if ([self.sampleDisplayLayer isReadyForMoreMediaData] == NO) {
		return;
	}


	CFRetain(sampleBuffer);

	dispatch_async
	(dispatch_get_main_queue(),
	 ^{
		 [self.sampleDisplayLayer enqueueSampleBuffer:sampleBuffer];
		 [self.sampleDisplayLayer setNeedsDisplay];

		 CFRelease(sampleBuffer);
	 });
}


- (void)describePixelBuffer:(CVPixelBufferRef)pixelBuffer {

	if (pixelBuffer == NULL) {
		return;
	}


	CVReturn didLock = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

	if (didLock != kCVReturnSuccess) {
		NSLog(@"didLock: %d", didLock);
		return;
	}


	NSLog(@"CVImageBufferIsFlipped(pixelBuffer): %d", CVImageBufferIsFlipped(pixelBuffer));
	NSLog(@"CVPixelBufferIsPlanar(pixelBuffer): %d", CVPixelBufferIsPlanar(pixelBuffer));

	NSLog(@"CVPixelBufferGetPixelFormatType(pixelBuffer): %u", (unsigned int)CVPixelBufferGetPixelFormatType(pixelBuffer));

	NSLog(@"CVPixelBufferGetDataSize(pixelBuffer): %lu", CVPixelBufferGetDataSize(pixelBuffer));


	size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
	NSLog(@"planeCount: %lu", planeCount);

	for (size_t planeIndex = 0; planeIndex < planeCount; planeIndex++) {

		size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
		size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);

		size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex);
		NSLog(@"planeIndex: %lu width: %lu, height: %lu bytesPerRow: %lu", planeIndex, width, height, bytesPerRow);


		uint8_t *baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex);


		Float64 rowSum = 0;

		for (size_t row = 0; row < height; row++) {

			unsigned long columnSum = 0;

			for (size_t column = 0; column < width; column++) {

				size_t pixelIndex = row*width+column;
				//NSLog(@"[%lu*%lu+%lu]=%lu: %u", row, width, column, pixelIndex, baseAddress[pixelIndex]);

				columnSum += baseAddress[pixelIndex];
			}

			rowSum += ((Float64)columnSum/(Float64)width);
		}

		Float64 mean = (rowSum/(Float64)height);
		NSLog(@"planeIndex: %lu mean: %f", planeIndex, mean);
	}

	CVReturn didUnlock = CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

	if (didUnlock != kCVReturnSuccess) {
		NSLog(@"didUnlock: %d", didUnlock);
	}
}


@end