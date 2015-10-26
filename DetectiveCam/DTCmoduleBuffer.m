//
//  DTCmoduleBuffer.m
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import "DTCmoduleBuffer.h"


OSStatus _compressionStatus;
VTCompressionSessionRef _compressionSession;


@implementation DTCmoduleBuffer

- (instancetype)init {
	self = [super init];

	if (self) {
		_compressionStatus = 0;
		_compressionSession = NULL;
	}

	return self;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

	if (CMFormatDescriptionGetMediaType(formatDescription) != kCMMediaType_Video) {
		return;
	}


	//TODO: check if pixel buffer is h.264
	//process it to be readable
	//refer to Direct Encode And Decode WWDC 2014 video for better understanding.
	//learn about CMBlockBuffer is compressed data. Check if it's h.264 with motion vectors
	//AVSampleBufferDisplayLayer
	//VTCompressionSession


	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
	size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);


	// VTCompressionSession
	if (_compressionSession == NULL) {
		_compressionStatus = VTCompressionSessionCreate(NULL, (int)width, (int)height, kCMVideoCodecType_H264, NULL, NULL, NULL, NULL, NULL, &_compressionSession);
		NSLog(@"compressionStatus: %d", _compressionStatus);
	}


	CMTime presentationTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	CMTime duration = CMSampleBufferGetDuration(sampleBuffer);

	VTCompressionSessionEncodeFrameWithOutputHandler(_compressionSession,
													 pixelBuffer,
													 presentationTimestamp,
													 duration,
													 NULL,
													 NULL,
													 ^(OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef  _Nullable sampleBuffer) {
														 NSLog(@"status: %d, infoFlags: %u", status, infoFlags);

														 [self describeSampleBuffer:sampleBuffer];
													 });
}

- (void)describeSampleBuffer:(CMSampleBufferRef  _Nullable)sampleBuffer {
	NSLog(@"sampleBuffer: %@", sampleBuffer);

	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

	CVReturn didLock = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	//NSLog(@"didLock: %d", didLock);

	if (didLock != kCVReturnSuccess) {
		return;
	}


	NSLog(@"pixelBuffer: %@", pixelBuffer);

	NSLog(@"CVImageBufferIsFlipped(pixelBuffer): %d", CVImageBufferIsFlipped(pixelBuffer));
	NSLog(@"CVPixelBufferIsPlanar(pixelBuffer): %d", CVPixelBufferIsPlanar(pixelBuffer));

	NSLog(@"CVPixelBufferGetPixelFormatType(pixelBuffer): %u", (unsigned int)CVPixelBufferGetPixelFormatType(pixelBuffer));

	NSLog(@"CVPixelBufferGetDataSize(pixelBuffer): %lu", CVPixelBufferGetDataSize(pixelBuffer));


	size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
	NSLog(@"planeCount: %d", planeCount);

	for (size_t planeIndex = 0; planeIndex < planeCount; planeIndex++) {

		size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
		size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);

		size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex);
		//NSLog(@"planeIndex: %lu width: %lu, height: %lu bytesPerRow: %lu", planeIndex, width, height, bytesPerRow);


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
	//NSLog(@"didUnlock: %d", didUnlock);
}

@end
