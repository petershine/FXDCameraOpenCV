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


class DTCsceneAVFoundation: UIViewController {

	@IBOutlet weak var opencvScreen: UIImageView!
	@IBOutlet weak var logCoefficientMatrix: UITextView!
	@IBOutlet weak var logHashTable: UITextView!

	var bufferingModule: DTCmoduleBuffer! = nil


	deinit {
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view, typically from a nib.

		bufferingModule = DTCmoduleBuffer();
	}


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated);

		if (bufferingModule.bufferDisplayLayer == nil) {
			bufferingModule.bufferDisplayLayer = AVSampleBufferDisplayLayer()
			bufferingModule.bufferDisplayLayer.bounds = opencvScreen.bounds
			bufferingModule.bufferDisplayLayer.position = CGPointMake(CGRectGetMidX(opencvScreen.bounds), CGRectGetMidY(opencvScreen.bounds))
			bufferingModule.bufferDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspect

			opencvScreen.layer.addSublayer(bufferingModule.bufferDisplayLayer);
		}
	}
}

