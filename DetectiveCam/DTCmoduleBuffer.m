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

	if (_decompressionSession == NULL) {
		CMVideoFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

		VTDecompressionOutputCallbackRecord callbackRecord;
		callbackRecord.decompressionOutputCallback = _outputCallback;
		callbackRecord.decompressionOutputRefCon = (__bridge void *)self;
		VTDecompressionSessionCreate(kCFAllocatorDefault,
									 formatDescription,
									 NULL,
									 NULL,
									 &callbackRecord,
									 &_decompressionSession);
	}


	VTDecodeFrameFlags flags = kVTDecodeFrame_EnableAsynchronousDecompression;
	VTDecodeInfoFlags flagOut;
	NSDate *currentTime = [NSDate date];
	VTDecompressionSessionDecodeFrame(_decompressionSession,
									  sampleBuffer,
									  flags,
									  (void*)CFBridgingRetain(currentTime),
									  &flagOut);
}

@end
