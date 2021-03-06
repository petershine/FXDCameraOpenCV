//
//  DTCmoduleCapture.m
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import "DTCmoduleCapture.h"


@implementation DTCmoduleCapture {

	AVCaptureSession *_captureSession;
	AVCaptureVideoDataOutput *_sampleDataOutput;

	AVCaptureDeviceInput *_videoDeviceInput;

	dispatch_queue_t _capturingQueue;
	dispatch_queue_t _sampleOutputQueue;
}

#pragma mark -
- (instancetype)init {
	self = [super init];

	if (self) {

		AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
		FXDLog(@"authorizationStatus: %ld", (long)authorizationStatus);

		if (authorizationStatus == AVAuthorizationStatusAuthorized) {
			[self prepareCaptureModule];
			return self;
		}


		//MARK: This app has crashed because it attempted to access privacy-sensitive data without a usage description.  The app's Info.plist must contain an NSCameraUsageDescription key with a string value explaining to the user how the app uses this data.



		[AVCaptureDevice
		 requestAccessForMediaType:AVMediaTypeVideo
		 completionHandler:^(BOOL granted) {
			 FXDLog(@"granted: %d", granted);

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

	FXDLog(@"cameraDevice: %@", cameraDevice);

	if (cameraDevice == nil) {
		return nil;
	}


	FXDLog(@"cameraDevice.formats: %@", cameraDevice.formats);

	NSArray *frameRateRanges = cameraDevice.activeFormat.videoSupportedFrameRateRanges;
	FXDLog(@"frameRateRanges: %@", frameRateRanges);

	AVFrameRateRange *defaultFrameRate = frameRateRanges.firstObject;

	NSError *error = nil;

	if ([cameraDevice lockForConfiguration:&error]) {
		cameraDevice.activeVideoMinFrameDuration = defaultFrameRate.minFrameDuration;
		cameraDevice.activeVideoMaxFrameDuration = defaultFrameRate.maxFrameDuration;
	}
	FXDLog(@"error: %@", error);
	[cameraDevice unlockForConfiguration];


	error = nil;
	_videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
	FXDLog(@"error: %@", error);

	return _videoDeviceInput;
}


#pragma mark -
- (void)prepareCaptureModule {

	_captureSession = [[AVCaptureSession alloc] init];
	_captureSession.sessionPreset = AVCaptureSessionPresetHigh;

	_sampleDataOutput = [[AVCaptureVideoDataOutput alloc] init];
	_sampleDataOutput.alwaysDiscardsLateVideoFrames = YES;
	_sampleDataOutput.videoSettings = nil;


	_sampleOutputQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
	[_sampleDataOutput setSampleBufferDelegate:self queue:_sampleOutputQueue];


	_capturingQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);

	dispatch_async
	(_capturingQueue,
	 ^{
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


	//MARK: Before compression h.264 codec is not used, even though preset was set with iFrame


	[self
	 compressWithSampleBuffer:sampleBuffer
	 withCallback:^(CMSampleBufferRef compressedSample) {

		 [self describeSampleBuffer:compressedSample];

		 
		 if ([self.sampleDisplayLayer isReadyForMoreMediaData]) {
			 [self.sampleDisplayLayer enqueueSampleBuffer:compressedSample];
		 }
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

		 FXDLog(@"COMPRESSED: status: %s, infoFlags: %u", FourCC2Str(status), infoFlags);

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

		 FXDLog(@"DE-COMPRESSED: status: %s, infoFlags: %u", FourCC2Str(status), infoFlags);

		 if (finishedCallback) {
			 finishedCallback(imageBuffer);
		 }
	 });
}

- (void)describeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
#warning //TODO: learn about CMBlockBuffer is compressed data. Check if it's h.264 with motion vectors

	// dataBuffer: contains 6 H.264 frames in decode order (P2,B0,B1,I5,B3,B4)
	// dataFormatDescription: describes H.264 video

	FXDLog(@"sampleBuffer:\n%@", sampleBuffer);


	// Find out if the sample buffer contains an I-Frame.
    // If so we will write the SPS and PPS NAL units to the elementary stream.
    BOOL isIFrame = NO;

    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, 0);
	FXDLog(@"attachmentsArray: %@", attachmentsArray);

    if (CFArrayGetCount(attachmentsArray)) {

        CFDictionaryRef dict = CFArrayGetValueAtIndex(attachmentsArray, 0);
		FXDLog(@"dict: %@", dict);

		CFBooleanRef notSync;
        BOOL keyExists = CFDictionaryGetValueIfPresent(dict,
                                                       kCMSampleAttachmentKey_NotSync,
                                                       (const void **)&notSync);
		FXDLog(@"keyExists: %d", keyExists);

        // An I-Frame is a sync frame
        isIFrame = !keyExists || !CFBooleanGetValue(notSync);
    }
	FXDLog(@"isIFrame: %d", isIFrame);


	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
	FXDLog(@"formatDescription:\n%@", formatDescription);


	CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);

	FXDLog(@"dataBuffer:\n%@", dataBuffer);

	if (dataBuffer == NULL) {
		return;
	}


	size_t setCountOut = 0;
	size_t setIndex = 0;

	int unitHeaderLengthOut = 0;

	do {
		const uint8_t *setPointerOut;
		size_t setSizeOut = 0;

		CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDescription,
														   setIndex,
														   &setPointerOut,
														   &setSizeOut,
														   &setCountOut,
														   &unitHeaderLengthOut);

		FXDLog(@"%lu: unitHeaderLengthOut: %d", setIndex, unitHeaderLengthOut);

		setIndex++;

	} while (setIndex < setCountOut);

	FXDLog(@"setCountOut: %lu", setCountOut);


	FXDLog(@"CMBlockBufferIsRangeContiguous(dataBuffer, 0, %lu): %@",
		  CMBlockBufferGetDataLength(dataBuffer),
		  CMBlockBufferIsRangeContiguous(dataBuffer, CMBlockBufferGetDataLength(dataBuffer), 0) ? @"true":@"false");


	size_t lengthAtOffset = 0;
	size_t totalLength = 0;

	uint8_t *dataPointer = NULL;

	

	CMBlockBufferGetDataPointer(dataBuffer,
								0,
								&lengthAtOffset,
								&totalLength,
								(char**)&dataPointer);

	FXDLog(@"totalLength: %lu == %lu %@", totalLength, CMBlockBufferGetDataLength(dataBuffer), (totalLength == CMBlockBufferGetDataLength(dataBuffer)) ? @"true":@"false");


	size_t offset = 0;
	static const int AVCCHeaderLength = 4;

	while (offset < totalLength - AVCCHeaderLength) {
		// Read the NAL unit length
		uint32_t NALUnitLength = 0;
		memcpy(&NALUnitLength, dataPointer+offset, AVCCHeaderLength);

		// Convert the length value from Big-endian to Little-endian
		NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);

		// Move to the next NAL unit in the block buffer
		offset += AVCCHeaderLength + NALUnitLength;

		FXDLog(@"offset: %lu, AVCCHeaderLength: %d, NALUnitLength: %u", offset, AVCCHeaderLength, NALUnitLength);
	}

	FXDLog(@"%lu < %lu - %d", offset, totalLength, AVCCHeaderLength);
}


