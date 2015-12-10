//
//  DTCsceneAVFoundation.swift
//  DetectiveCam
//
//  Created by petershine on 10/5/15.
//  Copyright © 2015 fXceed. All rights reserved.
//

import UIKit

import AVFoundation
import VideoToolbox


class DTCsceneAVFoundation: DTCsceneOpenCV {

	var capturingModule: DTCmoduleCapture! = nil


	override func viewDidLoad() {
		super.viewDidLoad()
	}


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated);

		if (capturingModule == nil) {
			capturingModule = DTCmoduleCapture();

			capturingModule.sampleDisplayLayer = AVSampleBufferDisplayLayer()
			capturingModule.sampleDisplayLayer.bounds = opencvScreen.bounds
			capturingModule.sampleDisplayLayer.position = CGPointMake(CGRectGetMidX(opencvScreen.bounds), CGRectGetMidY(opencvScreen.bounds))
			capturingModule.sampleDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspect

			opencvScreen.layer.addSublayer(capturingModule.sampleDisplayLayer);
		}
	}
}

