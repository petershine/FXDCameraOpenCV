//
//  DTCmoduleBuffer.m
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import "DTCmoduleBuffer.h"


@implementation DTCmoduleBuffer


void _outputCallback(void * CM_NULLABLE decompressionOutputRefCon,
					 void * CM_NULLABLE sourceFrameRefCon,
					 OSStatus status,
					 VTDecodeInfoFlags infoFlags,
					 CM_NULLABLE CVImageBufferRef imageBuffer,
					 CMTime presentationTimeStamp,
					 CMTime presentationDuration) {

	NSLog(@"status: %d, infoFlags: %u, presentationTimeStamp: %@, presentationDuration: %@", status, infoFlags, [NSValue valueWithCMTime:presentationTimeStamp], [NSValue valueWithCMTime:presentationDuration]);
	NSLog(@"imageBuffer: %@", imageBuffer);
}


- (instancetype)init {
	if (self = [super init]) {
		_decompressionSession = NULL;
	}

	return self;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	//TODO: check if pixel buffer is h.264
	//process it to be readable
	//refer to Direct Encode And Decode WWDC 2014 video for better understanding.
	//learn about CMBlockBuffer is compressed data. Check if it's h.264 with motion vectors
	//AVSampleBufferDisplayLayer
	//VTCompressionSession


	//NSLog(@"sampleBuffer: %@", sampleBuffer);

	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

	CVReturn didLock = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	NSLog(@"didLock: %d", didLock);

	if (didLock == kCVReturnSuccess) {
		NSLog(@"pixelBuffer: %@", pixelBuffer);

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
			unsigned char *baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex);

			NSLog(@"planeIndex: %lu width: %lu, height: %lu bytesPerRow: %lu baseAddress: %p", planeIndex, width, height, bytesPerRow, baseAddress);
		}
	}

	CVReturn didUnlock = CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	NSLog(@"didUnlock: %d", didUnlock);

	NSLog(@" ");
	NSLog(@" ");
	NSLog(@" ");


	//VTCompressionSession


}

@end