- (void)describePixelBuffer:(CVPixelBufferRef)pixelBuffer {

	if (pixelBuffer == NULL) {
		return;
	}


	CVReturn didLock = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

	if (didLock != kCVReturnSuccess) {
		FXDLog(@"didLock: %d", didLock);
		return;
	}


	FXDLog(@"CVImageBufferIsFlipped(pixelBuffer): %d", CVImageBufferIsFlipped(pixelBuffer));
	FXDLog(@"CVPixelBufferIsPlanar(pixelBuffer): %d", CVPixelBufferIsPlanar(pixelBuffer));

	FXDLog(@"CVPixelBufferGetPixelFormatType(pixelBuffer): %u", (unsigned int)CVPixelBufferGetPixelFormatType(pixelBuffer));

	FXDLog(@"CVPixelBufferGetDataSize(pixelBuffer): %lu", CVPixelBufferGetDataSize(pixelBuffer));


	size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
	FXDLog(@"planeCount: %lu", planeCount);

	for (size_t planeIndex = 0; planeIndex < planeCount; planeIndex++) {

		size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
		size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);

		size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex);
		FXDLog(@"planeIndex: %lu width: %lu, height: %lu bytesPerRow: %lu", planeIndex, width, height, bytesPerRow);


		uint8_t *baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex);


		Float64 rowSum = 0;

		for (size_t row = 0; row < height; row++) {

			unsigned long columnSum = 0;

			for (size_t column = 0; column < width; column++) {

				size_t pixelIndex = row*width+column;
				//FXDLog(@"[%lu*%lu+%lu]=%lu: %u", row, width, column, pixelIndex, baseAddress[pixelIndex]);

				columnSum += baseAddress[pixelIndex];
			}

			rowSum += ((Float64)columnSum/(Float64)width);
		}

		Float64 mean = (rowSum/(Float64)height);
		FXDLog(@"planeIndex: %lu mean: %f", planeIndex, mean);
	}

	CVReturn didUnlock = CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

	if (didUnlock != kCVReturnSuccess) {
		FXDLog(@"didUnlock: %d", didUnlock);
	}
}


@end
