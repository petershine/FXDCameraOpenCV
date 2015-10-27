//
//  DTCmoduleBuffer.h
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <TargetConditionals.h>
#if TARGET_RT_BIG_ENDIAN
#define FourCC2Str(fourcc) (const char[]){*((char*)&fourcc), *(((char*)&fourcc)+1), *(((char*)&fourcc)+2), *(((char*)&fourcc)+3),0}
#else
#define FourCC2Str(fourcc) (const char[]){*(((char*)&fourcc)+3), *(((char*)&fourcc)+2), *(((char*)&fourcc)+1), *(((char*)&fourcc)+0),0}
#endif


@import AVFoundation;
@import VideoToolbox;


@interface DTCmoduleBuffer : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
	dispatch_queue_t capturingQueue;
	dispatch_queue_t videoOutputQueue;

	BOOL shouldRunSession;

	AVCaptureSession *captureSession;
	AVCaptureDeviceInput *captureVideoInput;

	AVCaptureVideoDataOutput *captureVideoOutput;
}

@property (strong, nonatomic) AVSampleBufferDisplayLayer *bufferDisplayLayer;

@end
