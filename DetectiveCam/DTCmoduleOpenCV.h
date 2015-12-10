//
//  DTCmoduleOpenCV.h
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

#import "FXDconfigDeveloper.h"


#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)


@protocol CvVideoCameraDelegate;

@interface DTCmoduleOpenCV : NSObject <CvVideoCameraDelegate>

@property (weak, nonatomic) UIViewController *opencvScene;


- (id)opencvVideoCamera;


- (void)prepareWithOpenCVpreview:(UIView*)opencvPreview;

@end
