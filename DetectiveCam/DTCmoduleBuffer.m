//
//  DTCmoduleBuffer.m
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import "DTCmoduleBuffer.h"


static VTCompressionSessionRef compressionSession;
static VTDecompressionSessionRef decompressionSession;


@implementation DTCmoduleBuffer

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

	if (CMFormatDescriptionGetMediaType(formatDescription) != kCMMediaType_Video) {
		return;
	}


	[self
	 compressWithSampleBuffer:sampleBuffer
	 withCallback:^(CMSampleBufferRef compressedSample) {

		 CMBlockBufferRef dataBlock = CMSampleBufferGetDataBuffer(compressedSample);
		 [self describeDataBlock:dataBlock];


		 [self displaySampleBuffer:compressedSample];


		 //TODO: Check if decompression is necessary
		 /*
		 [self
		  decompressWithSampleBuffer:compressedSample
		  withCallback:^(CVImageBufferRef imageBuffer) {
			  //[self describePixelBuffer:imageBuffer];
		  }];
		  */
	 }];
}

- (void)compressWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withCallback:(void(^)(CMSampleBufferRef compressedSampleBuffer))finishedCallback {

	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

	size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
	size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);


	if (compressionSession == NULL) {
		VTCompressionSessionCreate(NULL, (int)width, (int)height, kCMVideoCodecType_H264, NULL, NULL, NULL, NULL, NULL, &compressionSession);
	}


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

		 NSLog(@"COMPRESSED: status: %d, infoFlags: %u", status, infoFlags);
		 NSLog(@"COMPRESSED: compressedSample:\n%@", compressedSample);

		 if (finishedCallback) {
			 finishedCallback(compressedSample);
		 }
	 });
}

- (void)decompressWithSampleBuffer:(CMSampleBufferRef)sampleBuffer withCallback:(void(^)(CVImageBufferRef imageBuffer))finishedCallback {

	CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

	if (decompressionSession == NULL) {
		VTDecompressionSessionCreate(NULL, formatDescription, NULL, NULL, NULL, &decompressionSession);
	}


	VTDecompressionSessionDecodeFrameWithOutputHandler
	(decompressionSession,
	 sampleBuffer,
	 kVTDecodeFrame_EnableAsynchronousDecompression,
	 NULL,
	 ^(OSStatus status,
	   VTDecodeInfoFlags infoFlags,
	   CVImageBufferRef  _Nullable imageBuffer,
	   CMTime presentationTimeStamp,
	   CMTime presentationDuration) {

		 NSLog(@"DE-COMPRESSED: status: %d, infoFlags: %u", status, infoFlags);
		 NSLog(@"DE-COMPRESSED: imageBuffer:\n%@", imageBuffer);

		 if (finishedCallback) {
			 finishedCallback(imageBuffer);
		 }
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

- (void)describeDataBlock:(CMBlockBufferRef)dataBlock {
#warning //TODO: learn about CMBlockBuffer is compressed data. Check if it's h.264 with motion vectors

	NSLog(@"dataBlock: %@", dataBlock);

	if (dataBlock == NULL) {
		return;
	}


	NSLog(@"CMBlockBufferIsEmpty(dataBlock): %d", CMBlockBufferIsEmpty(dataBlock));

	size_t offset = 0;
	size_t lengthAtOffset = 0;
	size_t totalLength = 0;
	char *dataPointer;

	CMBlockBufferGetDataPointer(dataBlock,
								offset,
								&lengthAtOffset,
								&totalLength,
								&dataPointer);

	NSLog(@"lengthAtOffset: %lu, totalLength: %lu dataPointer: %p", lengthAtOffset, totalLength, dataPointer);
}

- (void)displaySampleBuffer:(CMSampleBufferRef)sampleBuffer {

	__strong AVSampleBufferDisplayLayer *strongDisplayLayer = self.bufferDisplayLayer;

	if (strongDisplayLayer == nil) {
		return;
	}


	if ([strongDisplayLayer isReadyForMoreMediaData] == NO) {
		NSLog(@"[strongBufferDisplayLayer isReadyForMoreMediaData]: %d", [strongDisplayLayer isReadyForMoreMediaData]);
		return;
	}


	CFRetain(sampleBuffer);

	dispatch_async(dispatch_get_main_queue(), ^{
		[strongDisplayLayer enqueueSampleBuffer:sampleBuffer];
		[strongDisplayLayer setNeedsDisplay];

		CFRelease(sampleBuffer);
	});
}

@end
