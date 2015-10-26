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
	//NSLog(@"pixelBuffer: %@", pixelBuffer);



	CVReturn didLock = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	//NSLog(@"didLock: %d", didLock);

	if (didLock == kCVReturnSuccess) {
		//NSLog(@"CVPixelBufferIsPlanar(pixelBuffer): %d", CVPixelBufferIsPlanar(pixelBuffer));

		unsigned char *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
		//NSLog(@"baseAddress: %p", baseAddress);

		size_t width = CVPixelBufferGetWidth(pixelBuffer);
		size_t height = CVPixelBufferGetHeight(pixelBuffer);
		size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
		//NSLog(@"width: %lu, height: %lu bytesPerRow: %lu", width, height, bytesPerRow);

		unsigned long element_0 = 0;
		unsigned long element_1 = 0;
		unsigned long element_2 = 0;
		unsigned long element_3 = 0;

		unsigned long elementCount = 0;

		for (size_t row = 0; row < height; row++) {
			for (size_t column = 0; column < width; column++) {
				//NSLog(@"(%d, %d): %d %d %d %d", row, column, baseAddress[0], baseAddress[1], baseAddress[2], baseAddress[3]);
				element_0 += baseAddress[0];
				element_1 += baseAddress[1];
				element_2 += baseAddress[2];
				element_3 += baseAddress[3];

				baseAddress += 4;
				elementCount += 1;
			}
		}

		NSLog(@"sum: %lu %lu %lu %lu, mean: %f %f %f %f", element_0, element_1, element_2, element_3, ((Float64)element_0/elementCount), ((Float64)element_1/elementCount), ((Float64)element_2/elementCount), ((Float64)element_3/elementCount));
	}

	CVReturn didUnlock = CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	//NSLog(@"didUnlock: %d", didUnlock);

}

@end
