//
//  DTCmoduleCapture.h
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TargetConditionals.h>

#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

#import "DetectiveCam-Bridging-Header.h"


#if TARGET_RT_BIG_ENDIAN
#define FourCC2Str(fourcc) (const char[]){*((char*)&fourcc), *(((char*)&fourcc)+1), *(((char*)&fourcc)+2), *(((char*)&fourcc)+3),0}
#else
#define FourCC2Str(fourcc) (const char[]){*(((char*)&fourcc)+3), *(((char*)&fourcc)+2), *(((char*)&fourcc)+1), *(((char*)&fourcc)+0),0}
#endif


@interface DTCmoduleCapture : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> 

@property (strong, nonatomic) AVSampleBufferDisplayLayer *sampleDisplayLayer;


- (void)prepareCaptureModule;

@end
