//
//  DTCmoduleBuffer.h
//  DetectiveCam
//
//  Created by petershine on 10/23/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import <Foundation/Foundation.h>

@import AVFoundation;
@import VideoToolbox;


@interface DTCmoduleBuffer : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
	VTDecompressionSessionRef _decompressionSession;
}

@end
