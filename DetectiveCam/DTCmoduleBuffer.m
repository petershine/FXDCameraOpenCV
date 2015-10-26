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


	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	NSLog(@"pixelBuffer: %@", pixelBuffer);



	CVReturn didLock = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	NSLog(@"didLock: %d", didLock);

	if (didLock == kCVReturnSuccess) {
		NSLog(@"CVPixelBufferIsPlanar(pixelBuffer): %d", CVPixelBufferIsPlanar(pixelBuffer));

		void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
		NSLog(@"baseAddress: %p", baseAddress);

		size_t width = CVPixelBufferGetWidth(pixelBuffer);
		size_t height = CVPixelBufferGetHeight(pixelBuffer);
		size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
		NSLog(@"width: %lu, height: %lu bytesPerRow: %lu", width, height, bytesPerRow);
	}

	CVReturn didUnlock = CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	NSLog(@"didUnlock: %d", didUnlock);

}

@end
