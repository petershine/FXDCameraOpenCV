//
//  DTCmoduleCapture.h
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


@interface DTCmoduleCapture : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {

	AVCaptureSession *_captureSession;
	AVCaptureVideoDataOutput *_sampleDataOutput;
	
	dispatch_queue_t _capturingQueue;
	dispatch_queue_t _sampleOutputQueue;
}

@property (strong, nonatomic) AVCaptureDeviceInput *videoDeviceInput;

@property (strong, nonatomic) AVSampleBufferDisplayLayer *sampleDisplayLayer;


- (void)prepareCaptureModule;

@end
